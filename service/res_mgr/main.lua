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

local Command = {}

local res_path = "./service/res_mgr/res.lua"

function Command.reload_res()
    local res_file = readfile(res_path)
    ShareData.update('res', res_file)
    return Skynet.retpack(true)
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
end)
