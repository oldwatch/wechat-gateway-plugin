local typedefs = require "kong.db.schema.typedefs"


return {

    no_consumer = true ,

    fields = {
        appinfottl = { type = "number", default = 600, required = false } ,
        tokenttl = { type = "number", default = 60, required = false } ,
        work_mode= { type = "string", default = "oauth", required = false } ,
        wechat_token_host= { type = "string", default = "https://api.weixin.qq.com", required = false } ,
        refresh_token_url= { type = "string", default = "https://api.weixin.qq.com", required = false } ,
        redis_pwd = { type = "string", required = false } ,
        redis_ssl = { type = "boolean", required = false } ,
        redis_url = { type = "string", required = false } ,
        redis_masterurl = {type = "string", required = false},
        redis_cluster = { type = "array", required = false } ,
        redis_sentinels = { type = "array", required = false } ,
      },

}
