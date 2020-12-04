local red = require "kong.plugins.wechat-api.redis_daos" 
local utils = require "utils.commons.version_tool"
local ngx = ngx

local root_str="xml"

local _M = {}


function _M.getToken(conf,accessID)
    return  red.getToken(conf, accessID)
end


function _M.replace(conf,accessID,res)

    ngx.req.read_body()
    local data = ngx.req.get_body_data()
    if not data then
        return true
    end

    local appInfo = red.getAppInfoByAccessID(conf, accessID)
    if not appInfo then
        return false, "not found relation app info"
    end

    local body = string.gsub(data,"${APPID}", appInfo.appID)

    local ticket= res["ticket"]
    if ticket then
        body = string.gsub(body,"${TICKET}", ticket)
    end

    ngx.req.set_body_data(body)
end

return _M
