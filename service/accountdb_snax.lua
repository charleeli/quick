local skynet = require "skynet"
local snax = require "snax"
local redis = require "redis"
local config = require "config"

local db

function make_pairs_table(t, fields)
    assert(type(t) == "table", "make_pairs_table t is not table")

    local data = {}

    if not fields then
        for i=1, #t, 2 do
            data[t[i]] = t[i+1]
        end
    else
        for i=1, #t do
            data[fields[i]] = t[i]
        end
    end

    return data
end

function init(...)
    local accountdb_file = skynet.getenv('accountdb')
    local cfg = config(accountdb_file)
    local accountdb_cfg = cfg['accountdb']

    db = assert(redis.connect{
        host = accountdb_cfg.host,
        port = accountdb_cfg.port,
        db = 0,
        auth = accountdb_cfg.auth,
    },'accountdb redis connect error')
end

function exit(...)

end

function response.get_nextid()
    return db:incr('nextid')
end

function response.add(row)
    local data = {}
    for k, v in pairs(row) do
        table.insert(data, k)
        table.insert(data, v)
    end

    local key = row.sdkid..':'..row.pid
    local result = db:hmset(key, table.unpack(data))
    if result ~= 'OK' then
        return false
    end

    return true
end

function response.get(sdkid, pid)
    local key = sdkid..':'..pid
 
    local result = db:hgetall(key)
    result = make_pairs_table(result)

    return result
end

