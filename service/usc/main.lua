local Skynet = require "skynet"
local Env = require "global"
local Cmd = require "command"
local BaseMgr = require 'usc.base_mgr'
local NodeMonitorClient = require 'client.node_monitor'

--usc服务对base信息只读,而且比玩家自己身上的base有延迟
Skynet.start(function()
    Skynet.dispatch("lua", function(session, from, cmd, ...)
        local f = assert(Cmd[cmd], cmd)
        f(...)
    end)

    Env.base_mgr = BaseMgr.new{
        max_cnt = Env.cache_max_cnt,
        ttl = Env.cache_ttl,
        save_cd = Env.cache_save_cd,
    }

    Env.base_mgr:start()
    
    Skynet.register('.usc')
    LOG_INFO('usc booted') 
    NodeMonitorClient.register("usc", Cmd.on_exit)  
end)

