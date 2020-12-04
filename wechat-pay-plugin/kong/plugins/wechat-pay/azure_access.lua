local http_tool = require "utils.commons.http_tool"
local encrypt_tool= require "utils.commons.encrypt_tool" 
local utils = require "utils.commons.version_tool"
local cjson = require "cjson"
local ngx = ngx

local _M = {}

function _M.getCertSecretByAppID(appInfo,azure_token_host)

    local appID=appInfo.appID
    
    local http,err = http_tool.new()

    if err then
        return nil,err
    end 

    local url=azure_token_host.."/azure/"..appID.."/keyvault/access_token"
    local encrypt_token,err= http:simple_get(url)

    if  err then 
        return nil,err
    end

    local secretKey =appInfo["secretSignKey"]
    local azure_token,err = encrypt_tool.decryptForMsg(encrypt_token,secretKey)

    if err then 
        return nil,err
    end
    local url=appInfo["clientCertVaultUrl"]

    local headers={
        ["Authorization"]="Bearer "..azure_token
    }
    local param={
        headers=headers,
        query = "api-version=7.0",
    }

    http:set_timeout(5000)
    local json,err= http:simple_get(url,param)

    http:close()

    local secret_info=cjson.decode(json)
    
    local error=secret_info["error"]
    if error then 
        return nil,error
    end

    local secret=secret_info["value"]

    return secret
    -- return ngx.decode_base64(secret)
end


return _M
