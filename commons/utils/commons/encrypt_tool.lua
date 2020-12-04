local resty_aes = require "resty.aes"
local resty_str = require "resty.string"
local resty_md5 = require "resty.md5"
local resty_sha256 = require "resty.sha256"
local resty_rsa=  require "resty.rsa"
local resty_random = require "resty.random"
_NETTLE_LIB_PATH = "/usr/local/kong/lib"
local aes = require "resty.nettle.aes"
local ngx = ngx 

local _M={}

local function trim(s)
    -- from PiL2 20.4
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local algorithm="SHA256"

function _M.verifyPayV3Sign(publicKey,ctx,headers)

    local nonce=headers["Wechatpay-Nonce"]
    local timestamp=headers["Wechatpay-Timestamp"]
    local serial=headers["Wechatpay-Serial"]
    local signature=headers["Wechatpay-Signature"]

    if  (not nonce) or  (not timestamp) or (not serial) or (not signature) then 
        return nil,"header field lost"
    end

    local fullCtx=timestamp.."\n"..nonce.."\n"..ctx.."\n"

    ngx.log(ngx.INFO,"\n",fullCtx)
    
    return  _M.verifySignWithSHARSA(publicKey,fullCtx,signature)

end

function _M.decryptAesGCM(resource,pk)
    
    local nonce=resource["nonce"]
    local assoc_data=resource["associated_data"]
    local ciphertext=resource["ciphertext"]

    local aes256,err = aes.new(pk, "gcm", nonce, assocdata,16)
    if err then
        ngx.log(ngx.ERR,err)
        return nil,err
    end

    local plaintext, digest = aes256:decrypt(ngx.decode_base64(ciphertext))

    return  string.gsub(plaintext,"[^}]*$","")

end

function _M.verifySignWithSHARSA(publicKey,ctx,sign)

    local pub, err = resty_rsa:new({ public_key = publicKey,key_type = resty_rsa.KEY_TYPE.PKCS1, algorithm = algorithm })
    if not pub then
        ngx.log(ngx.ERR,err)
        return nil,err
    end
    local signValue=ngx.decode_base64(sign)
    return  pub:verify(ctx,signValue)
end


function _M.signWithSHARSA(privateKey,ctx)
    
    local priv, err = resty_rsa:new({ private_key = privateKey,key_type = resty_rsa.KEY_TYPE.PKCS8, algorithm = algorithm })
    if not priv then
        ngx.log(ngx.ERR,"gener private key fail",err)
        return nil,err
    end

    local sig, err = priv:sign(ctx)
    if not sig then
        ngx.log(ngx.ERR,"gener sign fail",err)
        return nil,err
    end

    return ngx.encode_base64(sig)

end



function _M.decryptForMsg(context,cipherKey)
    if not cipherKey then 
        error("null cipher key")
    end

    if not context then 
        error("null text body")
    end

    local aesKey=ngx.decode_base64(cipherKey.."=")

    local decodeCtx=ngx.decode_base64(context)

    local iv = string.sub(aesKey,1,16)

    local aes_cbc,err = resty_aes:new(aesKey,nil,resty_aes.cipher(256,"cbc"),{iv=iv})

    if not aes_cbc then 
        return nil,err
    end

    local result,err=  aes_cbc:decrypt(decodeCtx)

    return result,err
end


function _M.sha256_hash(key)

    local sha256 = resty_sha256:new()
    sha256:update(key)
    local digest = sha256:final()

    return resty_str.to_hex(digest)
end 

function  _M.md5_hash(key)

    local md5=resty_md5:new()
    md5:update(key)
    local hash= md5:final()

    local hash_key= resty_str.to_hex(hash)

    return hash_key
end 

function _M.decryptForRefund(context,cipherKey)
    if not cipherKey then 
        error("null cipher key")
    end

    if not context then 
        error("null text body")
    end

    local decodeCtx=ngx.decode_base64(context)

    local iv=ngx.decode_base64("AAAAAAAAAAAAAAAAAAAAAA==")

    local h={
        method=_M.md5_hash,
        iv=iv,
    }

    local aes_ecb,err = resty_aes:new(cipherKey,nil,resty_aes.cipher(256,"ecb"),h,1)

    if not aes_ecb then 
        return nil,err
    end

    local result,err=  aes_ecb:decrypt(decodeCtx)

    return result,err
end

function _M.random_str(len)

    local strong_random = resty_random.bytes(len,true)
    while strong_random == nil do
        strong_random = resty_random.bytes(len,true)
    end

    return resty_str.to_hex(strong_random)
end


return _M


