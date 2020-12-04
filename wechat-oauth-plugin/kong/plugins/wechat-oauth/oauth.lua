local redis_dao = require "kong.plugins.wechat-oauth.redis_daos"
local http_tool = require "utils.commons.http_tool"
local cjson = require "cjson"

local ngx = ngx

local _M = {}

local token_name="exchange_token"
local state_name="state"
local redirect_name="redirect"

function _M.addHeader(conf)

    local redirect=ngx.ctx[redirect_name]
    if not redirect then 
        return 
    end

    ngx.header["Location"]=redirect

end

local PATTERN="/app/([^/]+)"


function _M.access(conf)

    local url=ngx.var.uri

    local _,_,consumerID=string.find(url,PATTERN)
  
    ngx.log(ngx.INFO,url,consumerID)

    local appInfo=redis_dao.getAppInfoByAccessID(conf,consumerID)

    if not appInfo  then 
        ngx.say(err)
        ngx.exit(403)
    end


    local args=ngx.req.get_uri_args()
    local code=args["code"]
    local state=args["state"]

    if (not code) or (not state)  then 
        ngx.say(err)
        ngx.exit(400)
    end

    local url=conf.wechat_token_host.."/sns/oauth2/access_token"

    
    local http=http_tool.new()

    local query={}
    query["appid"]=appInfo.appID
    query["secret"]=appInfo.appSecret
    query["code"]=code
    query["grant_type"]="authorization_code"

    local params={}
    params.query=query

    local resp = http:simple_get(url,params)

    local tokens=cjson.decode(resp)

    if  tokens["errcode"]  and  tokens["errcode"]~=0 then 
        ngx.say(err)
        ngx.exit(500)
    end
    
    local exchange_token=redis_dao.saveTokenInfo(conf,appInfo.appID,consumerID,tokens)

    local redirect_url=appInfo[redirect_name].."?exchange_token="..exchange_token.."&state="..state

    ngx.ctx[redirect_name]=redirect_url
    ngx.exit(307)


end


return _M
