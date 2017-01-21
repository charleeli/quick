local skynet = require "skynet"
local cluster = require "cluster"
local snax = require "snax"
local quick = require 'quick'

function init(...)
    snax.enablecluster()
end

function exit(...)

end

function response.call(uid, op, ...)
    local node, agent

    local online_cli = cluster.snax(quick.center_node_name(), "online_snax")
    local ret = online_cli.req.query(uid)
    if ret.errcode ~= ERRNO.E_OK then
        LOG_INFO("call fail, query uid<%s>, errcode<%s>", uid, ret.errcode)
        return {errcode = ret.errcode }
    end

    node = ret.user.node
    agent = ret.user.agent

    local ok, resp = pcall(cluster.call, node, agent, op, ...)
    if not ok then
        LOG_INFO("call pcall fail")
        return {errcode = ok}
    end

    return {errcode = ERRNO.E_OK, ret = resp}
end

function response.send(uid, op, ...)
    skynet.fork(response.call, uid, op, ...)
end
