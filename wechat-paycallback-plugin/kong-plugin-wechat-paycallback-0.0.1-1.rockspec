package = "kong-plugin-wechat-paycallback"  

version = "0.0.1-1"               

local pluginName = package:match("^kong%-plugin%-(.+)$") 

supported_platforms = {"linux"}
source = {
  url = "https://github.com/oldwatch/gateway-plugin.git",
  tag = "0.1.0"
}

description = {
  summary = "plugin for wechat jpay call back",
  homepage = "http://demo.org",
}

dependencies = {
    "utils-commons >= 0.1.0",
    "lua >= 5.1",
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins.wechat-paycallback.handler"] = "kong/plugins/wechat-paycallback/handler.lua",
    ["kong.plugins.wechat-paycallback.access"] = "kong/plugins/wechat-paycallback/access.lua",
    ["kong.plugins.wechat-paycallback.schema"] = "kong/plugins/wechat-paycallback/schema.lua",
    ["kong.plugins.wechat-paycallback.redis_dao"] = "kong/plugins/wechat-paycallback/redis_dao.lua",
  }
}