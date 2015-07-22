local Skynet = require "skynet"
local Cmd = require "command"
local Env = require "global"
local RoomMgr = require "room_mgr"

Skynet.start(function()
    Skynet.dispatch("lua", function(session, address, cmd, ...)
        local f = assert(Cmd[cmd])
        f(...)
    end)
    
    Env.room_mgr = RoomMgr.new()

    Skynet.register(".lobby")
    LOG_INFO("lobby booted")
end)

