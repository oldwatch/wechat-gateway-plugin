local BasePlugin = require "kong.plugins.base_plugin"
local utils = require "utils.commons.version_tool"
local access = require "kong.plugins.wechat-paycallback.access"
local redis_dao = require "kong.plugins.wechat-paycallback.redis_dao"

local ngx= ngx

local PayCallbackHandler = BasePlugin:extend()

local encrypt_str="Encrypt"


local invalid_ctx_resp=[[
    <xml>
    <return_code>FAIL</return_code>
    <return_msg>INVALID_CTX</return_ms>
    </xml>
]]





local function sendToDownstream(config,newbody,busKey)

    local redirect=config.redirect_to
    local contType= ngx.req.get_headers()["Content-Type"]

    if redirect then
            local fields =access.parse(newbody)

            for _,route in ipairs(redirect) do
                local match=utils.filterRoute(route,fields)
                if match then 
                    ngx.req.set_body_data(newbody)
                    
                    if auth then 
                        ngx.req.set_header("apikey", auth)
                    end 
                    utils.fill_route_target(match)
                    return true
                end
            end
    end
    access.sendToKafka(config,busKey,newbody)
end

function PayCallbackHandler:access(conf)

    ngx.log(ngx.INFO,"start plugin pay callback")
    
    ngx.req.read_body()
    local data = ngx.req.get_body_data()
    
    if not data then
        utils.response("EMPTY_BODY")
        return
    end

    local contType= ngx.req.get_headers()["Content-Type"]
    ngx.log(ngx.INFO,"content type "..contType)

    if conf.pay_version == "v2"  then

        if not string.match(contType,"xml") then 
            ngx.log(ngx.ERR,"contType not xml "..contType)
            utils.internal_error_response("CONTENT_TYPE_ERROR",result)
        end

        status,result,busKey= pcall(access.decryptPayV2Callback,data,conf)
        if not status or not result then 
            ngx.log(ngx.ERR,result)
            utils.response("DECRYPT_FAIL",result)
        end

        sendToDownstream(conf,result,busKey)

    elseif  conf.pay_version == "v3" then

        if not string.match(contType,"json") then 
            ngx.log(ngx.ERR,"contType not json  ".. contType)
            utils.internal_error_response("CONTENT_TYPE_ERROR",result)
        end

        local path=ngx.var.upstream_uri
        local exp="/id/([%w_]+)"
        local _,_,globalID=string.find(path,exp)
    
        ngx.log(ngx.INFO,"global id",globalID,"path",path)

        if not globalID then 
            sendToDownstream(conf,data)
            return
        end    

        local appInfo=redis_dao.getPayV3AppInfoByAppID(conf,globalID)
        
        local verifySign,err=access.verifySignV3(appInfo["mchID"],data,conf)

        if not verifySign or err then 
            ngx.log(ngx.ERR,"verify sign fail",verifySign,err)
            utils.internal_error_response(tostring(err))
            return 
        end

        local newdata,busKey =access.decryptPayV3Callback(data,appInfo.secretPayKey)

        sendToDownstream(conf,newdata,busKey)

    else
        ngx.log(ngx.ERR,conf.pay_version)
        utils.internal_error_response("UNKNOWN_CALLBACK_TYPE",contType)
    end 
    
    utils.success_response()
    return

end


PayCallbackHandler.PRIORITY = 101
PayCallbackHandler.VERSION = "0.0.1"


return PayCallbackHandler
