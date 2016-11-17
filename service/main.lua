local skynet = require "skynet"
local snax = require "snax"
local cluster = require "cluster"
local ServiceStateClient = require "client.service_state"

skynet.start(function()
    local log = skynet.uniqueservice("log")
    skynet.call(log, "lua", "start")
    skynet.uniqueservice("sproto_loader")
    skynet.uniqueservice("crab_loader")
    
    skynet.newservice("debug_console", tonumber(skynet.getenv("debug_port")))
    skynet.newservice("service_state")
    skynet.monitor('node_monitor')
    skynet.newservice('chat_listener')
    skynet.newservice('rpc_proxy')
    skynet.newservice("res_mgr")
    snax.uniqueservice("gamedb_snax")
    snax.uniqueservice("accountdb_snax")

    if NODE_NAME == require("quick").center_node_name() then
        skynet.uniqueservice(true, 'cluster_monitor')
        skynet.uniqueservice(true, 'web_master')
        skynet.uniqueservice(true, 'chat_speaker')
        skynet.uniqueservice(true, 'online')
        skynet.uniqueservice(true, 'mailbox')
    end
    
    local gate = skynet.uniqueservice("gated")
    skynet.call(gate, "lua", "init")
    skynet.call(gate, "lua", "open" , {
        port = tonumber(skynet.getenv("port")) or 8888,
        maxclient = tonumber(skynet.getenv("maxclient")) or 1024,
        servername = NODE_NAME,
    })
    
    ServiceStateClient.add_service_state("gated")

    cluster.open(NODE_NAME)
end)
