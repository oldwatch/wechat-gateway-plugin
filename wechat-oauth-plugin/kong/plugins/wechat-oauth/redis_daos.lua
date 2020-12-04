local redis_tool = require "utils.commons.redis_tool"
local encrypt_tool = require "utils.commons.encrypt_tool"
local cjson = require "cjson"
local utils = require "utils.commons.version_tool"
local ngx = ngx


local function getAppInfo(config, accessID)

    local red=redis_tool.connect(config)
            
    local id = red:hget("consumer_rel:hash", accessID)
            
    local json = red:hget("account:hash", id)

    res= cjson.decode(json)

    local relJson=red:hget("consumer_rel:relationinfo:hash",accessID)
    local rel=cjson.decode(relJson)

    res["redirect"]=rel["redirectTarget"]
    red:close()

    return res
end

local _M = {}

local function getExchangeTokenKey(accessID,exchange_token)
    return "3party_app:"..accessID..":exchange_token:"..exchange_token..":value"
end

local function getTokenKeyName(appID,openID)
    return "wechat:webapplication:app:"..appID..":openid:oauthtoken:"..openID
end 


function _M.saveTokenInfo(config,appID,accessID,tokenInfo)

    local red=redis_tool.connect(config)

        -- {
    --     "access_token":"ACCESS_TOKEN",
    --     "expires_in":7200,
    --     "refresh_token":"REFRESH_TOKEN",
    --     "openid":"OPENID",
    --     "scope":"SCOPE" 
    --   }

    local openID=tokenInfo["openid"]
--"wechat_webapplication:consumer:${0}:$openid:${1}:token"
    local token_key=getTokenKeyName(appID,openID)

    local sign=red:setValue(token_key,tokenInfo["access_token"],tokenInfo["expires_in"])

    local randStr=encrypt_tool.random_str(16)
    local fullInfo="appID"..appID.."openID"..openID.."token"..tokenInfo["access_token"].."random"..randStr
    local exchange_token=encrypt_tool.sha256_hash(fullInfo)

    local json=cjson.encode(tokenInfo)

    local exchange_token_key=getExchangeTokenKey(accessID,exchange_token)    
    red:setValue(exchange_token_key,json,300)

    --":consumer_rel:oauthtoken:${0}:hash"
    local refresh_token_key="wechat:oauth:"..appID..":openidinfo:hash"
    sign=red:hset(refresh_token_key,openID,json)

    red:close()

    return exchange_token
end


function _M.getTokenInfoByExchangeToken(config,accessID, exchange_token)

    local red=redis_tool.connect(config)

    local exchange_token_key=getExchangeTokenKey(accessID,exchange_token)
    local json = red:getValue(exchange_token_key)
    
    if  json == ngx.null then 
        red:close()
        return nil
    end 

    local res= cjson.decode(json)

    red:delValue(exchange_token_key)

    red:close()

    return res
end



function _M.getAccessTokenByAppID(config,appID,openID)

    local red=redis_tool.connect(config)
    --"wechat_webapplication:consumer:${0}:$openid:${1}:token"
    local token_key=getTokenKeyName(appID,openID)
    local res = red:getValue(token_key)
        
    if res==ngx.null then 
        red:close()
        return nil
    end
    
    red:close()
    return res
    
end

function _M.getAppInfoByAccessID(config, accessID)

    local result,err =utils.cache_accessid_appinfo(
        accessID,config.appinfottl,getAppInfo,
        config, accessID)
    return result,err
    
end

return _M