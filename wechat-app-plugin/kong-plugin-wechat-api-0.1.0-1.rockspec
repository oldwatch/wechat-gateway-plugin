package = "kong-plugin-wechat-api"  

version = "0.1.0-1" 

local pluginName = package:match("^kong%-plugin%-(.+)$") 

supported_platforms = {"linux"}
source = {
  url = "https://github.com/oldwatch/wechat-gateway-plugin.git",
  tag = "0.1.0"
}

description = {
  summary = "plugin for wechat access token bind",
  homepage = "http://demo.org",
}

dependencies = {
    "lua >= 5.1",
    "utils-commons >= 0.1.0",
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins.wechat-api.handler"] = "kong/plugins/wechat-api/handler.lua",
    ["kong.plugins.wechat-api.access"] = "kong/plugins/wechat-api/access.lua",
    ["kong.plugins.wechat-api.redis_daos"] = "kong/plugins/wechat-api/redis_daos.lua",
    ["kong.plugins.wechat-api.schema"] = "kong/plugins/wechat-api/schema.lua",
  }
}
