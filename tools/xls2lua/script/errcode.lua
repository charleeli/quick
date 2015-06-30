
local function work(ms)
    local errcode = ms.errcode
    local rlt = {}
    for k, v in pairs(errcode) do
        rlt[v.name] = v.id
    end
    return rlt
end

return work
