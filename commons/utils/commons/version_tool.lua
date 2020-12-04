_NETTLE_LIB_PATH = "/usr/local/kong/lib"
local kong = kong
local singletons = require "kong.singletons"
local ngx=ngx
local cjson = require "cjson"


local _M = {}

if singletons then
    _M.tool=singletons
else 
    _M.tool=kong
end

function _M.forbidden_response(msg)

    ngx.say(msg)
    ngx.exit(403)

end

local function cache_get(key,ttl,cb,params)
    local tool
    if singletons then
        tool=singletons
    else 
        tool=kong
    end

    ngx.log(ngx.INFO,"cache key:",key)

    return tool.cache:get(key, { ttl = ttl },cb,table.unpack(params))
end

local function call_cache_get(key,ttl,cb,...)

    local status,result= pcall(cache_get,key, ttl,cb,table.pack(...))

    if  not status then
        ngx.log(ngx.ERR,"call cache get fail",tostring(result))
        return nil,result
    end

    return result
end

function _M.cache_appid_token(appID,ttl,cb,...)
    
    local key="token" .. appID
    return call_cache_get(key,ttl,cb,...)
end


function _M.cache_accessid_appinfo(accessID,ttl,cb,...)
    
   
    local key="accessID" .. accessID

    return call_cache_get(key,ttl,cb,...)
end

function _M.cache_mchid_privateKey(mchID,serial,ttl,cb,...)
    
    local cache_key="mchID_privateKey_"..serial.."_"..mchID

    return call_cache_get(cache_key,ttl,cb,...)
end

function _M.cache_mchid_publicKey(mchID,ttl,cb,...)
    
    local cache_key="mchID_publicKey_"..mchID

    return call_cache_get(cache_key,ttl,cb,...)
end

function _M.cache_access_callback(accessID,ttl,cb,...)

    local cache_key="callback_"..accessID
    return call_cache_get(cache_key,ttl,cb,...)

end

function _M.cache_mchid_serial_publicKey(mchID,serial,ttl,cb,...)
    
    local cache_key="serial_"..serial.."_publicKey_"..mchID

    return call_cache_get(cache_key,ttl,cb,...)
end

function _M.cache_appid_appinfo(appID,ttl,cb,...)
    
    local key="appID" .. appID

    return call_cache_get(key,ttl,cb,...)
end


function _M.cache_token_tokeninfo(token,ttl,cb,...)
    
    local key="exchange_token"..token
    return call_cache_get(key,ttl,cb,...)
end

function _M.internal_error_response(resp)
    ngx.say(tostring(resp))
    ngx.exit(501)
end    

function _M.success_response(body)
    ngx.say(tostring(body))
    ngx.exit(200)
end    

function _M.empty_response()
    ngx.exit(200)
end    

function _M.fill_route_target(upstream_url)

    ngx.log(ngx.INFO,upstream_url)
    
    local exp="([^:]+)://([^/:]+):?(%d*)(.*)"

    local _,_,schema,host,port,suburl = string.find(upstream_url,exp)

    if not port or port == "" then 
        if schema=="https" then
            port=443
        else    
            port=80
        end
    end

    ngx.var.upstream_uri=suburl

    local ba = ngx.ctx.balancer_address

    ba.scheme = schema
    ba.host = host
    ba.type = "name"
    ba.port = port

end

function _M.filterRoute(route,fields)

    local sign=true
    for k,v in pairs(route) do 
        if string.sub(k,1,1) ~= "_"  then 
            local val=fields[k]
            if not val then 
                sign=false
                break
            end
            local t=type(v)
            local strval=tostring(val)
            local s=true
            if t == "string" then 
                s= strval == v 
            elseif  t=="table" then
                s= v[strval]
            else
            end

            if not s then 
                sign=false
                break
            end 
        end
    end
    if sign then 
        return route["_customer"]
    else
        return nil
    end
end


function _M.getAccessID()

    local ctx = ngx.ctx

    local authenticated_consumer = ctx.authenticated_consumer
    local accessID
    if authenticated_consumer then
        accessID = authenticated_consumer.username
    else
        local header,err =ngx.req.get_headers()
        if not err then
            accessID=header["x-consumer-username"]
        end
        if not accessID then
            return nil
        end 
    end

    ngx.log(ngx.INFO,"accessID" .. accessID)
    return accessID
end


function _M.getUpstreamUrl()

    local ba = ngx.ctx.balancer_address
    local schema=ngx.var.upstream_scheme 
    local host=ba.host
    local port=ba.port
    local path=ngx.var.upstream_uri

    local fullurl=schema.."://"..host..":"..port..path

    return fullurl
end

return _M
