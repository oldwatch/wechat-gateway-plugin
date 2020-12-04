package = "utils-commons"  

version = "0.1.0-1"               

supported_platforms = {"linux"}
source = {
  url = "https://github.com/oldwatch/gateway-plugin.git",
  tag = "0.1.0"
}

description = {
  summary = "commons library"
}

dependencies = {
    "lua >= 5.1",
    "lua-resty-openssl >=0.6.2 ",
    "lua-resty-redis-connector >= 0.08",
    "resty-rediscluster >= 1.0",
    "xml2lua >= 1.4 ",
    "lua-resty-kafka >= 0.09 ",
}

build = {
  type = "builtin",
  modules = {
    ["utils.commons.encrypt_tool"] = "utils/commons/encrypt_tool.lua",
    ["utils.commons.sign_tool"] = "utils/commons/sign_tool.lua",
    ["utils.commons.version_tool"] = "utils/commons/version_tool.lua",
    ["utils.commons.redis_tool"] = "utils/commons/redis_tool.lua",
    ["utils.commons.http_tool"] = "utils/commons/http_tool.lua",
    ["utils.commons.kafka_tool"] = "utils/commons/kafka_tool.lua",

  }
}
