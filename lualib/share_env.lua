local share_env = {}

function share_env.init()
    local t = {}
    _keys = {}
    _t = {}
    local mt = {
        __index = function(t,k)
            return _t[k]
        end,
        __newindex = function(t,k,v)
            assert(type(k) ~= "number")
            if rawget(t,0) then
                if _keys[k] ~= 1 then
                    error(
                        string.format("key %s dont exist or cant modify", tostring(k)),
                    2)
                end

                rawset(t,k,v)
            else
                local c = string.byte(k)
                if c >= 65 and c <= 90 then
                    _keys[k] = 0
                    _t[k] = v
                else 
                    _keys[k] = 1
                    rawset(t,k,v)
                end
            end
        end,
    }
    setmetatable(t, mt)
    return t
end

function share_env.fini(t)
    rawset(t, 0, true) 
    return t
end

return share_env

