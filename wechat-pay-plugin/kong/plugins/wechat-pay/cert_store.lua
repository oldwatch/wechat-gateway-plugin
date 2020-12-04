local azure_access=require "kong.plugins.wechat-pay.azure_access"
local openssl = require 'openssl'
local pkcs12 = require 'openssl.pkcs12'
local x509 = require'openssl.x509'
local pkey = require'openssl.pkey'
local utils = require "utils.commons.version_tool"
local ngx=ngx

_M={}



local function getClientCertAzure(appInfo,conf)

    local secret=azure_access.getCertSecretByAppID(appInfo,conf.azure_token_host)

    if not secret then 
        return nil,"can not get secert from azure"
    end

    local len=string.len(secret)
    ngx.log(ngx.INFO," get secret "..string.sub(secret,1,10)..":"..string.sub(secret,len-10,len))

    local bin_secret=ngx.decode_base64(secret)

    local pk_inst,cert_inst,ca_inst=pkcs12.parse(bin_secret,"")
    ngx.log(ngx.INFO,"finish parse")

    if not pk_inst then
        ngx.log(ngx.ERR,"parse cert fail")
        error("parse fail ")
    end
    -- true,appInfo.mchID
    local pk_pem=pk_inst:toPEM("PrivateKey")

    local cert_pem=tostring(cert_inst)

    ngx.log(ngx.INFO,pk_pem)
    ngx.log(ngx.INFO,cert_pem)
    return {
        cert=cert_pem,
        key=pk_pem,
    }
end 


function _M.getClientCert(appInfo,conf)

    return   utils.tool.cache:get("wechatpay_cert" .. appInfo.appID,
    nil,
    getClientCertAzure, appInfo, conf)

end

local cert=[[
-----BEGIN CERTIFICATE-----
MIIFOjCCAyICFGPIHxPMDF8q+Ep29/I5iwmaOJb2MA0GCSqGSIb3DQEBCwUAMF0x
CzAJBgNVBAYTAlVTMQ0wCwYDVQQIDARPaGlvMQ0wCwYDVQQHDARPaGlvMRMwEQYD
VQQKDAp3c3R1dG9yaWFsMQswCQYDVQQLDAJJVDEOMAwGA1UEAwwFamlhbmcwHhcN
MjAwNzA4MDcwNzEwWhcNMjEwNzAzMDcwNzEwWjBWMQswCQYDVQQGEwJVUzENMAsG
A1UECAwET2hpbzENMAsGA1UEBwwET2hpbzEMMAoGA1UECgwDbGJzMQswCQYDVQQL
DAJJVDEOMAwGA1UEAwwFamlhbmcwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIK
AoICAQDMFGjqbJ1bjUIUzx8quT+J8EzWk6mnp+0Zi7cMX0yQwSj0SWUBHj9vpUIa
pWuUNhJnMlEBYhd2ZFjNTz3mdkN39n9WqjphtKtI0BiKFFjOzbqf2xCnqkUBdjS1
U65BSW6rvBCClYcHPliAUrQCHo2KRNAfYcU5jrRzELZrBOLixyC+1Z9flA72DfiO
Mx0J2aXwas/kJ7z1VcfyxQ9ls0ENs1/sziUy3A1JgYM2RdYMrUVccSWDHnj2xYr7
CcLrwa8YVFWjjuAWtMyd/Mgs3V4ZpCBm8Zi9wZGxkSllz0JzH2kt24IbuK/Pn8gV
3LJ68yCz2/efweiXdcISydxFwqgsSO1yh+kORoScgVkp2Z2XQ/off46ryD7cH2mb
FutMO5v7gERQuvQ2R9fQpNO6F5Zn27i5s9MK8IAIjyWXloV7ANZCok5KFVR4irCq
w8YtxfTHMcVjKpmb4TqYPRI0SVL0uGWCvWfJTO3gyZUUPlF/ZD7j5+HaYBhu3kNP
IUNWEeSt4vLbxnGndNG/cIV7/oEEdLW5DpRA01TqGpf4GPYW6arsvqHQUi33BNCJ
yC1Eecc0k3bDl5q+RT9Alcme0o/12FaabkN+FaWyCutvxi6RW1v5fe/eENh3ycO9
MCZOL6ys48AFu/dXFMUDLLdl+4LBzPcrH13SiIItkKUrZtjbKQIDAQABMA0GCSqG
SIb3DQEBCwUAA4ICAQDOqSr/IFxxc9n/OBaXTsVc9ImJf5+CP7r03vxxXpPmcvWo
pSObRhmLQzty737BYE64dk9Mv0P6dfLd43VmPYrSx4Kt4H/b8Ajk3FXKzxJnse2t
AqFTP6qlrxGL3VZmvYQ0uMZs1QTQQouoryj/61IST1fEzl3BLT2SrZDi8bhe93eu
tBhHHIhlhvH5FSaClMjaWUDLC6zJn1Cdmnitr/C6wbfiH0dw9xFogPLIBZsKZmBV
BPs2VeGyROB5y9/OrcIvN7voOhDppKHegXxst0sxJFxZI5FPIFaH9o7Z0r080ApP
AMd0lu55vb818syo0MYMZfH7rbRv/IlKYUuTH7CV55l5V7WvnjNV1yaa9f+ZnkMX
R4hAlWS70yjUe8XEKYjcHPBV7HQjOZ7osDgTMuZcnK9ROifp3NKCZDPyLUCP88P/
GVeOf79Yk8RG7cnvZKuizh3tI4NME81VJwavR5+gpBxKfw7Qqp7B0MpQ43AGCyVS
O0J3hHbmSyHQcuDODSlSSlDllgBJn+DUuGg9kP0lLi3+3kxG12KpI/VDlvcF5L6f
69O4F+W2btkYzX1kOUG53wW6zgx/gLVU9caxWivOnxrbwWhtAYB/hWlQHx/Dgfql
pLFTpkczzc3a8f9Ts/zn7osLY5yb3Vt3X5p5z19PaV8RR858FXoty+Fd+Flsyg==
-----END CERTIFICATE-----
]]

local key=[[
-----BEGIN RSA PRIVATE KEY-----
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
-----END RSA PRIVATE KEY-----
]]

return _M