local redis_dao = require "kong.plugins.wechat-oauth.redis_daos"
local cjson = require "cjson"
local utils = require "utils.commons.version_tool"
local http_tool = require "utils.commons.http_tool"
local ngx = ngx

local _M = {}

local token_name="exchange_token"
local state_name="state"
local redirect_name="redirect"

local err_msg=
[[
{"errcode":40001,"errmsg":"invalid token"}
]]

local function token_invalid()
    utils.success_response(err_msg)
end

function _M.access(conf,accessID)

    local args,err=ngx.req.get_uri_args()

    if  err == "truncated" then 
        utils.forbidden_response("not found param")
        return
    end

    local exchange_token=args["exchange_token"]
    if  exchange_token then 
        local tokens=redis_dao.getTokenInfoByExchangeToken(conf,accessID,exchange_token)

        if not tokens then 
            token_invalid()
            return 
        end 

        local params=ngx.req.get_uri_args()

        params["access_token"]=tokens["access_token"]
        params["openid"]=tokens["openid"]

        ngx.req.set_uri_args(params)

        return 
    end
    
    local openid=args["openid"]
    if openid then 

        local appInfo=redis_dao.getAppInfoByAccessID(conf,accessID)

        local appID=appInfo.appID
        local token=redis_dao.getAccessTokenByAppID(conf,appID,openid)

        local params=ngx.req.get_uri_args()

        if token then 
            params["access_token"]=token
            ngx.req.set_uri_args(params)
            return 
        end 

        local url="/tpservice/webtoken/wechat/refresh/app/"..appID.."/openid/"..openid

        local http=http_tool.new()    

        local resp ,status = http:simple_post(conf.refresh_token_url..url,"")

        if status == 200 then 
         
            params["access_token"]=resp
            ngx.req.set_uri_args(params)
    
            return 
        end

        ngx.log(ngx.ERR,resp)

        token_invalid()
        return
    end

    token_invalid()
    return

end


return _M
