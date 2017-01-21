local skynet = require "skynet"
local snax = require "snax"
local cluster = require "cluster"

skynet.start(function()
	local log = skynet.uniqueservice("log")
	skynet.call(log, "lua", "start")
	skynet.newservice("debug_console", tonumber(skynet.getenv("debug_port")))
	skynet.uniqueservice("sproto_loader")
	skynet.uniqueservice("crab_loader")
    skynet.newservice('chat_listener')
	skynet.newservice('ws_master')
	skynet.newservice('web_master')
	skynet.newservice("res_mgr")
	skynet.monitor('node_monitor')

	snax.uniqueservice("accountdb_snax")
    snax.uniqueservice("gamedb_snax")
	snax.uniqueservice("maildb_snax")
	snax.uniqueservice("agent_snax")

	if NODE_NAME == require("quick").center_node_name() then
        skynet.uniqueservice(true, 'cluster_monitor')
		skynet.uniqueservice(true, 'admin')
        skynet.uniqueservice(true, 'chat_speaker')
        skynet.uniqueservice(true, 'mailbox')
		snax.uniqueservice("online_snax")
	end

	local gate = skynet.uniqueservice("gated")		-- 启动游戏服务器
	skynet.call(gate, "lua", "init")				-- 初始化，预先分配若干agent
	skynet.call(gate, "lua", "open" , {
		port = tonumber(skynet.getenv("port")) or 8888,
		maxclient = tonumber(skynet.getenv("maxclient")) or 1024,
		servername = NODE_NAME,
	})

	cluster.open(NODE_NAME)
end)

