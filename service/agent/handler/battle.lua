local LobbyClient = require 'client.lobby'
local Env = require 'global'

function enter_single_battle(args)
    return Env.role:enter_single_battle(args.stage_id)
end

function end_single_battle(args)
    return Env.role:end_single_battle(args.is_complete)
end

function apply_team_battle(args)
    return Env.role:apply_team_battle(args.stage_id)
end

function enter_team_battle(args)
    return Env.role:enter_team_battle()
end

function send_team_battle_event(args)
    return Env.role:send_team_battle_event(args.event)
end

function team_apply_control(args)
    return Env.role:team_apply_control(args.apply_list)
end

function end_team_battle(args)
    return Env.role:end_team_battle(args.is_complete)
end

