local BasePlugin = require "kong.plugins.base_plugin"
local ngx = ngx 

local MockRedirectHandler = BasePlugin:extend()

local function fill_redirect_host(redirect_host)

    ngx.log(ngx.INFO,redirect_host)
    
    local exp="([^:]+)://([^/:]+):?(%d*)(.*)"

    local _,_,schema,host,port,suburl = string.find(redirect_host,exp)

    ngx.log(ngx.INFO,schema,host,port)

    if not port or port == "" then
        if schema == "https" then
            port=443
        else    
            port=80
        end
    end

    local url={}

    url["schema"]=schema
    url["host"]=host
    url["port"]=port
    url["suburl"]=suburl

    return url

end

function MockRedirectHandler:header_filter(conf)

    local redirect=conf.redirect_path
    ngx.header["Location"]=redirect

end


function MockRedirectHandler:access(conf)

    local ctx = ngx.ctx

    local headers,err=ngx.req.get_headers()
    if err == "truncated" then
        return
    end

    local header_name=headers["x-mocking-req"]
    if   header_name then 
        
        local mock_host=conf.mock_host
        local prefix=conf.mock_path_prefix

        if prefix then 
            ngx.var.upstream_uri=prefix..ngx.var.upstream_uri
        end 

        local url=fill_redirect_host(mock_host)
        local ba = ngx.ctx.balancer_address

        ba.scheme = url.schema
        ba.host = url.host
        ba.type = "name"
        ba.port = url.port

        return
    end

    -- header_name=headers["x-mock-redirect"]
    -- if header_name then 
        -- local redirect=conf.redirect_path
        -- local url=fill_redirect_host(redirect)

        -- ngx.req.set_header("X-Forwarded-Host", url.host)
        -- ngx.req.set_header("Location", redirect)
        -- local ba = ngx.ctx.balancer_address

        -- ba.scheme = url.schema
        -- ba.host = url.host
        -- ba.type = "name"
        -- ba.port = url.port
        -- ngx.req.set_header("Referer", redirect)
        -- X-Forwarded-Proto
        -- ngx.status = 307
    if conf.redirect_path then
        ngx.exit(307)
        return 
    end
end


MockRedirectHandler.PRIORITY = 798
MockRedirectHandler.VERSION = "0.0.1"


return MockRedirectHandler
