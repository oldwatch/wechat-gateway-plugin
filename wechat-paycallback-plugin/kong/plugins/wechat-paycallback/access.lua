local sign_tool = require "utils.commons.sign_tool"
local encrypt_tool = require "utils.commons.encrypt_tool"
local utils = require "utils.commons.version_tool"
local kafka_tool = require "utils.commons.kafka_tool"

local redis_dao = require "kong.plugins.wechat-paycallback.redis_dao"

local xml2lua = require "xml2lua"
local handler = require "xmlhandler.tree"
local resty_str = require "resty.string"
local cjson = require "cjson"
local ngx = ngx

local return_str="return_code"
local app_str="appid"
local mch_str="mch_id"
local nonce_str="nonce_str"
local req_str="req_info"
local root_str="xml"
local refund_no_str="out_refund_no"

local _M = {}

local function output(t)

    for i,v in pairs(t) do 
        ngx.log(ngx.INFO,tostring(i),tostring(v))
    end 
end


function _M.verifySignV3(mchID,ctx,conf)

    local headers, err = ngx.req.get_headers()

    if err == "truncated" then
        return false,"headers empty"
    end
    local serial=headers["Wechatpay-Serial"]


    local pk=redis_dao.getPlatformPublicKeyByID(conf,mchID,serial)

    local result,err= encrypt_tool.verifyPayV3Sign(pk,ctx,headers)
    
    return result,err

end

function _M.decryptPayV3Callback(data,secretPayKey)


    local fields=cjson.decode(data)

    local key=fields["id"]

    local resource=fields["resource"]

    if not resource then 
        return fields,key
    end

    local algorithm = resource["algorithm"]
    if  algorithm ~= "AEAD_AES_256_GCM" then
        return fields,key
    end
    
    local plain_ctx=encrypt_tool.decryptAesGCM(resource,secretPayKey)

    fields["decrypt_data"]=cjson.decode(plain_ctx)

    return cjson.encode(fields),key
end


function _M.decryptPayV2Callback(data,config)

    local parser  = xml2lua.parser(handler)
        
    parser:parse(data)

    local fields = handler.root[root_str]


    local return_code=fields[return_str]

    if return_code ~= "SUCCESS"  then 
        return fields
    end

    local app_id=fields[app_str]
    local mch_id=fields[mch_str]

    local req_info=fields[req_str]

    local appinfo,err=redis_dao.getAppInfoByAppID(config,app_id,"wechat_pay")
    
    if err then 
        ngx.log(ngx.ERR,err)
        error(err)
    end 

    local secretKey =appinfo["secretPayKey"]

    local req_txt,err = encrypt_tool.decryptForRefund(req_info,secretKey)
    
    if err or not req_txt then 
        ngx.log(ngx.ERR,err)
        error(err)
    end 

    parser:parse(req_txt)

    local newFields = handler.root[root_str]
    
    local result={}
    result.appid=fields["appid"]
    result.mch_id=fields["mch_id"]
    result.root=newFields

    local nonce=fields[nonce_str]
    local business_key =nonce..newFields[refund_no_str]

    local newbody=xml2lua.toXml(result,"xml")

    return newbody,business_key,err
end



function _M.sendToKafka(conf,key,data)

    if not key then 
        ngx.log(ngx.DEBUG,"not found key")
        key="timestamp"..tostring(ngx.now())
    end

    --for  no kafka env
    if not conf.kafka_cluster then
    
        utils.success_response(data)
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