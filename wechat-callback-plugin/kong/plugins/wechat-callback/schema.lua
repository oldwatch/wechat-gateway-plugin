local typedefs = require "kong.db.schema.typedefs"



return {

    no_consumer = true ,

    fields = {
      appinfottl = { type = "number", default = 600, required = false } ,
      tokenttl = { type = "number", default = 240, required = false } ,
      verify_token = { type = "string", required = false } ,
      kafka_cluster =  {type="array",required = false },
      kafka_topic  = {type="string",required = false,default = "demo.callback.msg"},
      redirect_to  = {type="array",required= false },
      msg_bind = {type="object",required= false,default={TEMPLATESENDJOBFINISH=true,MASSSENDJOBFINISH=true} },
      redis_pwd = { type = "string", required = false } ,
      redis_ssl = { type = "boolean", required = false } ,
      redis_url = { type = "string", required = false } ,
      redis_masterurl = {type = "string", required = false},
      redis_cluster = { type = "array", required = false } ,
      redis_sentinels = { type = "array", required = false } ,
    },


}
