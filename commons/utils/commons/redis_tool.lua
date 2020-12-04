local redis_cluster = require "resty.rediscluster.rediscluster"
local redis_connect = require "resty.redis.connector"
local ngx = ngx
local setmetatable = setmetatable

local _M = {}


local mt = { __index = _M }

local function connect_single(config)

    local rc = redis_connect.new({
            connect_timeout = 50,
            read_timeout = 5000,
            keepalive_timeout = 30000,
            -- ssl=config.redis_ssl,
            -- ssl_verify=false,
    })

    local red, err = rc:connect({
        url = config.redis_url,
        password = config.redis_pwd
    })

       
    if err then 
        error(err)
    end 
    return red,err
    
end 


local function connect_sentinel(config)
    local rc = redis_connect.new({
            connect_timeout = 50,
            read_timeout = 5000,
            keepalive_timeout = 30000,
            -- ssl=config.redis_ssl,
            -- ssl_verify=false,
    })
    
    local sentinels_cfg={}
    
    for n,v in ipairs(config.redis_sentinels) do
        local sentinel = {}
        local _,_,host,port= string.find(v,"([^:]+)%s*:%s*(%d+)")
        sentinel.port=port
        sentinel.host=host
    
        sentinels_cfg[n]=sentinel
    end

    local cfg={}

    cfg.sentinels =sentinels_cfg

    cfg.url=config.redis_masterurl
    if  config.redis_pwd then 
        cfg.sentinel_password =config.redis_pwd
    end

    local red, err = rc:connect(cfg)
   
    if err then 
        error(err)
    end 
    return red,err
    
end 

local function connect_cluster(config)

    local name =  "redis_cluster_for_kong"
    
    local rc = {
        dict_name  = "kong_cache",
        name=name,
        keepalive_timeout = 60000,              --redis connection pool idle timeout
        keepalive_cons = 1000,                  --redis connection pool size
        connection_timeout = 1000,              --timeout while connecting
        max_redirection = 5,                    --maximum retry attempts for redirection
        max_connection_attempts = 1,         --maximum retry attempts for connection
    }

    local cfg = {
        ssl=config.redis_ssl,
        ssl_verify=false,
    }

    local serv_list={}

    for n,v in pairs(config.redis_cluster) do
            local serv = {}
            local _,_,host,port= string.find(v,"([^:]+)%s*:%s*(%d+)")
            serv.port=port
            serv.ip=host
            serv_list[n]=serv
    end

    rc.serv_list=serv_list
    if config.redis_pwd then 
        rc.auth=config.redis_pwd
    end

    local red_c,err = redis_cluster:new(rc,cfg)

    if err then 
        error(err)
    end

    return red_c

end 

function _M.connect(config) 

    local factory,type
    if config.redis_cluster then 
        factory=connect_cluster
        type="cluster"
    elseif config.redis_masterurl then 
        factory=connect_sentinel
        type="sentinel"
    else
        factory=connect_single
        type="single"
    end

    local status,result=pcall(factory,config)

    if  not status then
        ngx.log(ngx.ERR,"connect fail",result)
        error(err)
    end

    return setmetatable({
        red =result,
        type=type,
    }, mt)

end

local prefix="{utils:apigateway}:"

function _M.lpush(self,key,val)

    local red=self.red

    local sign, err = red:lpush(prefix..key,val)
    if err then
       error(err.."list  push "..key.." val "..val)
    end     
    return sign

end

function _M.hget(self,col,key)

    local red=self.red

    local id, err = red:hget(prefix..col, key)
    if err then
       error(err.."  col "..col.." key "..key)
    end     
    return id

end



function _M.hset(self,hash,key,val)

    local red=self.red

    local sign,err=red:hset(prefix..hash,key,val)
    if err then
        error(err.."hash "..hash.."  key "..key)
     end     
     return sign

end

function _M.hmget(self,key, ...)

    local red=self.red

    local result, err = red:hmget(prefix..key,...)
    if err then
       error(err.." key "..key)
    end     
    return result

end

function _M.zrange(self,key, ...)

    local red=self.red

    local result, err = red:zrange(prefix..key,...)
    if err then
       error(err.." key "..key)
    end     
    return result

end

function _M.get(self,key)

    local red=self.red

    local id, err = red:get(prefix..key)
    if err then
       error(err.." key "..key)
    end     
    return id

end

function _M.getValue(self,key)

    local red=self.red

    local id, err = red:get(key)
    if err then
       error(err.." key "..key)
    end     
    return id

end


function _M.setValue(self,key,val,ttl)

    local red=self.red

    local sign,err=red:set(key,val,"EX",ttl)
    if err then
        error(err.."  key "..key)
     end     
     return sign

end


function _M.delValue(self,key)

    local red=self.red

    local sign,err=red:del(key)
    if err then
        error(err.."  key "..key)
     end     
     return sign

end


function _M.close(self)

    local type=self.type

    if type ~= "cluster" then 
        local red=self.red
         red:close()
    end

end

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


return setmetatable(_M,fixed_field_metatable)