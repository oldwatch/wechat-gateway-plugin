local typedefs = require "kong.db.schema.typedefs"


return {

    no_consumer = true ,

    fields = {
      appinfottl = { type = "number", default = 600, required = false } ,
      pay_version = { type = "string", default = "v3", required = false } ,
      kafka_cluster =  {type="array",required = false },
      kafka_topic  = {type="string",required = false,default = "demo.callback.msg"},
      redirect_to  = {type="array",required= false },
      redis_pwd = { type = "string", required = false } ,
      redis_ssl = { type = "boolean", required = false } ,
      redis_url = { type = "string", required = false } ,
      redis_masterurl = {type = "string", required = false},
      redis_cluster = { type = "array", required = false } ,
      redis_sentinels = { type = "array", required = false } ,
    },
  }
