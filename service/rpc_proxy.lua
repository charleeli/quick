local Skynet = require "skynet"
local Quick = require 'quick'
local OnlineClient = require 'client.online'

local Cmd = {}

function Cmd.call_agent(uuid, op, ...)
    local uid,node,agent

    uid = ret.base.uid
    
    ret = OnlineClient.query(uid)
    if ret.errcode ~= ERRNO.E_OK then
        LOG_INFO("call_agent fail,query uid<%s>,errcode<%s>",uid,ret.errcode)
        return Skynet.retpack{errcode = ret.errcode }
    end
    
    node = ret.user.node
    agent = ret.user.agent

    local ok, resp = pcall(Cluster.call, node, agent, op, ...)
    if not ok then 
        LOG_INFO("call_agent pcall fail")
        return Skynet.retpack{errcode = ok} 
    end
            
    return Skynet.retpack{errcode = ERRNO.E_OK, ret = resp}
end

function Cmd.send_agent(uuid, op, ...)
    Skynet.fork(Cmd.call_agent, uuid, op, ...)
end

Skynet.start(function()
    Skynet.dispatch('lua', function(session, address, cmd, ...)
        local f = assert(Cmd[cmd], cmd)
        f(...)
    end)

    Skynet.register(".rpc_proxy")
    LOG_INFO('rpc_proxy booted')
end)
