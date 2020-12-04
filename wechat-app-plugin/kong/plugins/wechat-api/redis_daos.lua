local redis_tool = require "utils.commons.redis_tool"
local cjson = require "cjson"
local utils = require "utils.commons.version_tool"
local ngx = ngx


local function accessRedis(config, accessID, type)


    local red=redis_tool.connect(config)

    local res
    if type == "token" then

        local token=  red:get("wechat:app:token:"..accessID)

        if token == ngx.null then 
            red:close()
            error("not found app token ")
        end

        local ticket= red:get("wechat:app:ticket:wx_card:"..accessID)
    
        res={}
        ngx.log(ngx.INFO,token)

        res["token"]=token
        if ticket ~= ngx.null then
            res["ticket"]=ticket
        end

    elseif type == "accessID" then

        local id = red:hget("consumer_rel:hash", accessID)
        
        if id == ngx.null then 
            red:close()
            error("not found relation app id ")
        end 

        ngx.log(ngx.INFO,id)

        local json = red:hget("account:hash", id)

        if json == ngx.null then 
            red:close()
            error("not found relation app info ")
        end

        res= cjson.decode(json)

   
    else
        res={}

    end

    red:close()

    return res
end

local _M = {}

function _M.getToken(config, accessID)

    local appInfo,err=_M.getAppInfoByAccessID(config,accessID)
    if not appInfo then 
        ngx.log(ngx.ERR,"not found relation app ",accessID,err)
        return nil
    end

    local appID=appInfo.appID
    local result= utils.cache_appid_token(appID,config.tokenttl,
            accessRedis, config, appID, "token")

    return result
end


function _M.getAppInfoByAccessID(config, accessID)

    local result,err =utils.cache_accessid_appinfo(
        accessID,config.appinfottl,accessRedis,
        config, accessID, "accessID")
    return result,err
    
end

return _M