local Skynet = require "skynet"

local ShareData = require "sharedata"
local NodeMonitorClient = require 'client.node_monitor'

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
    ShareData.update('res', res_file)
    LOG_INFO('res_mgr reload_res succeed')
    return Skynet.retpack(true)
end

function Command.on_exit()
    local res_file = readfile(res_path)
    ShareData.delete('res')
    LOG_INFO('res_mgr delete res succeed')
end

Skynet.start(function()
    Skynet.dispatch('lua', function(session, address, cmd, ...)
        local f = assert(Command[cmd], cmd)
        f(...)
    end)

    local res_file = readfile(res_path)
    ShareData.new('res', res_file)
    Skynet.register('.res_mgr')
    LOG_INFO('res_mgr booted')
    
    NodeMonitorClient.register("res_mgr", Command.on_exit)  
end)
