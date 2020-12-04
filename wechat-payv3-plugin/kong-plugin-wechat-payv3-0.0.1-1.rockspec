package = "kong-plugin-wechat-payv3"  

version = "0.0.1-1"               

local pluginName = package:match("^kong%-plugin%-(.+)$") 

supported_platforms = {"linux"}
source = {
  url = "https://github.com/oldwatch/gateway-plugin.git",
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
    ["kong.plugins.wechat-payv3.handler"] = "kong/plugins/wechat-payv3/handler.lua",
    ["kong.plugins.wechat-payv3.redis_dao"] = "kong/plugins/wechat-payv3/redis_dao.lua",
    ["kong.plugins.wechat-payv3.access"] = "kong/plugins/wechat-payv3/access.lua",
    ["kong.plugins.wechat-payv3.filter_body"] = "kong/plugins/wechat-payv3/filter_body.lua",
    ["kong.plugins.wechat-payv3.schema"] = "kong/plugins/wechat-payv3/schema.lua",
  }
}
