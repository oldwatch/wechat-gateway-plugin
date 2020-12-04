local BasePlugin = require "kong.plugins.base_plugin"
local utils = require "utils.commons.version_tool"
local access = require "kong.plugins.wechat-callback.access"
local redis_dao = require "kong.plugins.wechat-callback.redis_daos"
local msg_receive = require "kong.plugins.wechat-callback.msg_receive"

local ngx= ngx

local WeChatCallbackHandler = BasePlugin:extend()


local invalid_ctx_resp=[[
    <xml>
    <return_code>FAIL</return_code>
    <return_msg>INVALID_CTX</return_ms>
    </xml>
]]


local function sendToCallback(body,url,auth)

    ngx.req.set_body_data(body)
                    
    if auth then 
        ngx.req.set_header("apikey", auth)
    end 
    utils.fill_route_target(url)
    return true
end

local function sendToDownstream(config,newbody)

    local redirect=config.redirect_to
    local contType= ngx.req.get_headers()["Content-Type"]

    if redirect then

        local fields = nil
        if  string.match(contType,"xml") then
            fields =access.parseXml(newbody)
        end


        if fields then

            local url,auth=msg_receive.redirectTo(config,fields)

            if url then 
                return sendToCallback(newbody,url,auth)
            end

            for _,route in ipairs(redirect) do
                local customer =utils.filterRoute(route,fields)
                if customer then
                    local url,auth=getCallbackInfoByAccessID(config,customer)
                    if url then
                        return sendToCallback(newbody,url,auth)
                    end 
                end
            end
        end 
    end
    access.sendToKafka(config,nil,newbody)
end

function WeChatCallbackHandler:access(conf)

    ngx.log(ngx.INFO,"start plugin wechat callback")
    
    local args, err = ngx.req.get_uri_args()

    if not err  and  args["echostr"] then
        local result=access.verifyWechatVerfiy(conf,args)
        if result then
            utils.success_response(args["echostr"])
        else 
            utils.success_response("verify fail!")
        end
        return
    end
    
    ngx.req.read_body()
    local data = ngx.req.get_body_data()
    if not data then
        ngx.log(ngx.ERR,"not found body")
        utils.success_response(success_resp)
        return
    end

    sendToDownstream(conf,data)
end


WeChatCallbackHandler.PRIORITY = 101
WeChatCallbackHandler.VERSION = "0.1.0"


return WeChatCallbackHandler
