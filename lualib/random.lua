local M = {}

-- random.random(m,n)
do
    local randomtable
    local tablesize = 97

    function M.random(m, n)
        -- 初始化随机数与随机数表，生成97个[0,1)的随机数
        if not randomtable then
            -- 避免种子过小
            math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
            randomtable = {}
            for i = 1, tablesize do
                randomtable[i] = math.random()
            end
        end

        local x = math.random()
        local i = 1 + math.floor(tablesize*x)   -- i取值范围[1,97]
        x, randomtable[i] = randomtable[i], x   -- 取x为随机数，同时保证randomtable的动态性

        if not m then
            return x
        elseif not n then
            n = m
            m = 1
        end

        --if not Check(m <= n) then return end

        local offset = x*(n-m+1)
        return m + math.floor(offset)
    end
end

return M
