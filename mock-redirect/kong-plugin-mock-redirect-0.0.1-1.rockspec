package = "kong-plugin-mock-redirect"  

version = "0.0.1-1" 

local pluginName = package:match("^kong%-plugin%-(.+)$") 

supported_platforms = {"linux"}
source = {
  url = "https://github.com/oldwatch/wechat-gateway-plugin.git",
  tag = "0.0.1"
}

description = {
  summary = "plugin for redirect mock request",
  homepage = "http://demo.org",
}

dependencies = {
    "lua >= 5.1",
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins.mock-redirect.handler"] = "kong/plugins/mock-redirect/handler.lua",
    ["kong.plugins.mock-redirect.schema"] = "kong/plugins/mock-redirect/schema.lua",
  }
}
