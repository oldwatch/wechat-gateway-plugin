package = "kong-plugin-wechat-callback"  

version = "0.1.0-1"               

local pluginName = package:match("^kong%-plugin%-(.+)$") 

supported_platforms = {"linux"}
source = {
  url = "https://github.com/oldwatch/gateway-plugin.git",
  tag = "0.1.0"
}

description = {
  summary = "plugin for wechat callback",
  homepage = "http://demo.org",
}

dependencies = {
    "utils-commons >= 0.1.0",
    "lua >= 5.1",
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins.wechat-callback.handler"] = "kong/plugins/wechat-callback/handler.lua",
    ["kong.plugins.wechat-callback.access"] = "kong/plugins/wechat-callback/access.lua",
    ["kong.plugins.wechat-callback.schema"] = "kong/plugins/wechat-callback/schema.lua",
    ["kong.plugins.wechat-callback.msg_receive"] = "kong/plugins/wechat-callback/msg_receive.lua",
    ["kong.plugins.wechat-callback.redis_daos"] = "kong/plugins/wechat-callback/redis_daos.lua",
  }
}