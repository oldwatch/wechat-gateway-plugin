local ngx = ngx 
local ssl = require "ngx.ssl"
local tls = require "resty.kong.tls"
local cert_store=require "kong.plugins.wechat-pay.cert_store"

_M  = {}

function _M.bindCtx(appID)

    local cert=cert_store.getCert(appID)

    local cert_chain, err = ssl.parse_pem_cert(cert)
    if err then
        ngx.log(ngx.ERR, "failed to convert certificate chain ",err)
        error(err)
    end


    -- assuming the user already defines the my_load_private_key()
    -- function herself.
    local key=cert_store.getPrivateKey(appID)

    local priv_key, err = ssl.parse_pem_priv_key(key)
    if err then
        ngx.log(ngx.ERR, "failed to convert private key ",
                err)
        error(err)
    end

    ok, err = tls.set_upstream_cert_and_key(cert_chain, priv_key)
    
    if err then 
        ngx.log(ngx.ERR,"fail set cert & key",err)
        error(err)
    end

end


return _M
