local function split(str, sep)
    local s, e = str:find(sep)
    if s then
        return str:sub(0, s - 1), str:sub(e + 1)
    end
    return str
end

local function main(ms)
    local ret = {}

    for _, item in pairs(ms['full_duty_award']) do
        table.insert(ret,item.award)
    end

    return ret
end

return main
