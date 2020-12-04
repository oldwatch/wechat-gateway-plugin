local sign_tool = require "utils.commons.sign_tool"
local utils = require "utils.commons.version_tool"
local ngx = ngx
local xml2lua = require "xml2lua"
local handler = require "xmlhandler.tree"
local concat = table.concat
local _M = {}

local root_str="xml"
local app_str="appid"

local function verifySign(signtype,body)

    local parser  = xml2lua.parser(handler)

    parser:parse(body)

    local fields = handler.root[root_str]

    local secretPayKey= ngx.ctx.secretPayKey

    local sign,err=sign_tool.new(secretPayKey,signtype)
    
    if err then
       error(err)
    end
    return sign:verifySign(fields)

end

function _M.check_context(signtype)

    local ctx = ngx.ctx
    local chunk, eof = ngx.arg[1], ngx.arg[2]

    ctx.rt_body_chunks = ctx.rt_body_chunks or {}
    ctx.rt_body_chunk_number = ctx.rt_body_chunk_number or 1

    if eof then
      local chunks = concat(ctx.rt_body_chunks)

      local sign = verifySign(signtype, chunks)

      if  not sign then
           ngx.arg[1] = nil
      end
  
    else
      ctx.rt_body_chunks[ctx.rt_body_chunk_number] = chunk
      ctx.rt_body_chunk_number = ctx.rt_body_chunk_number + 1

    end
end


return _M