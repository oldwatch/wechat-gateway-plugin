local redis_tool = require "utils.commons.redis_tool"
local cjson = require "cjson"
local utils = require "utils.commons.version_tool"
local ngx = ngx



local _M = {}


local function accessRedis(config, id,service,serialNo)

    local red=redis_tool.connect(config)

    local res=nil
    if service == "publickey" then

        res  = red:hget("wechat_payv3:platform:"..id..":publickey:hash",serialNo)

    elseif service == "wechat_payv3" then 
        local json = red:hget("account:hash", id)

        res= cjson.decode(json)
    else 
        local globalID= red:hget("wechat_pay:account:hash", id)

        local json = red:hget("account:hash", globalID)

        res= cjson.decode(json)
    end
  
    red:close()

    return res
end

function _M.getPlatformPublicKeyByID(config, mchID,serialNo)

    local result,err =utils.cache_mchid_serial_publicKey(
        mchID,serialNo,config.appinfottl,accessRedis,
        config, mchID, "publickey",serialNo)
    return result,err

    
end

function _M.getPayAppInfoByAppID(config, mchID)

    return utils.cache_appid_appinfo(mchID,config.appinfottl,accessRedis, config, mchID,"wechat_pay",nil)

end

function _M.getPayV3AppInfoByAppID(config, globalID)

    return utils.cache_appid_appinfo(globalID,config.appinfottl,accessRedis, config, globalID,"wechat_payv3",nil)

end


return _M
