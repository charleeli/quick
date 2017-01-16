local lvedis = require 'lvedis'
local base64 = require 'base64'

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
	lvedis.store(vedis.db, base64.encode(key), base64.encode(value))
    lvedis.commit(vedis.db)
end

function vedis.get(key)
    return base64.decode(lvedis.fetch(vedis.db, base64.encode(key)))
end

function vedis.hmset(key, row)
    local cmd = "HMSET "..base64.encode(key).." "
    for k, v in pairs(row) do
        cmd = cmd.." "..base64.encode(k).." "..base64.encode(v).." "
    end
	print(cmd)
    lvedis.begin(vedis.db)
    lvedis.exec(vedis.db, cmd)
    lvedis.commit(vedis.db)
end

function vedis.hgetall(key)
	local cmd = "HGETALL "..base64.encode(key)
    local t = lvedis.exec_result_array(vedis.db, cmd)

    local data = {}
    for i=1, #t, 2 do
        data[base64.decode(t[i])] = base64.decode(t[i+1])
    end

    return data
end

function vedis.halls(key)
    local t = lvedis.exec_result_array(vedis.db, "HVALS "..base64.encode(key))
	
	local data = {}
    for i=1, #t do
        table.insert(data, base64.decode(t[i]))
    end

    return data
end

return vedis
