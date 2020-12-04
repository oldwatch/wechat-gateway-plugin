local encrypt_tool = require "utils.commons.encrypt_tool" 
local utils = require "utils.commons.version_tool"
local redis_dao = require "kong.plugins.wechat-payv3.redis_dao" 

local ngx = ngx

local _M = {}

local function sign(signtype,fields, secretKey)

    local sign_inst,err=sign_tool.new(secretKey,signtype)

    if err then
        return nil,err
    end

    local output,err=sign_inst:addSign(fields)

    return output,err
end



function _M.doSignWork(config,mchID,serial,data)

    local pk=redis_dao.getUserPrivateKeyByMchID(config,mchID,serial)

    local method=ngx.req.get_method()

    local path=ngx.var.upstream_uri

    ngx.log(ngx.INFO,"path:",path)

    local timestamp=os.time()

    local nonce=encrypt_tool.random_str(16)

    local fullStr=method.."\n"..path.."\n"..timestamp.."\n"..nonce.."\n"..data.."\n"
    
    local sign,err=encrypt_tool.signWithSHARSA(pk,fullStr)

    if err then 
        ngx.log(ngx.ERR,err)
        return
    end

    local authheader="WECHATPAY2-SHA256-RSA2048 mchid=\""..mchID.."\",nonce_str=\""..nonce.."\",signature=\""..sign.."\",timestamp=\""..timestamp.."\",serial_no=\""..serial.."\""

    ngx.req.set_header("Authorization", authheader)

end




return _M
