local encrypt_tool = require "utils.commons.encrypt_tool" 
local utils = require "utils.commons.version_tool"
local redis_dao = require "kong.plugins.wechat-payv3.redis_dao" 

local ngx = ngx
local kong = kong

local _M = {}

function _M.verifySign(ctx,conf)

    local mchID= ngx.ctx.mchID

    local headers, err = ngx.resp.get_headers()

    if err == "truncated" then
        return false,"not found headers"
    end

    local serial=headers["Wechatpay-Serial"]

    local pks=ngx.ctx.publicKeys

    local pk=pks[serial]
    if not pk then 
      return nil,"not found public key "..serial
    end

    return  encrypt_tool.verifyPayV3Sign(pk,ctx,headers)


end


function _M.check_context(conf)

    local ctx = ngx.ctx
    local chunk, eof = ngx.arg[1], ngx.arg[2]

    ctx.rt_body_chunks = ctx.rt_body_chunks or {}
    ctx.rt_body_chunk_number = ctx.rt_body_chunk_number or 1

    if eof then

      local chunks = table.concat(ctx.rt_body_chunks)

      local sign,err = _M.verifySign(chunks,conf)

      if not sign  or  err then
           ngx.log(ngx.ERR,"response fail",tostring(sign),tostring(err))
           ngx.exit(500)
          --  error("verify sign fail")
      end
      
    else
      ctx.rt_body_chunks[ctx.rt_body_chunk_number] = chunk
      ctx.rt_body_chunk_number = ctx.rt_body_chunk_number + 1

    end
end

return _M
