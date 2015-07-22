local Skynet = require 'skynet'
local Quick = require 'quick'

local M = {}

local _call_battle_proxy = Quick.caller('battle_proxy')

local _send_battle_proxy = function(...) Skynet.fork(_call_battle_proxy,...) end

function M.apply_team_battle(...)
    return _send_battle_proxy('apply_team_battle', ...)
end

function M.query_udp_addr(...)
    return _call_battle_proxy('query_udp_addr', ...)
end

return M
