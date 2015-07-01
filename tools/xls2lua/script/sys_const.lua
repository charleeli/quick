local function work(ms)
    local const = ms.sys_const
    local ret = {}
    for k, v in pairs(const) do
        if v.type == 'string' then
            ret[v.name] = v.value

        elseif v.type == 'int' then
            local value = math.floor(tonumber(v.value))
            if value ~= tonumber(v.value) then
                error(string.format("illegal int, <%s=%s>", v.name, v.value))
            end
            ret[v.name] = value

        elseif v.type == 'float' then
            local value = tonumber(v.value)
            if not value then
                error(string.format("illegal float, <%s=%s>", v.name, v.value))
            end
            ret[v.name] = value
        end
    end

    return ret
end

return work
