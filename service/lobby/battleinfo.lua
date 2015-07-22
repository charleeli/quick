local Date = require 'date'
local Json = require 'json'
local Res = require 'res'
local Drop = require 'lobby.drop'
local TeamMate = require 'lobby.teammate'

local BattleInfo = class()

function BattleInfo:ctor(stage_id, type, time, uuid_list)
    self.stage_id = stage_id                    --关卡ID
    self.type = type                            --战斗类型
    self.seed = nil                             --随机种子

    self.teammate = {}                          --队友
    for _, v in ipairs(uuid_list) do
        self.teammate[v] = TeamMate.new(v, time)
    end

    self.control_map = {}                       --
    self.check_wave_list = {}                   --
end

function BattleInfo:dtor()
end

function BattleInfo:del_mate(uuid)
    self.teammate[uuid] = nil
end

function BattleInfo:gen_seed()
    self.seed = math.random(1, 10000)
end

function BattleInfo:get_seed()
    return self.seed
end

function BattleInfo:get_drop(i)
    local mate = self.teammate[i]
    if mate and mate.drop then
        return mate.drop
    end
end

function BattleInfo:mark_finish(uuid, time)
    local mate = self.teammate[uuid]
    if mate then
        mate:finish(time)
    end
end

function BattleInfo:handle_event(uuid, event_id, event_data)
    local mate = self.teammate[uuid]
    if not mate then
        return
    end
    
    local data
    if event_data then
        data = Json:decode(event_data)
    end
    
    --此处编号定义请对照关卡事件表
    if event_id == 1 then --剩余血量
        local left_hp = math.floor(data.hp)
        mate.left_hp = left_hp

    elseif event_id == 2 then --使用药水
        mate.use_medicine = (mate.use_medicine or 0) + 1

    elseif event_id == 3 then --一波搞定
        self.check_wave_list[mate.uuid] = Date.second()
    end
end

function BattleInfo:cal_star(uuid, is_complete)
    local mate = self.teammate[uuid]
    if not mate then
        return {}
    end
    if mate.star_map then
        return mate.star_map
    end

    local stage_tbl = Res.Stage[self.stage_id]
    local star_event_list = stage_tbl.star_event_list

    local star_map = {}
    if not is_complete or is_complete <= 0 then
        table.insert(star_map, {id = 0, finish = 0, star = 1})
        for _, v in ipairs(star_event_list) do
            table.insert(star_map, {id = v.id, finish = 0, star = v.star})
        end
        
    else
        table.insert(star_map, {id = 0, finish = 1, star = 1})
        for _, v in ipairs(star_event_list) do
            --此处编号定义请对照x星级条件表
            if v.id == 1 then
                if not mate.use_medicine or mate.use_medicine <= 0 then
                    table.insert(star_map, {id = v.id, finish = 1, star = v.star})
                end

            elseif v.id == 2 then
                if stage_tbl.assign_time_pass > 0 and mate.begin_time and mate.finish_time and (mate.finish_time - mate.begin_time) <= stage_tbl.assign_time_pass then
                    table.insert(star_map, {id = v.id, finish = 1, star = v.star})
                end

            elseif v.id == 3 then
                if self.left_hp and self.left_hp/100 >= stage_tbl.assign_blood_ratio then
                    table.insert(star_map, {id = v.id, finish = 1, star = v.star})
                end
            end
        end

    end

    mate.star_map = star_map
    return star_map
end

function BattleInfo:gen_drop()
    local stage_tbl = Res.Stage[self.stage_id]
    if not stage_tbl then
        return
    end

    for k, v in pairs(self.teammate) do
        local handle_lst = {
            normal = stage_tbl.normal_drop,
            boss = stage_tbl.boss_drop
        }
        local result = {}
        for k2, v2 in pairs(handle_lst) do
            if v2 and v2 > 0 then
                result[k2] = Drop.gen_drop(v2)
            end
        end
        v.drop = result
    end
end

function BattleInfo:cal_reward(uuid, is_complete)
    local reward = {}
    local stage_tbl = Res.Stage[self.stage_id]
    if not stage_tbl or not is_complete or is_complete <= 0 then
        return reward
    end

    --固定奖励
    reward.fixed = {}
    reward.fixed.gold = stage_tbl.reward_gold
    reward.fixed.exp = stage_tbl.reward_exp

    --掉落奖励
    local drop = self:get_drop(uuid)
    reward.normal_drop = Drop.assort_drop(drop.normal) 
    reward.boss_drop = Drop.assort_drop(drop.boss)

    return reward
end

function BattleInfo:team_apply_control(uuid, apply_list)
    local map = self.control_map
   
    local newlist = {}
    for _, v in ipairs(apply_list) do
        if not map[v] then
            map[v] = uuid
            table.insert(newlist, v)
        end
    end
    
    return newlist
end

return BattleInfo
