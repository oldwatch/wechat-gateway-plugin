local sign_tool = require "utils.commons.sign_tool" 
local utils = require "utils.commons.version_tool"
local redis_dao = require "kong.plugins.wechat-pay.redis_dao" 
local xml2lua = require "xml2lua"
local handler = require "xmlhandler.tree"
-- local cert_store= require "kong.plugins.wechat-pay.cert_store"

local ngx = ngx

local _M = {}

local root_str="xml"

local function sign(signtype,fields, secretKey)

    local sign_inst,err=sign_tool.new(secretKey,signtype)

    if err then
        return nil,err
    end

    local output,err=sign_inst:addSign(fields)

    return output,err
end

function _M.doSignWork(config,appInfo,data)

    -- local cert,err=cert_store.getClientCert(appInfo,config)

    -- if not cert or err then
    --     error("can not get cert"..tostring(err))
    -- end


    local secretPayKey=appInfo["secretPayKey"]

    ngx.ctx.secretPayKey=secretPayKey

    
    local parser  = xml2lua.parser(handler)
    parser:parse(data)
    local fields = handler.root[root_str]

    fields["appid"]=appInfo.appID
    if appInfo.mchID then
        fields["mch_id"]=appInfo.mchID
    end

    local new_fields,err = sign(config.signtype,fields,secretPayKey)
    if err then
        error(err)
    end

    return xml2lua.toXml(new_fields,root_str)    

end




return _M
