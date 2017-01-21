local skynet = require "skynet"
local quick = require 'quick'
local sharedata = require "sharedata"
local acceptor = require 'acceptor'
local connector = require 'connector'
local node_monitor_cli = require 'node_monitor_cli'
local cluster_monitor_cli = require 'cluster_monitor_cli'

local function readfile(file)
    local fh = io.open(file , "rb")
    if not fh then return end
    local data = fh:read("*a")
    fh:close()
    return data
end

local Command = {}

local res_path = "./service/res_mgr/res.lua"

function Command.reload_res()
    local res_file = readfile(res_path)
    sharedata.update('res', res_file)
    LOG_INFO('res_mgr reload_res succeed')
    return skynet.retpack(true)
end

function Command.on_exit()
    local res_file = readfile(res_path)
    sharedata.delete('res')
    LOG_INFO('res_mgr delete res succeed')
end

local cluster_monitor_connector

local function connect_cluster_monitor_cb(...)
    local _call_speaker = quick.caller('cluster_monitor')
    local  r = _call_speaker('connect', ...)
    return r
end

local function disconnect_cluster_monitor_cb()

end

local function connected_cluster_monitor_cb()
    local ok, err = pcall(node_monitor_cli.register, "res_mgr", Command.on_exit)
    if not ok then
        LOG_ERROR("register listener fail, err<%s>", err)
        return false
    end

    return true
end

skynet.start(function()
    skynet.dispatch('lua', function(session, address, cmd, ...)
        local f = assert(Command[cmd], cmd)
        f(...)
    end)

    local res_file = readfile(res_path)
    sharedata.new('res', res_file)
    skynet.register('.res_mgr')

    cluster_monitor_connector = connector(
        connect_cluster_monitor_cb,
        connected_cluster_monitor_cb,
        disconnect_cluster_monitor_cb
    )
    cluster_monitor_connector:start()

    LOG_INFO('res_mgr booted')
end)
