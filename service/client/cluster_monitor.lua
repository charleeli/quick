local Quick = require 'quick'

local _call = Quick.caller('cluster_monitor')

local M = {}

function M.connect(...)
    return _call('connect', ...)
end

function M.register_node(...)
    return _call('register_node', ...)
end

function M.register_service_name(...)
    return _call('register_service_name', ...)
end

function M.shutdown(...)
    return _call('shutdown', ...)
end

return M
