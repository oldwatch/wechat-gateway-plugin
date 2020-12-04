local http = require "resty.http"

local setmetatable = setmetatable
local ngx = ngx


_M={}

local mt = { __index = _M }


local max_idle_timeout=500
local pool_size = 2

local fixed_field_metatable = {
    __index =
        function(t, k) -- luacheck: ignore 212
            error("field " .. tostring(k) .. " does not exist", 3)
        end,
    __newindex =
        function(t, k, v) -- luacheck: ignore 212
            error("attempt to create new field " .. tostring(k), 3)
        end,
}

function _M.request_uri(url,params)

    local httpc = http.new()
    local res, err = httpc:request_uri(url, params)

    if not res then 
        return nil ,err
    end

    local ok, err = httpc:set_keepalive(max_idle_timeout, pool_size)
    if not ok then
        ngx.log(ngx.INFO,"failed to set keepalive")
    end 
    return res
end 

function _M.new()

    local httpc,err = http.new()

    if err then 
        return nil,err
    end

    httpc:set_timeout(500)

    return setmetatable({
        httpc =httpc
    }, mt)
end 

function _M.request(self,param)

    local httpc=self.httpc

    local res, err = httpc:request(
        param
    )

    if err then
        return nil,"failed to request: "..tostring(err)
    end


    if not res.has_body then 
        return nil
    end   
    local reader = res.body_reader

    local body=""
    repeat
        local chunk, err = reader(8192)
        if err then
            ngx.log(ngx.ERR, err)
        break
        end

        if chunk then
            body=body..chunk
        end
    until not chunk

    return body

end

function _M.simple_post(self,url,body,contentType,param)

    local httpc=self.httpc 

    if not param then
        param={}
    end

    param.method="POST"
    param.ssl_verify=false
    param.body=body

    local headers={}
    headers["Content-Type"]=contentType
    param.headers=headers

    local resp,err=httpc:request_uri(url,param)

    if err then 
        error(err)
    end

    return resp.body,resp.status
end

function _M.api_post(self,url,token,body)

    local httpc=self.httpc 

    local param={}
    
    param.method="POST"
    param.ssl_verify=true
    param.query="access_token="..token
    param.body=body
    local headers={
        ["Content-Type"] = "application/json",
      }
    param.headers = headers
    param.keepalive_timeout = 60000
    param.keepalive_pool = 10

    local resp,err=httpc:request_uri(url,param)

    if err then 
        error(err)
    end

    return resp
end

function _M.set_timeout(self,timout)
    local httpc=self.httpc 
    httpc:set_timeout(timeout)
end


function _M.simple_get(self,url,param)

    local httpc=self.httpc 

    if not param then
        param={}
    end

    param.method="GET"
    param.ssl_verify=false

    local resp,err=httpc:request_uri(url,param)

    if err then 
        error(err)
    end

    return resp.body
end

function _M.close(self)
    local httpc=self.httpc

    local ok, err = httpc:set_keepalive(max_idle_timeout, pool_size)
    if not ok then
        return nil,"failed to set keepalive: "..err
    end 
end




return setmetatable(_M,fixed_field_metatable)