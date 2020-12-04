package = "kong-plugin-wechat-pay"  

version = "0.0.1-1"               

local pluginName = package:match("^kong%-plugin%-(.+)$") 

supported_platforms = {"linux"}
source = {
  url = "https://github.com/oldwatch/gateway-plugin.git",
  tag = "0.0.1"
}

description = {
  summary = "plugin for wechat access token bind",
  homepage = "http://demo.org",
}

dependencies = {
    "utils-commons >= 0.1.0",
    "lua >= 5.1",
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins.wechat-pay.handler"] = "kong/plugins/wechat-pay/handler.lua",
    ["kong.plugins.wechat-pay.redis_dao"] = "kong/plugins/wechat-pay/redis_dao.lua",
    ["kong.plugins.wechat-pay.bind_cert"] = "kong/plugins/wechat-pay/bind_cert.lua",
    ["kong.plugins.wechat-pay.azure_access"] = "kong/plugins/wechat-pay/azure_access.lua",
    ["kong.plugins.wechat-pay.cert_store"] = "kong/plugins/wechat-pay/cert_store.lua",
    ["kong.plugins.wechat-pay.filter_body"] = "kong/plugins/wechat-pay/filter_body.lua",
    ["kong.plugins.wechat-pay.access"] = "kong/plugins/wechat-pay/access.lua",
    ["kong.plugins.wechat-pay.schema"] = "kong/plugins/wechat-pay/schema.lua",
  }
}
