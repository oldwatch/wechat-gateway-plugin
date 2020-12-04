local typedefs = require "kong.db.schema.typedefs"


return {

    no_consumer = true ,

    fields = {
        modifybody = { type = "boolean", default = false, required = false } ,
        bind_replytype= { type = "string", required = false } , 
        tokenttl = { type = "number", default = 240, required = false } ,
        appinfottl = { type = "number", default = 600, required = false } ,
        redis_pwd = { type = "string", required = false } ,
        redis_ssl = { type = "boolean", required = false } ,
        redis_url = { type = "string", required = false } ,
        redis_masterurl = {type = "string", required = false},
        redis_cluster = { type = "array", required = false } ,
        redis_sentinels = { type = "array", required = false } ,
    },


}
