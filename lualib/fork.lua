local Skynet = require 'skynet'
local t = Skynet.time

local M = {}

local function _fork_func(list, func, max_fork)
    local t1 = t()
    local total = #list
    local count = total
    
    for _, i in ipairs(list) do
        Skynet.fork(function()
            func(i)
            count = count - 1
        end)
    end
    
    while true do
        Skynet.sleep(10)
        if count <= 0 then
            break
        end
    end
    
    LOG_INFO("sub fork load count:<%d> time:<%.2f>", total, t()-t1)
end

function M.multi_fork(list, func, max_fork)
    local t1 = t()
    local total = #list
    local count = math.floor(total/max_fork)
    local last = total - count*max_fork
    local loop_num = count
    
    if last > 0 then
        loop_num = count + 1
    end
    
    for i=1, loop_num do
        local s = (i-1)*max_fork
        local e = s + max_fork
        
        if i == loop_num then
            e = total
        end
        
        local temp = {table.unpack(list, s+1, e)}
        _fork_func(temp, func, max_fork)
    end
    
    LOG_INFO("multi fork count:<%d> time:<%.2f>", total, t()-t1)
end

return M

