function enum(begin_idx)
    local enum_idx = (begin_idx or 0) - 1
    return function()
        enum_idx = enum_idx + 1
        return enum_idx
    end
end

function config(path, pre)
    assert(path)
    local env = pre or {}
    local f = assert(loadfile(path,"t",env))
    f()
    return env
end

string.split = function(s, delim)
    local split = {}
    local pattern = "[^" .. delim .. "]+"
    string.gsub(s, pattern, function(v) table.insert(split, v) end)
    return split
end

-- 判断table是否为空
table.empty = function(t)
    return not next(t)
end

table.print = function(T, CR)
    assert(type(T) == "table",'arg should be a table!')

    CR = CR or '\r\n'
    local cache = {  [T] = "." }
    local function _dump(t,space,name)
        local temp = {}
        for k,v in next,t do
            local key = tostring(k)
            if cache[v] then
                table.insert(temp,"+" .. key .. " {" .. cache[v].."}")
            elseif type(v) == "table" then
                local new_key = name .. "." .. key
                cache[v] = new_key
                table.insert(temp,
                    "+" .. key .. _dump(
                    v,
                    space .. (next(t,k) and "|" or " " ).. string.rep(" ",#key),
                    new_key
                ))
            else
                table.insert(temp,"+" .. key .. " [" .. tostring(v).."]")
            end
        end
        return table.concat(temp,CR..space)
    end
    print(_dump(T, "",""))
end
