
local _M={}

function _M.generConds(routes)

    local conds={}

    for _,v in ipairs(routes) do
        local service=v.upstream_name
        for i,vv in pairs(v.condition) do
            local cond={}
            cond.service=service
            
            local _,_,ex = string.find(vv,"#(%b())")
            if ex then 
                cond.fun="regex"
                cond.value=ex
            else
                cond.fun="equ"
                cond.value=vv   
            end
            cond.name=i
            table.insert(conds,cond)
        end
    end 
    return conds
end

function _M.regex(exp,val)

    return string.find(val,exp)
end

function _M.equ(vv,val)
    return vv==tostring(val)
end


function _M.match(input,conds)


    for _,cond in ipairs(conds) do


        local val=input[cond.name]

        if val then

            local success,sign=pcall(_M[cond.fun],cond.value,val)

            if success and sign  then 
                return cond.service
            end
        end 

    end 
    
    return nil
end

return _M