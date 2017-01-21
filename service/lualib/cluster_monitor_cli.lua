local quick = require 'quick'

local _call = quick.caller('cluster_monitor')

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

function M.reload_res(...)
    return _call('reload_res', ...)
end

return M
