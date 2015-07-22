local Skynet = require "skynet"
local Json = require 'json'
local Notify = require 'notify'
local Env = require 'global'

local M = {}

function M.query_proto_info()
    Skynet.retpack(Env.role:gen_proto())
end

function M.room_action(iType, uuid)
    Notify.room_action(iType, uuid)
    Skynet.retpack(true)
end

function M.battle_team_apply_result(flag)
    Notify.battle_team_apply_result(flag)
    Skynet.retpack(true)
end

function M.battle_server_event(id, data)
    local data = data or {}
    data = Json:encode(data)
    Notify.battle_server_event(id, data)
    Skynet.retpack(true)
end

function M.battle_control_action(uuid, control_list)
    Notify.battle_control_action(uuid, control_list)
    Skynet.retpack(true)
end

return M
