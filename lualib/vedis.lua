local lvedis = require 'lvedis'

local vedis = {}

vedis.db = nil

function vedis.open(file)
    vedis.db = lvedis.open(file or 'test.vedis')
end

function vedis.close()
    lvedis.close()
end

function vedis.set(key, value)
    lvedis.begin(vedis.db)
	lvedis.store(vedis.db, key, value)
    lvedis.commit(vedis.db)
end

function vedis.get(key)
    return lvedis.fetch(vedis.db, key)
end

function vedis.hmset(key, row)
    local cmd = "HMSET "..key.." "
    for k, v in pairs(row) do
        cmd = cmd.." "..k.." "..v
    end
    lvedis.begin(vedis.db)
    lvedis.exec(vedis.db, cmd)
    lvedis.commit(vedis.db)
end

function vedis.hgetall(key)
    local t = lvedis.exec_result_array(vedis.db, "HGETALL "..key)

    local data = {}
    for i=1, #t, 2 do
        data[t[i]] = t[i+1]
    end

    return data
end

function vedis.halls(key)
    return lvedis.exec_result_array(vedis.db, "HVALS "..key)
end

return vedis
