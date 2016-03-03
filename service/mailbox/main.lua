local Skynet = require "skynet"
local Env = require "env"
local Cmd = require "command"
local MailboxMgr = require 'mailbox.mailbox_mgr'
local NodeMonitorClient = require 'client.node_monitor'

Skynet.start(function()
    Skynet.dispatch("lua", function(session, from, cmd, ...)
        local f = assert(Cmd[cmd], cmd)
        f(...)
    end)

    Env.mailbox_mgr = MailboxMgr{
        max_cnt = Env.cache_max_cnt,
        ttl = Env.cache_ttl,
        save_cd = Env.cache_save_cd,
    }

    Env.mailbox_mgr:start()
    
    Skynet.register('.mailbox')
    LOG_INFO('mailbox booted') 
    NodeMonitorClient.register("mailbox", Cmd.on_exit)  
end)

