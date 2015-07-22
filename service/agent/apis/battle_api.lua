local LobbyClient = require 'client.lobby'
local BattleInfo = require 'lobby.battleinfo'
local Date = require 'date'
local Env = require 'global'
local Res = require 'res'

local apis = {}

function apis:set_battle(type, battle_info)
    self.battle_type = type
    self.battle_info = battle_info
end

function apis:get_battle_type()
    return self.battle_type
end

function apis:get_battle_info()
    return self.battle_info
end

function apis:reward_battle(reward)

end

function apis:enter_single_battle(stage_id)
    local stage_tbl = Res.Stage[stage_id]
    if not stage_tbl then
        return {errcode = ERRNO.E_STAGE_NOT_EXIST}
    end
  
    local battle_info = BattleInfo.new(
        stage_id, 
        "single", 
        Date.second(), 
        {Env.role:get_uuid()}
    )
    battle_info:gen_drop()
    
    Env.role:set_battle("single", battle_info)
    
    local drop = battle_info:get_drop(Env.role:get_uuid())

    return {errcode = 0, drop = drop}
end

function apis:end_single_battle(is_complete)
    local battle_info = self:get_battle_info()
    if not battle_info then
        return {errcode = ERRNO.E_ERROR}
    end
    
    battle_info:mark_finish(Env.role:get_uuid(), Date.second())
    
    local star_map = battle_info:cal_star(Env.role:get_uuid(), is_complete)
    local reward = battle_info:cal_reward(Env.role:get_uuid(), is_complete)
    local gold, exp, items = self:reward_battle(reward)

    local settle = {}
    settle.gold = gold
    settle.exp = exp
    settle.items = items
    settle.star_map = star_map

    battle_info:del_mate(Env.role:get_uuid())
    Env.role:set_battle()

    return {errcode = 0, settle = settle}
end

function apis:apply_team_battle(stage_id)
    return LobbyClient.apply_team_battle(self:get_uuid(), stage_id)
end

function apis:enter_team_battle()
    local ret_info = LobbyClient.enter_team_battle(Env.role:get_uuid())
    if ret_info.errcode ~= 0 then
        return {errcode = ret_info.errcode}
    end
    
    self:set_battle("team")

    return {
        errcode = ret_info.errcode, 
        drop = ret_info.drop, 
        seed = ret_info.seed,
        role_list = ret_info.role_list
    }
end

function apis:send_team_battle_event(event)
    local battle_type = Env.role:get_battle_type()
    local battle_info = Env.role:get_battle_info()

    if event and event.id then
        if battle_type == 'single' and battle_info then
            battle_info:handle_event(Env.role:get_uuid(), event.id, event.data)
        elseif battle_type == 'team' then
            LobbyClient.send_team_battle_event(Env.role:get_uuid(), event.id, event.data)
        end
    end
    
    return {errcode = ERRNO.E_OK}
end

function apis:team_apply_control(apply_list)
    LobbyClient.team_apply_control(Env.role:get_uuid(), apply_list)
    return {errcode = ERRNO.E_OK}
end

function apis:end_team_battle(is_complete)
    local ret_info = LobbyClient.end_team_battle(Env.role:get_uuid(), is_complete)
    if ret_info.errcode ~= 0 then
        return {errcode = ret_info.errcode}
    end
    
    local star_map = ret_info.star_map
    local reward = ret_info.reward

    local gold, exp, items = self:reward_battle(Env.role, reward)
    local settle = {
        star_map = star_map,
        gold = gold,
        exp = exp,
        items = items,
    }

    Env.role:set_battle()

    return {errcode = 0, settle = settle}
end

local triggers = {

}

return {apis = apis, triggers = triggers}

