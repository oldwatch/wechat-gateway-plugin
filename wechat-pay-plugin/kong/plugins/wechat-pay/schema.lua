local typedefs = require "kong.db.schema.typedefs"

return {

    no_consumer = true ,

    fields = {
      signtype = { type = "string", default = "HMAC-SHA256", required = false } ,
      need_cert = { type = "boolean", default = false, required = false } ,
      certbind_service=  { type= "string", default= "" ,required = false },
 --     azure_token_host= { type = "string", required = false },
      appinfottl = { type = "number", default = 600, required = false } ,
      redis_pwd = { type = "string", required = false } ,
      redis_ssl = { type = "boolean", required = false } ,
      redis_url = { type = "string", required = false } ,
      redis_masterurl = {type = "string", required = false},
      redis_cluster = { type = "array", required = false } ,
      redis_sentinels = { type = "array", required = false } ,
    },


}
