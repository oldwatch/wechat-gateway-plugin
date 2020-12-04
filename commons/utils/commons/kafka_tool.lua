local kafka = require "resty.kafka.client"
local producer = require "resty.kafka.producer"
local ngx=ngx

_M={}


local mt = { __index = _M }

local function defaultErr(err)
    ngx.log(ngx.ERR,err)
end

local function getBrokerList(config)

    local broker_list= {}

    if config.kafka_cluster then
        for n,v in ipairs(config.kafka_cluster) do
            local serv = {}
            local _,_,host,port= string.find(v,"([^:]+)%s*:%s*(%d+)")
            serv.port=port
            serv.host=host
            broker_list[n]=serv
        end
    end

    return broker_list

end

function _M.producer(config,error)

    if not error then 
        error=defaultErr
    end 

    local broker_list=getBrokerList(config)

    local prod_config = {
        producer_type="async",
        api_version=2,
        error_handler=error
    }


    local prod,err = producer:new(broker_list,prod_config)

    if err then 
        return null,err
    end 

    return setmetatable({
        prod = prod
    }, mt)

end

function _M.producer_sync(config)

    local broker_list=getBrokerList(config)

    local prod_config = {
        producer_type="sync",
        api_version=2
    }


    local prod,err = producer:new(broker_list,prod_config)

    if err then 
        return null,err
    end 

    return setmetatable({
        prod = prod
    }, mt)

end


function _M.send(self,topic,key,message)

    local prod=self.prod

    return  prod:send(topic,key,message)

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