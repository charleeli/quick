local skynet = require "skynet"
local snax = require "snax"
local redis = require "redis"
local config = require "config"

local db

function init(...)
    local ranking_file = skynet.getenv('accountdc')
    local cfg = config(ranking_file)
    local ranking_cfg = cfg['redis']

    db = assert(redis.connect{
	    host = ranking_cfg.host,
	    port = ranking_cfg.port,
	    db = 0,
	    auth = ranking_cfg.auth,
    },'ranking redis connect error')
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

	return result
end

