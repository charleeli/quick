local Skynet = require 'skynet'
local Cluster = require 'cluster'
local Quick = require 'quick'

local _call_usc = Quick.caller('usc')

local _send_usc = function(...) Skynet.fork(_call_usc, ...) end

local M = {}

function M.update(uuid)
    return _send_usc('update', uuid)
end

function M.query_basic(uuid)
    return _call_usc("query_basic", uuid)
end

function M.query_full(uuid)
    return _call_usc("query_full", uuid)
end

return M
