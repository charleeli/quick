--local Monitor = require "monitor"
local Skynet = require "skynet"
local Env = require "global"
local Cmd = require "command"
local MailBoxMgr = require 'mailbox.mailbox_mgr'

Skynet.start(function()
    Skynet.dispatch("lua", function(session, from, cmd, ...)
        local f = assert(Cmd[cmd], cmd)
        f(...)
    end)

    Env.mailbox_mgr = MailBoxMgr.new{
        max_cnt = Env.cache_max_cnt,
        ttl = Env.cache_ttl,
        save_cd = Env.cache_save_cd,
    }

    Env.mailbox_mgr:start()
    
    Skynet.register('.mailbox')
    LOG_INFO('mailbox booted') 
    --Monitor.register("mailbox", Cmd.on_exit)  
end)

