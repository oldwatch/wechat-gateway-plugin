local BasePlugin = require "kong.plugins.base_plugin"
local utils = require "utils.commons.version_tool"
local access = require "kong.plugins.wechat-pay.access"
local filter_body = require "kong.plugins.wechat-pay.filter_body"
local redis_dao = require "kong.plugins.wechat-pay.redis_dao" 
local ngx= ngx

local WeChatpayHandler = BasePlugin:extend()


function WeChatpayHandler:body_filter(conf)

    ngx.log(ngx.INFO,"do body filter")
    local  resp_status=ngx.status
    if not (resp_status>=200 and resp_status < 300 ) then 
        return;
    end 

    local status,result=pcall(filter_body.check_context,conf.signtype)

    
    if not status then 
        ngx.log(ngx.ERR,"bad sign")
        ngx.exit(500)
    end

end

function WeChatpayHandler:access(conf)

   

    local accessID=utils.getAccessID()
    if not accessID then
        return utils.forbidden_response("You cannot consume this service")
    end 

    local ctx = ngx.ctx
    local appInfo,err =redis_dao.getAppInfoByAccessID(conf,accessID)
    if err then
        return utils.forbidden_response("this consume not bind wechat account"..err)
    end

    ngx.req.read_body()
    local data = ngx.req.get_body_data()
    if not data then
        return
    end
    
    ngx.req.set_header("Accept-Encoding","")


    local status,result=pcall(access.doSignWork,conf,appInfo,data)

    if not status then 
        ngx.log(ngx.ERR,result)

        return utils.internal_error_response({status=502,message=result})
    else
        ngx.req.set_body_data(result)
    end

    if conf.need_cert  then 

        -- ngx.req.set_header("x-account-global-id",appInfo.globalID)

        local base_url=conf.certbind_service

        local suburl=ngx.var.upstream_uri

        ngx.log(ngx.INFO,suburl)
        
        utils.fill_route_target(base_url..suburl)
    end 

end


WeChatpayHandler.PRIORITY = 101
WeChatpayHandler.VERSION = "0.0.1"


return WeChatpayHandler
