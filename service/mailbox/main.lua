local skynet = require "skynet"
local env = require "env"
local Cmd = require "cmd"
local MailboxMgr = require 'mailbox.mailbox_mgr'
local node_monitor_cli = require 'node_monitor_cli'

skynet.start(function()
    skynet.dispatch("lua", function(session, from, cmd, ...)
        local f = assert(Cmd[cmd], cmd)
        f(...)
    end)

    env.mailbox_mgr = MailboxMgr{
        max_cnt = env.cache_max_cnt,
        ttl = env.cache_ttl,
        save_cd = env.cache_save_cd,
    }

    env.mailbox_mgr:start()
    
    skynet.register('.mailbox')
    LOG_INFO('mailbox booted') 
    node_monitor_cli.register("mailbox", Cmd.on_exit)
end)

