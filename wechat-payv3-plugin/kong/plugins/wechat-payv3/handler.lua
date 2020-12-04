local BasePlugin = require "kong.plugins.base_plugin"
local utils = require "utils.commons.version_tool"
local access = require "kong.plugins.wechat-payv3.access"
local filter_body = require "kong.plugins.wechat-payv3.filter_body"
local redis_dao = require "kong.plugins.wechat-payv3.redis_dao" 
local ngx= ngx

local WeChatpayV3Handler = BasePlugin:extend()


function WeChatpayV3Handler:body_filter(conf)

    ngx.log(ngx.INFO,"do body filter")
    local  resp_status=ngx.status
    if not (resp_status>=200 and resp_status < 300 ) then 
        return;
    end 

    filter_body.check_context(conf)

end

function WeChatpayV3Handler:access(conf)

    local accessID=utils.getAccessID()
    if not accessID then
        return utils.forbidden_response("You cannot consume this service")
    end 

    local appInfo,err =redis_dao.getAppInfoByAccessID(conf,accessID)
    if err then
        return utils.forbidden_response("this consume not bind wechat account"..err)
    end

    ngx.req.read_body()
    local data = ngx.req.get_body_data()

    local pks=redis_dao.getPlatformPublicKeysByMchID(conf,appInfo.mchID)

    ngx.ctx.publicKeys=pks

    ngx.ctx.mchID=appInfo.mchID

    access.doSignWork(conf,appInfo.mchID,appInfo.keySerial,data)


end


WeChatpayV3Handler.PRIORITY = 101
WeChatpayV3Handler.VERSION = "0.0.1"


return WeChatpayV3Handler
