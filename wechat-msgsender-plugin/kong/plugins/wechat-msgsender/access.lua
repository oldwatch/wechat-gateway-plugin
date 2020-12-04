local red = require "kong.plugins.wechat-msgsender.redis_daos"
local utils = require "utils.commons.version_tool"
local http_tool = require "utils.commons.http_tool"
local cjson = require "cjson"

local ngx = ngx

local root_str="xml"

local _M = {}

local function replace(conf,data,appInfo,res)

    if not conf.modifybody then 
        return data
    end

    local body = data:gsub("${APPID}", appInfo.appID)

    local ticket= res["ticket"]
    if ticket then
        body = body:gsub("${TICKET}", ticket)
    end
 
    return body
end

function _M.callApi(conf,accessID)

    ngx.req.read_body()
    local body = ngx.req.get_body_data()
    if not body then
        return  "",true
    end

    local res,err= red.getToken(conf, accessID)
    if err then 
        return "",true
    end

    local appInfo,err= red.getAppInfoByAccessID(conf, accessID)
    if err then 
        return "",true
    end

    local wechatNo=appInfo["wechatNo"]

    local newBody=replace(conf,body,appInfo,res)

    local http=http_tool.new()


    local fullurl=utils.getUpstreamUrl()

    local token=res["token"]
    
    local response,err=http:api_post(fullurl,token,newBody)
    if err or response.status>=300 then 
        return nil,true
    end

    local resp=cjson.decode(response.body)

    local msgID=tostring(resp["msgid"])
    local res,err=red.setMsgIndex(conf,wechatNo, msgID,accessID)

    if err then 
        return nil,true
    end

    ngx.ctx.upstream_headers=response.headers 

    return response.body
end



return _M
