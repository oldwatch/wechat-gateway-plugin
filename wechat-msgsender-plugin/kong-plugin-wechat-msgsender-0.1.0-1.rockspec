package = "kong-plugin-wechat-msgsender"  

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
    ["kong.plugins.wechat-msgsender.handler"] = "kong/plugins/wechat-msgsender/handler.lua",
    ["kong.plugins.wechat-msgsender.access"] = "kong/plugins/wechat-msgsender/access.lua",
    ["kong.plugins.wechat-msgsender.redis_daos"] = "kong/plugins/wechat-msgsender/redis_daos.lua",
    ["kong.plugins.wechat-msgsender.schema"] = "kong/plugins/wechat-msgsender/schema.lua",
  }
}
