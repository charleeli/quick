local Skynet = require 'skynet'
local Quick = require 'quick'
local Env = require 'global'
local Res = require 'res'

local NORMAL_STATE = 0
local APPLY_STATE = 1
local BATTLE_STATE = 2
local ROOM_CHECK_INTERVAL = 2 * 100

local Room = class()

function Room:ctor(room_id)
    self.room_id = room_id
    self.roles = {}
    self.battle_list = {}
    self.state = NORMAL_STATE
    self.battle_info = nil

    Skynet.fork(function()
        local r = Env.room_mgr:get_room(room_id)
        if r then
            while true do
                Skynet.sleep(ROOM_CHECK_INTERVAL)
                r:check()
            end
        end
    end)
end

function Room:check()
    --关卡的推进
    self:check_wave()
end

function Room:check_wave()
    local battle_info = self.battle_info
    
    if battle_info and battle_info.teammate then
        local teammate = battle_info.teammate
        local check_wave_list = battle_info.check_wave_list

        local flag = true
        for k, v in pairs(teammate) do
            if not check_wave_list[k] then
                flag = false
                break
            end
        end

        if flag then
            for k, v in pairs(check_wave_list) do
                if Env.players[k] then
                    local addr = Env.players[k].addr
                    if addr then
                        local node = Env.players[k].node
                        Quick.send(node, addr, 'battle_server_event', 1)
                    end
                end
            end
        end
    end
end

function Room:room_detail()
    local roles = {}
    for uuid,_ in pairs(self.roles) do
        table.insert(roles,{uuid=uuid})
    end
    
    return {room_id = self.room_id, roles = roles}
end

function Room:room_roles_num()
    local cnt = 0
    for k, v in pairs(self.roles) do
        cnt = cnt + 1
    end
    return cnt
end

function Room:set_battle_info(battle_info)
    self.battle_info = battle_info
end

function Room:get_battle_info()
    return self.battle_info
end

function Room:add_role(uuid)
    self.roles[uuid] = true
    
    local info = Env.players[uuid]
    if info then
        info.uuid = uuid
        info.room_id = self.room_id
    end

    for k, v in pairs(self.roles) do
        if Env.players[k] then
            local addr = Env.players[k].addr
            if addr then
                local node = Env.players[k].node
                Quick.send(node, addr, 'room_action', 1, uuid)
            end
        end
    end

    return 0
end

function Room:del_role(uuid)
    for k, v in pairs(self.roles) do
        if Env.players[k] then
            local addr = Env.players[k].addr
            if addr then
                local node = Env.players[k].node
                Quick.send(node, addr, 'room_action', 2, uuid)
            end
        end
    end

    self.roles[uuid] = nil
    
    local info = Env.players[uuid]
    if info then
        info.room_id = nil
    end

    if self:room_roles_num() <= 0 then
        Env.room_mgr:del_room(self.room_id)
    end

    return 0
end

function Room:goto_battle(uuid)
    local cache = self.battle_info.teammate_cache
    if not cache or not cache[uuid] then
        return {errcode = E_ROLE_NOT_IN_CACHE}
    end
    
    local player_list = {}
    for k, v in pairs(cache) do
        table.insert(player_list, v)
    end

    local drop = self.battle_info:get_drop(uuid)
    local seed = self.battle_info:get_seed()
    
    self:set_fight(uuid)

    return {errcode = 0, drop = drop, seed = seed, player_list = player_list}
end

function Room:set_fight(uuid)
    self.state = BATTLE_STATE
    self.battle_list[uuid] = 1

    local flag = true
    for k, v in pairs(self.battle_info.teammate_cache) do
        if not self.battle_list[k] then
            flag = false
        end
    end
    
    if flag then
        self.battle_info.teammate_cache = {}
    end
end

function Room:set_apply()
    self.state = APPLY_STATE
    self.battle_info = nil
end

function Room:end_team_battle(uuid, is_complete)
    if self.state ~= BATTLE_STATE then
        return {errcode = 1}
    end
    
    local battle_info = self.battle_info
    if not battle_info then
        return {errcode = 1}
    end

    local stage_id = battle_info.stage_id
    if not stage_id or stage_id <= 0 then
        return {errcode = 1}
    end

    battle_info:mark_finish(uuid)
    
    local reward = battle_info:cal_reward(uuid, is_complete)
    local star_map = battle_info:cal_star(uuid, is_complete)
    
    battle_info:del_mate(uuid)
    
    self:set_stop(uuid)

    return {errcode = 0, reward = reward, star_map = star_map}
end

function Room:set_stop(uuid)
    self.battle_list[uuid] = nil
    
    if not next(self.battle_list) then
        self.state = NORMAL_STATE
        self.battle_info = nil
    end
end

function Room:check_apply_team(uuid, stage_id)
    if self.state ~= NORMAL_STATE then
        return ERRNO.E_ERROR
    end
    
    local stage_tbl = Res.Stage[stage_id]
    if not stage_tbl then
        return ERRNO.E_ERROR
    end

    for k, v in pairs(self.roles) do
        if not Env.players[k] or not Env.players[k].addr then
            return ERRNO.E_ERROR
        end
    end
    
    return ERRNO.E_OK
end

return Room

