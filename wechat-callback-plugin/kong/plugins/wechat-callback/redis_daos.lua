local redis_tool = require "utils.commons.redis_tool"
local cjson = require "cjson"
local utils = require "utils.commons.version_tool"
local ngx = ngx



local _M = {}



local function queryRedirectUrlByMsgID(config, accessID)

    local red=redis_tool.connect(config)

    local res=red:hget("consumer_rel:relationinfo:hash",accessID)

    red:close()

    if res == ngx.null then 
        return nil
    end
    
    local json= cjson.decode(res)

    return json
end

local function queryAccessIDByMsgID(config, msgID,appID,type)

    local red=redis_tool.connect(config)

    local key="msgreply:"..appID..":replytype:"..type..":msgid:"..msgID
    ngx.log(ngx.INFO,"key",key)
    local accessID=red:getValue(key)

     red:close()

     if accessID==ngx.null then
        return nil
     end

    return accessID
end


function _M.pushDataToList(config,body)

    local red=redis_tool.connect(config)

    local res = red:lpush("wechat:callback:list", body)
  
    red:close()

    return res
end



function _M.getRedirectByMsgID(config,appID,msgID,type)

    local accessID=queryAccessIDByMsgID(config,msgID,appID,type)

    if not accessID then 
        return nil
    end

    return _M.getCallbackInfoByAccessID(config,accessID)

end

function _M.getCallbackInfoByAccessID(config,accessID)

    return utils.cache_access_callback(accessID,config.appinfottl,queryRedirectUrlByMsgID,config,accessID)


end


return _M
