package = "kong-plugin-cache-maintain"  

version = "0.0.1-1" 

local pluginName = package:match("^kong%-plugin%-(.+)$") 

supported_platforms = {"linux"}
source = {
  url = "https://github.com/oldwatch/gateway-plugin.git",
  tag = "0.0.1"
}

description = {
  summary = "plugin for maintain business cache",
  homepage = "http://demo.org",
}

dependencies = {
    "lua >= 5.1",
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins.cache-maintain.handler"] = "kong/plugins/cache-maintain/handler.lua",
    ["kong.plugins.cache-maintain.schema"] = "kong/plugins/cache-maintain/schema.lua",
  }
}
