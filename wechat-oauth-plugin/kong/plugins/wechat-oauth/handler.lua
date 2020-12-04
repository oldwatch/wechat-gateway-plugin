local BasePlugin = require "kong.plugins.base_plugin"
local redis_dao = require "kong.plugins.wechat-oauth.redis_daos"
local oauth = require "kong.plugins.wechat-oauth.oauth"
local exchange_token = require "kong.plugins.wechat-oauth.exchange_token"
local utils = require "utils.commons.version_tool"

local ngx = ngx 
local kong = kong 

local WechatOAuthHandler = BasePlugin:extend()


function WechatOAuthHandler:header_filter(conf)

    if conf.work_mode=="oauth" then
        oauth.addHeader(conf)
    end 
    

end



function WechatOAuthHandler:access(conf)

    if conf.work_mode=="oauth" then

        oauth.access(conf)
    end 

    if conf.work_mode == "getuserinfo" then 

        local accessID=utils.getAccessID()
        if not accessID then
            return utils.forbidden_response("You cannot consume this service")
        end 
        exchange_token.access(conf,accessID)
    end 

end


WechatOAuthHandler.PRIORITY = 798
WechatOAuthHandler.VERSION = "0.0.1"


return WechatOAuthHandler
