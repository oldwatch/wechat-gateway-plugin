local utils = require "utils.commons.version_tool"
local redis_dao = require "kong.plugins.wechat-callback.redis_daos"

local ngx= ngx

local _M = {}

function _M.redirectTo(conf,fields)

    local msgID=fields["MsgID"]

    local type=fields["Event"]

    local wechatNo=fields["ToUserName"]

    if conf.msg_bind[type] then
        local json= redis_dao.getRedirectByMsgID(conf,wechatNo,msgID,type)
        
        local url=json["callbackUrl"]
        local auth=json["callbackApiKey"]

        return url,auth
    end

    return nil
end




return _M