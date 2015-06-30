local Skynet = require "skynet"
require 'skynet.manager'
local ShareData = require "sharedata"

local function readfile(file)
    local fh = io.open(file , "rb")
    if not fh then return end
    local data = fh:read("*a")
    fh:close()
    return data
end

local res_path = "./service/agent/resmgr.lua"

local Command = {}

function Command.reload_res()
    local res_file = readfile(res_path)
    ShareData.update('resource', res_file)
    return Skynet.retpack(true)
end

Skynet.start(function()
    Skynet.dispatch('lua', function(session, address, cmd, ...)
        local f = assert(Command[cmd], cmd)
        f(...)
    end)

    local res_file = readfile(res_path)
    ShareData.new('resource', res_file)
    Skynet.register('.resource')
    LOG_INFO('resource booted')
end)
