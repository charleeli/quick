local Skynet = require "skynet"

local function _call_res_mgr(cmd, ...)
    return Skynet.call('.res_mgr', "lua", cmd, ...)
end

local function _send_res_mgr(cmd, ...)
    Skynet.send('.res_mgr', "lua", cmd, ...)
end

local M = {}

function M.reload_res()
    _send_res_mgr('reload_res')
end

return M
