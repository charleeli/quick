local skynet = require "skynet"
local snax = require "snax"
local redis = require "redis"
local unqlite = require "unqlite"

local unqlitedb

local redis_pool = {}
local redis_maxinst

local function read_gamedb_conf()
    local gamedb_cfg = skynet.getenv('gamedb')
    if not gamedb_cfg then
        error("no gamedb cfg!")
    end

    local env = {}
    local f = assert(loadfile(gamedb_cfg,"t",env))
    f()
    return env
end

local function getconn(uid)
    return redis_pool['redis'..tostring(math.floor(uid % redis_maxinst))]
end

function init(...)
    unqlitedb = unqlite.open(skynet.getenv("cold_backup"))


    local gamedb_conf = read_gamedb_conf()

    redis_maxinst = tonumber(skynet.getenv("redis_maxinst")) or 1
	for i = 0, redis_maxinst - 1 do
		local db = assert(redis.connect{
			host = gamedb_conf["redis"..i.."_host"],
			port = gamedb_conf["redis"..i.."_port"],
			db = 0,
			auth = gamedb_conf["redis"..i.."_auth"],
		},'redis'..i..' connect error')

		if db then
			redis_pool['redis'..i] = db
		else
			skynet.error("redis"..i.." connect error")
		end
    end
end

function exit(...)
    unqlite.close(unqlitedb)
end

function response.set(uid,value)
    local db = getconn(uid)
    local result = db:set(uid, value)
    if result ~= 'OK' then
        return false
    end

    if unqlitedb == nil then
        unqlitedb = unqlite.open(skynet.getenv("cold_backup"))
    end

    unqlite.begin(unqlitedb)
	unqlite.store(unqlitedb, uid, value)
    unqlite.commit(unqlitedb)
    return true
end

function response.get(uid)
    print(uid)
    local db = getconn(uid)
    local result = db:get(uid)
    --[[
    if result == nil then
        result = unqlite.fetch(unqlitedb, key)
    end
    --]]
    return result
end
