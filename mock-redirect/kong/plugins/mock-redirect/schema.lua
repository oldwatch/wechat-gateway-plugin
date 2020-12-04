local typedefs = require "kong.db.schema.typedefs"


return {

    no_consumer = true ,

    fields = {
        mock_host = { type = "string",  required = false } ,
        mock_path_prefix = { type = "string",required = false } ,
        redirect_path= {type= "string",require= false },
    },


}
