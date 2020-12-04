package = "kong-plugin-wechat-oauth"  

version = "0.0.1-1"               

local pluginName = package:match("^kong%-plugin%-(.+)$") 

supported_platforms = {"linux"}
source = {
  url = "https://github.com/oldwatch/wechat-gateway-plugin.git",
  tag = "0.0.1"
}

description = {
  summary = "plugin for wechat pay request modify",
  homepage = "http://demo.org",
}

dependencies = {
    "utils-commons >= 0.1.0",
    "lua >= 5.1",
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins.wechat-oauth.handler"] = "kong/plugins/wechat-oauth/handler.lua",
    ["kong.plugins.wechat-oauth.redis_daos"] = "kong/plugins/wechat-oauth/redis_daos.lua",
    ["kong.plugins.wechat-oauth.schema"] = "kong/plugins/wechat-oauth/schema.lua",
    ["kong.plugins.wechat-oauth.exchange_token"] = "kong/plugins/wechat-oauth/exchange_token.lua",
    ["kong.plugins.wechat-oauth.oauth"] = "kong/plugins/wechat-oauth/oauth.lua",
  }
}
