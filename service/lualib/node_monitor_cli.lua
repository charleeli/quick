local skynet = require "skynet"

local service

local function _call(cmd, ...)
    return skynet.call(service, "lua", cmd, ...)
end

local function _send(cmd, ...)
    skynet.send(service, "lua", cmd, ...)
end

local M = {}

function M.register(service_name, cb)
    skynet.atexit(cb)
    _send("register", skynet.self(), service_name)
end

skynet.init(function()
    service = skynet.uniqueservice(true, "node_monitor")
    assert(service)
end, "node_monitor")

return M
