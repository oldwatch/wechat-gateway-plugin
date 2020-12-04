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
            error("not found relation token ")
        end 


        local ticket= red:get("wechat:app:ticket:wx_card:"..accessID)
    
        res={}
        res["token"]=token
        if ticket then
            res["ticket"]=ticket
        end

    elseif type == "accessID" then
        local id = red:hget("consumer_rel:hash", accessID)

        if id == ngx.null then 
            red:close()
            error("not found relation appid ") 
        end 
        local json = red:hget("account:hash", id)

        if json == ngx.null then 
            red:close()
            error("not found app info ") 
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
    if err then 
        return nil,err
    end

    local appID=appInfo.appID
    local result,err= utils.cache_appid_token(appID,config.tokenttl,
            accessRedis, config, appID, "token")

    return result,err
end


function _M.getAppInfoByAccessID(config, accessID)

    local result,err =utils.cache_accessid_appinfo(
        accessID,config.appinfottl,accessRedis,
        config, accessID, "accessID")
    return result,err
    
end


function _M.setMsgIndex(config,wechatNo, msgID,accessID)

    local red=redis_tool.connect(config)

    local replyType=config.bind_replytype

    red:setValue("msgreply:"..wechatNo..":replytype:"..replyType..":msgid:"..msgID,accessID,3600)

    red:close()

    return res
end

return _M