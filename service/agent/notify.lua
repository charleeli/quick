local Env = require 'global'
local Quick = require 'quick'

local function _send(proto, ...)
    if Env.zinc_client then
        Quick.notify(Env.zinc_client, proto, ...)
    end
end

local M = {}

function M.daily_update()
    if not Env.role then return end
    _send('daily_update')
end

function M.chat(msg)
    if not Env.role then return end
    _send('chat', {
        chats = {msg}
    })
end

function M.mail(private_mails, system_mails)
    if not Env.role then return end
    _send('mail', {
        private_mails = private_mails, 
        system_mails = system_mails
    })
end

function M.notify_udp_addr(udp_ip, udp_port)
    if not Env.role then return end
    _send('notify_udp_addr', {udp_ip = udp_ip, udp_port = udp_port})
end

function M.room_action(i, uuid)
    if not Env.role then return end
    _send('room_action', {action = i, uuid = uuid})
end

function M.battle_team_apply_result(flag)
    if not Env.role then return end
    _send('battle_team_apply_result', {flag = flag})
end

function M.battle_server_event(id, data)
    if not Env.role then return end
    _send('battle_server_event', {event = {id = id, data = data}})
end

function M.battle_control_action(uuid, control_list)
    if not Env.role then return end
    _send('battle_control_action', {uuid = uuid, control_list = control_list})
end

return M
