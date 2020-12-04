local resty_md5 = require "resty.md5"
local openssl_hmac = require "resty.openssl.hmac"
local resty_str = require "resty.string"
local encrypt_tool=require "utils.commons.encrypt_tool"


local function factory(sign_type,sign_key)
    
    if sign_type=="HMAC-SHA256" then
      return  openssl_hmac.new(sign_key,"sha256")
    elseif sign_type=="MD5" then 
       return resty_md5:new()
    else 
        return nil,"sign type "..sign_type.." not support"
    end    
end


local nonce_str="nonce_str"
local sign_str="sign"
local sign_type_str="sign_type"
local key_str="key"


local _M={}

local mt = { __index = _M }


function _M.new(sign_key,sign_type)

    if not sign_key then
        error(" sign key is null")
    end

    
    if not sign_type then
        error(" sign type is null")
    end

    local hash,err= factory(sign_type,sign_key)

    if err then 
        return nil,err
    end

    return  setmetatable({hash=hash,sign_key=sign_key,sign_type=sign_type},mt)
end


local function computeSign(sortKey,fields,this)

    local hash = this.hash

    local sign_key=this.sign_key

    table.sort(sortKey)

    for i,n in pairs(sortKey) do
        local val=fields[n]
        if val==nil or  type(val) == "table"  then 
            goto continue 
        end    
        local str=n.."="..val.."&"
        local ok = hash:update(str)
        if not ok then
            return nil,"failed to add data"
        end
        ::continue::
    end

    local ok = hash:update(key_str.."="..sign_key)
    if not ok then
        return nil,"failed to add data"
    end

    local digest,err=hash:final()

    return string.upper(resty_str.to_hex(digest))

end



function _M.addSign(self,fields)

    local sortKey = {}

    local nonce_field_sign=false
    for k,v in pairs(fields) do
        if k==sign_str or k==sign_type_str then 
            goto continue
        end
        if k==nonce_str then 
            nonce_field_sign=true
        end
        table.insert(sortKey,k)
        ::continue::
    end

    if not nonce_field_sign then
        table.insert(sortKey,nonce_str)
        fields[nonce_str]=encrypt_tool.random_str(16)
    end


    local signValue=computeSign(sortKey,fields,self)

    fields[sign_str]=signValue

    fields[sign_type_str]=self.sign_type

    return fields

end

function _M.verifySign(self,fields)

    local sortKey = {}

    for k,v in pairs(fields) do
        if k==sign_str or k==sign_type_str then 
            goto continue
        end
        table.insert(sortKey,k)
        ::continue::
    end

    local input_sign_value=fields[sign_str]

    local signValue=computeSign(sortKey,fields,self)

    return signValue == input_sign_value   

end


local fixed_field_metatable = {
    __index =
        function(t, k) -- luacheck: ignore 212
            error("field " .. tostring(k) .. " does not exist", 3)
        end,
    __newindex =
        function(t, k, v) -- luacheck: ignore 212
            error("attempt to create new field " .. tostring(k), 3)
        end,
}


return setmetatable(_M,fixed_field_metatable)
