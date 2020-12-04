local redis_tool = require "utils.commons.redis_tool"
local cjson = require "cjson"
local utils = require "utils.commons.version_tool"
local ngx = ngx


local _M = {}


local function accessRedis(config, id,type)

    local red=redis_tool.connect(config)

    local res

    if type=="accessID" then

        local globalID = red:hget("consumer_rel:hash",id)
       
        local json = red:hget("account:hash", globalID)

       
        res= cjson.decode(json)
    end

    red:close()

    return res
end

-- local function callRedisForAppInfoByAccessID(config,accessID)

--     return utils.tool.cache:get("accessID" .. accessID,
--     { ttl = config.appinfottl },
--    accessRedis, config, accessID,"accessID")

-- end  



function _M.getAppInfoByAccessID(config, accessID)

    local result,err =utils.cache_accessid_appinfo(
        accessID,config.appinfottl,accessRedis,
        config, accessID, "accessID")
    return result,err

    -- local status,result = pcall(callRedisForAppInfoByAccessID, config, accessID)

    -- if  not status then
    --     return nil,"cannot get app info by "..accessID..","..tostring(result)
    -- end

    -- return result
    
end



return _M