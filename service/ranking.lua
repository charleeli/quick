local skynet = require "skynet"
local redis = require "redis"
local config = require "config"

local db

local CMD = {}

function CMD.zadd(key, score, member)
	local result = db:zadd(key, score, member)

	return result
end

function CMD.zrange(key, from, to)
	local result = db:zrange(key, from, to)

	return result
end

function CMD.zrevrange(key, from, to ,scores)
	local result

	if not scores then
		result = db:zrevrange(key,from,to)
	else
		result = db:zrevrange(key,from,to,scores)
	end
	
	return result
end

function CMD.zrank(key, member)
	local result = db:zrank(key,member)

	return result
end

function CMD.zrevrank(key, member)
	local result = db:zrevrank(key,member)

	return result
end

function CMD.zscore(key, score)
	local result = db:zscore(key,score)

	return result
end

function CMD.zcount(key, from, to)
	local result = db:zcount(key,from,to)

	return result
end

function CMD.zcard(key)
	local result = db:zcard(key)

	return result
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = assert(CMD[cmd], cmd .. "not found")
		skynet.retpack(f(...))
	end)
	
	local ranking_file = skynet.getenv('ranking')
    local cfg = config(ranking_file)
    local ranking_cfg = cfg['redis']
  
    db = assert(redis.connect{
		host = ranking_cfg.host,
		port = ranking_cfg.port,
		db = 0,
		auth = ranking_cfg.auth,
	},'ranking redis connect error')

	skynet.register('.ranking')
	LOG_INFO('ranking booted')
end)
