local redis_tool = require "utils.commons.redis_tool"
local cjson = require "cjson"
local utils = require "utils.commons.version_tool"
local ngx = ngx


local _M = {}


local function accessRedis(config,type,id,serialNo)


    local red=redis_tool.connect(config)

    local res=nil

    if type=="accessID" then

        local globalID = red:hget("consumer_rel:hash",id)
       
        local json = red:hget("account:hash", globalID)

        res= cjson.decode(json)
    elseif type=="privatekey"  then

        res = red:hget("wechat_payv3:user:"..id..":privatekey:hash",serialNo)

    elseif type=="publickey" then

        local  serials = red:zrange("wechat_payv3:platform:"..id..":key_serial:queue",-2,-1)

        local pks=red:hmget("wechat_payv3:platform:"..id..":publickey:hash",table.unpack(serials))

        if pks then
            res={}
            
            for i,v in pairs(pks) do
                ngx.log(ngx.INFO,i,v,serials[i])
                res[serials[i]]=v
            end
        end
    else
        res=nil
    end 

    red:close()

    return res
end

function _M.getUserPrivateKeyByMchID(config, mchID,serialNo)

    local result,err =utils.cache_mchid_privateKey(
        mchID,serialNo,config.keysttl,accessRedis,
        config, "privatekey", mchID,serialNo)
    return result,err

    
end

function _M.getPlatformPublicKeysByMchID(config, mchID)

    local result,err =utils.cache_mchid_publicKey(
        mchID,config.keysttl,accessRedis,
        config,  "publickey",mchID,nil)
    return result,err
    
end


function _M.getAppInfoByAccessID(config, accessID)

    local result,err =utils.cache_accessid_appinfo(
        accessID,config.appinfottl,accessRedis,
        config,  "accessID",accessID,nil)
    return result,err

    
end



return _M