local skynet = require "skynet"
local snax = require "snax"
local cluster = require "cluster"

skynet.start(function()
	local log = skynet.uniqueservice("log")
	skynet.call(log, "lua", "start")
	
	snax.uniqueservice("accountdb_snax") -- 账号服务

	skynet.uniqueservice("logind")		-- 启动登录服务器
	cluster.open("login")
end)
