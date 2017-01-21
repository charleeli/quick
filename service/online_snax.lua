local skynet = require 'skynet'
local snax = require "snax"
local acceptor = require 'acceptor'
local cluster = require "cluster"

--{uid:{node,agent,uid,subid,timestamp}}
local users = {} 

local function _get_user(uid)
    return users[uid]
end

local function _add_user(uid, info)
    users[uid] = {
        node = info.node,
        agent = info.agent,
        uid = info.uid,
        subid = info.subid,
        timestamp = skynet.time()
    }
end

local function _del_user(uid)
    if not users[uid] then
        return false
    end

    users[uid] = nil

    return true
end

function init(...)
    snax.enablecluster()
end

function exit(...)

end

function response.connect(delay)
    return acceptor.connect_handler(delay)
end

function response.online(node,agent,uid,subid)
    local info = {}
    info.node = node
    info.agent = agent
    info.uid = uid
    info.subid = subid
    
    _add_user(uid, info)

    return {errcode = ERRCODE.E_OK}
end

function response.offline(uid)
    _del_user(uid)
    
    return {errcode = ERRCODE.E_OK}
end

function response.query(uid)
    local user = _get_user(uid)
    if not user then
        return {errcode = ERRCODE.E_ONLINE}
    end

    return {errcode = ERRCODE.E_OK, user = user}
end

function response.clear_node(node)
    local del_users = {}
    for uid,info in pairs(users) do
        if info.node == node then
            table.insert(del_users, uid)
        end
    end

    for _, uid in ipairs(del_users) do
        _del_user(uid)
    end

    LOG_INFO('online.clear_node<%s|%s>', node, #del_users)
    return {errcode = ERRCODE.E_OK}
end

function response.register_node(node, agent_list)
    for _, item in ipairs(agent_list) do
        local info = {}
        info.node = item.node
        info.agent = item.agent
        info.uid = item.uid
        info.subid = item.subid
        info.timestamp = item.timestamp

        _add_user(info.uid, info)
    end

    LOG_INFO(
        'online.register_node, node<%s>, agent num<%s>',
        node, #agent_list
    )
    
    return { errcode = ERRCODE.E_OK, fail_list = {} }
end

function response.kick(uid, reason)
    local user = _get_user(uid)
    if not user then
        LOG_INFO("kick user<%s> not find", uid)
        return {errcode = ERRCODE.E_ONLINE, ret = true}
    end

    local node = user.node
    LOG_INFO('kick begin, user<%s> node<%s> reason:<%s>', uid, node, reason)
    
    local _call_gated = function(api, ...)
        local ok, ret = pcall(cluster.call, node, 'gated', api, ...)
        if ok then return ret end
        return {errcode = ERRCODE.E_SERVICE, errdata=ret}
    end

    local ok, ret = pcall(_call_gated, 'kick', user.uid, user.subid)
    if not ok then
        LOG_INFO('kick fail, user<%s> node<%s> reason<%s>, err<%s>',
            user.uid, node, reason, ret
        )
        
        return {errcode = ERRCODE.E_ERROR, ret=false}
    end
    
    LOG_INFO(
        'kick, uid<%s> subid<%s> node<%s> reason:<%s>, ret<%s>',
        user.uid, user.subid,node, reason, ret
    )
    
    return {errcode = ERRCODE.E_OK, ret = ret}
end
