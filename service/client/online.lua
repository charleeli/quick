local Quick = require 'quick'

local _call = Quick.caller('online')

local M = {}

function M.connect(delay)
    return _call('connect', delay)
end

function M.online(node,agent,uid,subid)
    return _call('online', node,agent,uid,subid)
end

function M.query(uid)
    return _call('query', uid)
end

function M.offline(uid)
    return _call('offline', uid)
end

function M.kick(uid, reason)
    return _call('kick', uid, reason)
end

function M.clear_node(node_name)
    return _call('clear_node', node_name)
end

function M.register_node(node_name, agent_list)
    return _call('register_node', node_name, agent_list)
end

return M
