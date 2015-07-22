
local function work(ms)
    local handle_lst = {}
    table.insert(handle_lst, ms.stage_drop)

    local rlt = {}

    for _, v in ipairs(handle_lst) do
        for k1, v1 in pairs(v) do
            rlt[k1] = v1
        end
    end

    return rlt
end

return work
