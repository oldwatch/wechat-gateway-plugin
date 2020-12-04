local BasePlugin = require "kong.plugins.base_plugin"
local ngx = ngx 
local cjson = require "cjson"

local kong = kong
local singletons = require "kong.singletons"


local CacheMaintainHandler = BasePlugin:extend()


local function getcache()

    if singletons then
        return singletons.cache
    else 
        return kong.cache
    end
    
end

local function getRequestCtx()

    ngx.req.read_body()
    local data = ngx.req.get_body_data()
    return data
end

local function sendResult(ttl,val)
    ngx.log(ngx.INFO,tostring(ttl),tostring(val))
    local  result={}
    result["ttl"]=ttl
    result["value"]=val
    local result_txt=cjson.encode(result)
    ngx.say(result_txt)
end

function CacheMaintainHandler:access(conf)

    local ctx = ngx.ctx
 
    local header_name,err=ngx.req.get_headers()["x-kong-cache-maintain"]
    if err == "truncated" then
        ngx.exit(200)
        return
    end
    
    local args,err=ngx.req.get_uri_args()
    if err == "truncated" then
        ngx.exit(200)
        return
    end

    local cache_key=args["cache_key"]
    if not cache_key  then
        ngx.exit(200)
        return 
    end
    
    local method=ngx.req.get_method()

    ngx.log(ngx.INFO,method,cache_key)
    
    local cache=getcache()

    if method=="GET" then
        local ttl, err, value = cache:probe(cache_key)
        if err then 
            ngx.say(tostring(err))
            return 
        end
        sendResult(ttl,value)
    elseif method=="DELETE" then
        cache:invalidate(cache_key)	
        ngx.say("delete cache "..cache_key)
    elseif method=="PUT" then 

        local ttl, err, value = cache:probe(cache_key)
        if err then 
            ngx.say(tostring(err))
            return 
        end
        cache:invalidate(cache_key)
        local val,err=cache:get(cache_key,  { ttl = ttl },getRequestCtx)
        if err then 
            ngx.say(tostring(err))
            return 
        end
        sendResult(ttl,value)
    elseif method=="POST" and cache_key=="_all_cache_" then

        cache:purge()
        ngx.say("clear everything")

    else
        ngx.say("do nothing")
    end
    
    ngx.exit(200)

end


CacheMaintainHandler.PRIORITY = 798
CacheMaintainHandler.VERSION = "0.0.1"


return CacheMaintainHandler
