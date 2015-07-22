local Skynet = require 'skynet'
local Quick = require 'quick'

local M = {}

local _rcall_lobby = Quick.caller('lobby')

local _rsend_lobby = function (...) Skynet.fork(_rcall_lobby, ...) end

--登入登出战斗大厅
function M.register(...)
    return _rsend_lobby('register', ...)
end

function M.unregister(...)
    return _rsend_lobby('unregister', ...)
end

--房间
function M.create_room(...)
    return _rcall_lobby('create_room', ...)
end

function M.enter_room(...)
    return _rcall_lobby('enter_room', ...)
end

function M.exit_room(...)
    return _rcall_lobby('exit_room', ...)
end

function M.show_all_rooms(...)
    return _rcall_lobby('show_all_rooms', ...)
end

function M.show_room_detail(...)
    return _rcall_lobby('show_room_detail', ...)
end

--战斗
function M.apply_team_battle(...)
    return _rcall_lobby('apply_team_battle', ...)
end

function M.enter_team_battle(...)
    return _rcall_lobby('enter_team_battle', ...)
end

function M.send_team_battle_event(...)
    return _rsend_lobby('send_team_battle_event', ...)
end

function M.team_apply_control(...)
    return _rsend_lobby('team_apply_control', ...)
end

function M.end_team_battle(...)
    return _rcall_lobby('end_team_battle', ...)
end

--来自战斗服务器
function M.from_battle_proxy(...)
    return _rsend_lobby('from_battle_proxy', ...)
end

return M
