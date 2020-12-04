local sign_tool = require "utils.commons.sign_tool"
local encrypt_tool = require "utils.commons.encrypt_tool"
local utils = require "utils.commons.version_tool"
local redis_dao = require "kong.plugins.wechat-callback.redis_daos"
local kafka_tool = require "utils.commons.kafka_tool"

local xml2lua = require "xml2lua"
local handler = require "xmlhandler.tree"
local resty_sha1 = require "resty.sha1"
local resty_str = require "resty.string"

local ngx = ngx

local _M = {}

local success_resp="success"

local encrypt_str="Encrypt"
local touser_str="ToUserName"
local appid_str="AppId"
local root_str="xml"

local from_str="FromUserName"
local create_str="CreateTime"
local signature_str="msg_signature"
local timestamp_str="timestamp"
local nonce_str="nonce"


function _M.verifyWechatVerfiy(conf,fields)

    local token=conf.verify_token

    local params={fields[timestamp_str],fields[nonce_str],token}

    table.sort(params)

    local sha1 = resty_sha1:new()
    if not sha1 then 
        return nil," cannot do sha1 operate"
    end

    for _,v in ipairs(params) do 
        local ok=sha1:update(v)
        if not ok then 
            return nil,"do sha-1 operate fail"
        end
    end

    local digest = sha1:final()

    local sign= resty_str.to_hex(digest)

    ngx.log(ngx.INFO,sign," : ",fields["signature"])
    return  sign == fields["signature"]
    
end


function _M.parseXml(data)
    local parser  = xml2lua.parser(handler)
    
    parser:parse(data)

    local fields = handler.root[root_str]

    return fields
end

function _M.toXml(fields)

    return xml2lua.toXml(fields,root_str)    

end

function _M.getAppID(fields)

    local app_id=fields[touser_str]
    if not app_id then
        app_id=fields[appid_str]
    end
    return app_id
end


function _M.sendToKafka(conf,key,data)

    if not key then 
        ngx.log(ngx.DEBUG,"not found key")
        key="timestamp"..tostring(ngx.now())
    end

    --for  no kafka env
    if not conf.kafka_cluster then
        if data then 
            redis_dao.pushDataToList(conf,data)
        end
        utils.success_response(success_resp)
        return
    end
    
    local prod,err=kafka_tool.producer(conf)
    if err then
        ngx.log(ngx.INFO,"can not create kafka"..err)
        utils.internal_error_response(err)
        return 
    end

    local ok,err=prod:send(conf.kafka_topic,key,data)

    if ok then
        utils.success_response(success_resp)
    else 
        ngx.log(ngx.INFO,"can not send msg"..tostring(err))
        utils.internal_error_response(err)
    end 

end 



return _M
