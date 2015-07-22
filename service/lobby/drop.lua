local Res = require 'res'
local Const = require 'const'

local M = {}

function M.gen_sub_drop(id)
    local t = Res.SubDrop[id]
    assert(t, string.format('not exist sub drop id %d', id))

    local total = 0
    for k, v in ipairs(t.item_list) do
        total = total + v.val
    end
    local ran = math.random(1, total)
    local now_pro = 0

    --items
    for k, v in ipairs(t.item_list) do
        now_pro = now_pro + v.val
        if ran <= now_pro then
            return {id = v.id, amount = v.amount}
        end
    end

    return nil
end

function M.gen_drop(id)
    local t = Res.StageDrop[id]
    assert(t, string.format('not exist drop id %d', id))

    local total = 10000
    local ran

    local r = {}
    local p
    local sid
    for i, j in ipairs(t.drop_rules) do
        ran = math.random(1, total)
        p = j.val
        sid = j.id
        if ran <= p then
            local item = M.gen_sub_drop(sid)
            if item then
                table.insert(r, item)
            end
        end
    end

    return r
end

function M.assort_drop(drop)
    local assort_map = {
        items = {},
    }

    for _, v in ipairs(drop) do
        local id, amount = v.id, v.amount
        
        if not assort_map.items[id] then
            assort_map.items[id] = 0
        end
        
        assort_map.items[id] = assort_map.items[id] + amount
    end

    return assort_map
end

return M

