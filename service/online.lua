local Skynet = require 'skynet'
local Acceptor = require 'acceptor'
local Quick = require 'quick'

--{uid:{node,agent,uid,subid,timestamp}}
local users = {} 

local function _get_user(uid)
    return users[uid]
end

local function _add_user(uid, info)
    if users[uid] then
        return false
    end

    users[uid] = {
        node = info.node,
        agent = info.agent,
        uid = info.uid,
        subid = info.subid,
        timestamp = Skynet.time()
    }

    return true
end

local function _del_user(uid)
    if not users[uid] then
        return false
    end

    users[uid] = nil
    
    return true
end

local Cmd = {}

function Cmd.connect(...)
    return Acceptor.connect_handler(...)
end

function Cmd.online(node,agent,uid,subid)
    local info = {}
    info.node = node
    info.agent = agent
    info.uid = uid
    info.subid = subid
    
    local ok = _add_user(uid, info)
    if not ok then
        Skynet.retpack({errcode = ERRNO.E_LOGIN_CONFLICT })
    end
    
    return Skynet.retpack({errcode = ERRNO.E_OK})
end

function Cmd.offline(uid)
    _del_user(uid)
    
    return Skynet.retpack({errcode = ERRNO.E_OK})
end

function Cmd.query(uid)
    local find = _get_user(uid)
    if not find then
        return Skynet.retpack({errcode = ERRNO.E_OK})
    end

    return Skynet.retpack({errcode = ERRNO.E_OK, agent=find.agent})
end

function Cmd.clear_node(node)
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
    return Skynet.retpack({errcode = ERRNO.E_OK})
end

function Cmd.register_node(node, agent_list)
    local fail_list = {}
    for _, item in ipairs(agent_list) do
        local info = {}
        info.node = item.node
        info.agent = item.agent
        info.uid = item.uid
        info.subid = item.subid
        info.timestamp = item.timestamp
        
        local user = _get_user(item.uid)
        if user then 
            if user.node ~= item.node or user.agent ~= item.agent then
                table.insert(fail_list, item)
            end
        else
            _add_user(uid, info)
        end
    end

    LOG_INFO(
        'online.register_node, node<%s>, agent num<%s> fail num<%s>',
        node, #agent_list, #fail_list
    )
    
    return Skynet.retpack({errcode = ERRNO.E_OK, fail_list = fail_list})
end

function Cmd.kick(uid, reason)
    local user = _get_user(uid)
    if not user then
        LOG_INFO("kick user<%s> not find", uid)
        return Skynet.retpack({errcode = ERRNO.E_OK, ret = true})
    end

    local node = user.node
    LOG_INFO(
        'kick begin, user<%s> node<%s> reason:<%s>',
        uid, node, reason
    )
    
    local _call = Quick.caller('gated')

    local ok, ret = pcall(_call, 'kick', user.uid, user.subid)
    if not ok then
        LOG_INFO(
            'kick fail, user<%s> node<%s> reason<%s>, err<%s>',
            user.uid, node, reason, ret
        )
        
        return Skynet.retpack({errcode = ERRNO.E_OK, ret=false})
    end
    
    LOG_INFO(
        'kick suc, user<%s> node<%s> reason:<%s>, ret<%s>',
        user.uid, node, reason, ret
    )
    
    return Skynet.retpack({errcode = ERRNO.E_OK, ret = ret})
end

Skynet.start(function()
    Skynet.dispatch('lua', function(session, address, cmd, ...)
        local f = assert(Cmd[cmd], cmd)
        f(...)
    end)
    
    Skynet.register('.online')
    LOG_INFO('online booted')
end)
