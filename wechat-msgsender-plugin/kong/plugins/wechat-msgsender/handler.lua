local access = require "kong.plugins.wechat-msgsender.access"
local BasePlugin = require "kong.plugins.base_plugin"
local utils = require "utils.commons.version_tool"
local ngx = ngx 

local WeChatMsgSenderHandler = BasePlugin:extend()


function WeChatMsgSenderHandler:header_filter(conf)

    local headers=ngx.ctx.upstream_headers

    for i,v in pairs(headers) do
        ngx.header[i]=v
    end

end

function WeChatMsgSenderHandler:access(conf)

    local accessID=utils.getAccessID()
    if not accessID then
        return utils.forbidden_response("You cannot consume this service")
    end 
    
    local result,err=access.callApi(conf, accessID)

    if err then
        return utils.internal_error_response({status=502,message=err})
    end

    utils.success_response(result)

end


WeChatMsgSenderHandler.PRIORITY = 101
WeChatMsgSenderHandler.VERSION = "0.1.0"


return WeChatMsgSenderHandler