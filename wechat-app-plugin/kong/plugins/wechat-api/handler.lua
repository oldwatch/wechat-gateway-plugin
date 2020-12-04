local access = require "kong.plugins.wechat-api.access"
local BasePlugin = require "kong.plugins.base_plugin"
local utils = require "utils.commons.version_tool"
local ngx = ngx 

local WeChatApiHandler = BasePlugin:extend()


function WeChatApiHandler:access(conf)

    local ctx = ngx.ctx

    local accessID=utils.getAccessID()
    if not accessID then
        return utils.forbidden_response("You cannot consume this service")
    end 

    ngx.log(ngx.INFO,"accessID" .. accessID)

    local query = ngx.req.get_uri_args()
    if query.access_token then
        return
    end

    local res = access.getToken(conf, accessID)
    if not res then
        return utils.internal_error_response("consumer relation app not found ")
    end

    local token=res["token"]
    ngx.log(ngx.INFO,type(token))

    query.access_token = token
    ngx.req.set_uri_args(query)
    

    if conf.modifybody  then

        local result,err=access.replace(conf, accessID,res)
        if not result then
            ngx.log(ngx.ERR,err)
            return utils.internal_error_response(err)
        end
    end

    return 
end


WeChatApiHandler.PRIORITY = 101
WeChatApiHandler.VERSION = "0.1.0"


return WeChatApiHandler