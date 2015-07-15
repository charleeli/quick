local Skynet = require 'skynet'
local M = {}

local _call = function(...)
    Skynet.call(".rpc_proxy", "lua", ...)
end

local _send = function(...)
    Skynet.send(".rpc_proxy", "lua", ...)
end

function M.call_agent(uuid, op, ...)
    _call("call_agent", uuid, op, ...)
end

function M.send_agent(uuid, op, ...)
    _send("send_agent", uuid, op, ...)
end

return M
