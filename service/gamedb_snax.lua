local skynet = require "skynet"
local snax = require "snax"
local redis = require "redis"
local unqlite = require "unqlite"

local db
local unqlitedb

function init(...)
    db = assert(redis.connect{
        host = skynet.getenv('redis_host') or '127.0.0.1',
        port = skynet.getenv('redis_port') or 6379,
        db = 0,
        auth = skynet.getenv('redis_auth') or '123456',
    },'redis connect error')

    unqlitedb = unqlite.open(skynet.getenv("cold_backup"))
end

function exit(...)
    unqlite.close(unqlitedb)
end

function response.set(key,value)
    local result = db:set(key, value)
    if result ~= 'OK' then
        return false
    end

    if unqlitedb == nil then
        unqlitedb = unqlite.open(skynet.getenv("cold_backup"))
    end

    unqlite.begin(unqlitedb)
	unqlite.store(unqlitedb, key, value)
    unqlite.commit(unqlitedb)
    return true
end

function response.get(key)
    local result = db:get(key)
    --[[
    if result == nil then
        result = unqlite.fetch(unqlitedb, key)
    end
    --]]
    return result
end
