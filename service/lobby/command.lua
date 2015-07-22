local Skynet = require 'skynet'
local Cluster = require 'cluster'
local Quick = require 'quick'
local Json = require 'json'
local Date = require 'date'
local Env = require 'global'
local BattleInfo = require 'battleinfo' 
local BattleProxyClient = require 'client.battle_proxy'

local APPLY_TEAM_BATTLE_RESULT = 1

local M = {}

function M.register(node, addr, uuid)
    local info = Env.players[uuid]
    if info then
        info.node = node
        info.addr = addr
        info.uuid = uuid
    else
        info = {}
        info.node = node
        info.addr = addr
        info.uuid = uuid
        Env.players[uuid] = info
    end
    
    return Skynet.retpack(true)
end

function M.unregister(uuid)
    local info = Env.players[uuid]
    if info then
        local r = Env.room_mgr:get_room(info.room_id)
        if r then
            r:del_role(uuid)
        end
    end
    
    Env.players[uuid] = nil
    
    return Skynet.retpack(true)
end

function M.create_room(uuid)
    local r = Env.room_mgr:new_room()
    if r then
        local flag = r:add_role(uuid)
        return Skynet.retpack{
            errcode = flag, 
            room_id = r.room_id, 
            detail = r:room_detail()
        }
    else
        return Skynet.retpack{errcode = ERRNO.E_ERROR}
    end
end

function M.enter_room(uuid, room_id)
    local r = Env.room_mgr:get_room(room_id)
    if r then
        local flag = r:add_role(uuid)
        return Skynet.retpack{
            errcode = flag, 
            detail = r:room_detail()
        }
    else
        return Skynet.retpack{errcode = ERRNO.E_ERROR}
    end
end

function M.exit_room(uuid)
    local info = Env.players[uuid]
    if not info then
        return Skynet.retpack{errcode = ERRNO.E_ROLE_NOT_IN_LOBBY}
    end
    
    local room_id = info.room_id
    local r = Env.room_mgr:get_room(room_id)
    if r then
        local flag = r:del_role(uuid)
        return Skynet.retpack{errcode = flag}
    else
        return Skynet.retpack{errcode = ERRNO.E_ERROR}
    end
end

function M.show_room_detail(room_id)
    local r = Env.room_mgr:get_room(room_id)
    if r then
        return Skynet.retpack{errcode = 0, detail = r:room_detail()}
    else
        return Skynet.retpack{errcode = ERRNO.E_ERROR}
    end
end

function M.show_all_rooms()
    local room_list = Env.room_mgr:get_room_list()
    
    local tmp = {}
    for k, v in pairs(room_list) do
        local v2 = {}
        v2.room_id = v.room_id
        table.insert(tmp, v2)
    end
    
    return Skynet.retpack{errcode = 0, rooms = tmp}
end

function M.apply_team_battle(uuid, stage_id)
    local info = Env.players[uuid]
    if not info then
        return Skynet.retpack{errcode = ERRNO.E_ERROR}
    end
    
    local room_id = info.room_id
    local r = Env.room_mgr:get_room(room_id)
    if r then
        local err = r:check_apply_team(uuid, stage_id)
        if err ~= 0 then
            return Skynet.retpack{errcode = err}
        end

        local uuid_list = {}
        for k, v in pairs(r.roles) do
            table.insert(uuid_list, k)
        end
        
        BattleProxyClient.apply_team_battle(r.room_id, stage_id, uuid_list)
        
        r:set_apply()
        return Skynet.retpack{errcode = 0}
    end
    
    return Skynet.retpack{errcode = ERRNO.E_ERROR}
end

function M.enter_team_battle(uuid)
    local info = Env.players[uuid]
    if not info then
        return Skynet.retpack{errcode = ERRNO.E_ROLE_NOT_IN_LOBBY}
    end
    
    local room_id = info.room_id
    local r = Env.room_mgr:get_room(room_id)
    if r then
        local ret = r:goto_battle(uuid)
        --print(r)
        return Skynet.retpack(ret)
    else
        return Skynet.retpack{errcode = ERRNO.E_ROOM_NOT_EXIST}
    end
end

function M.team_apply_control(uuid, apply_list)
    local info = Env.players[uuid]
    if not info then
        return Skynet.retpack(true)
    end
    
    local room_id = info.room_id
    local r = Env.room_mgr:get_room(room_id)
    if r then
        local battle_info = r:get_battle_info()
        if not battle_info then
            return Skynet.retpack(true)
        end
        
        local newlist = battle_info:team_apply_control(uuid, apply_list)
        if newlist and #newlist > 0 then
            for k, v in pairs(r.roles) do
                local node = Env.players[k].node
                local addr = Env.players[k].addr
                if node and addr then
                    Quick.send(node, addr, "battle_control_action", k, newlist)
                end
            end
        end
    end
    
    return Skynet.retpack(true)
end

function M.send_team_battle_event(uuid, event_id, event_data)
    local info = Env.players[uuid]
    if not info then
        return Skynet.retpack(true)
    end
    
    local room_id = info.room_id
    local r = Env.room_mgr:get_room(room_id)
    if r then
        local battle_info = r:get_battle_info()
        if not battle_info then
            return Skynet.retpack(true)
        end
        
        battle_info:handle_event(uuid, event_id, event_data)
    end
  
    return Skynet.retpack(true)
end

function M.end_team_battle(uuid, is_complete)
    local info = Env.players[uuid]
    if not info then
        return Skynet.retpack{errcode = ERRNO.E_ERROR}
    end
    
    local room_id = info.room_id
    local r = Env.room_mgr:get_room(room_id)
    if r then
        local ret = r:end_team_battle(uuid, is_complete)
        return Skynet.retpack(ret)
    else
        return Skynet.retpack{errcode = ERRNO.E_ERROR}
    end
end

function M.from_battle_proxy(ptype, pcontent_len, pcontent)
    if ptype == APPLY_TEAM_BATTLE_RESULT then
        local data = Json:decode(pcontent)
        local room_id = math.floor(data.room_id)
        local flag = data.flag
        local stage_id = math.floor(data.stage_id)

        local r = Env.room_mgr:get_room(room_id)
        if r then
            local player_list = {}
            for k, v in pairs(r.roles) do
                if not Env.players[k] or not Env.players[k].addr then
                    return
                end
                table.insert(player_list, k)
            end
            
            local battle_info = BattleInfo.new(stage_id, "team", Date.second(), player_list)
            battle_info:gen_drop()
            battle_info:gen_seed()

            r:set_battle_info(battle_info)
            for k, v in pairs(r.roles) do
                local node = Env.players[k].node
                local addr = Env.players[k].addr
                Quick.send(node, addr, "battle_team_apply_result", flag)
            end
            
            battle_info.teammate_cache = {}
            for k, v in pairs(r.roles) do
                local node = Env.players[k].node
                local addr = Env.players[k].addr
                local info = Cluster.call(node, addr, "query_proto_info")
                if info then
                    battle_info.teammate_cache[k] = info
                end
            end
        end
    else
        print('err:', ptype, pcontent_len, pcontent)
    end
end

return M
