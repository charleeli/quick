local Skynet = require "skynet"

local service

local function _call(cmd, ...)
    return Skynet.call(service, "lua", cmd, ...)
end

local function _send(cmd, ...)
    Skynet.send(service, "lua", cmd, ...)
end

local M = {}

function M.register(service_name, cb)
    Skynet.atexit(cb)
    _send("register", Skynet.self(), service_name)
end

Skynet.init(function()
    service = Skynet.uniqueservice(true, "node_monitor")
    assert(service)
end, "node_monitor")

return M
