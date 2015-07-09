local Skynet = require "skynet"
require 'skynet.manager'
local Date = require 'date'
local Const = require 'const'
local Res = require 'res'
local Sign = require 'crud.sign'

local apis ={}

--获取开服时间
local function _opensvr_time()
    local opensvr_cfg = Skynet.getenv('open_server_time')
    if not opensvr_cfg then
        error("no open_server_time cfg!")
    end
    
    local f, err = load("return "..opensvr_cfg)
    assert(f)    
    
    local ok, time = pcall(f)
    assert(ok and type(time) == 'table')
    
    if time.year < 2015 then return nil end
    if time.month < 1 or time.month > 12 then return nil end
    local max_mday = Date.max_mday(time.month)
    if time.day < 1 or time.day > max_mday then return nil end
    if time.hour < 0 or time.hour > 24 then return nil end
    if time.min < 0 or time.min > 60 then return nil end
    if time.sec < 0 or time.sec > 60 then return nil end 

    return time
end

--获取奖励
local function _get_award(level,sign_count)
    local base_conf = Res.SignAwardBase[level]
    if not base_conf then
        LOG_ERROR('get_award,base_conf not exist!')
        return nil
    end
   
    local rate_conf = Res.SignAwardRate[sign_count]
    if not rate_conf then
        LOG_ERROR('get_award ,rate_conf not exist!')
        return nil
    end

    local award_list = {
        ['gold'] = math.floor(base_conf.gold * rate_conf.gold_rate),
        ['exp'] = math.floor(base_conf.exp * rate_conf.exp_rate)
    }

    return award_list
end

function apis:init_sign()
    self.sign = Sign.new(self._role_orm.sign)   
end

function apis:refresh_sign()
    local sign = self.sign:get_sign()
    local now = Date.localtime()
    local last = Date.localtime(sign.last_refresh_time) 

    if now.month ~= last.month or now.year ~= last.year then
        sign.full_duty_awarded = false
        sign.resigned_this_month = 0
        sign.signed_today = false
        sign.last_refresh_time = Date.second()
        sign.signed_this_month = 0
        return sign
    end

    if now.day ~= last.day then
        sign.signed_today = false
        sign.last_refresh_time = Date.second() 
        return sign
    end

    return sign
end

function apis:view_sign()
    --补签次数配置
    local resign_count_conf = Res.ResignCount[self:get_vip()]
    if not resign_count_conf then 
        LOG_ERROR('resign_count_conf not exist!')
        return {errcode = Res.ErrCode.common}
    end
    
    local level = self:get_level() 
    if level < Res.SysConst.sign_open_level then
        LOG_ERROR('view sign,level not enough!')    
        return {errcode = Res.ErrCode.level}
    end

    --取得签到数据
    local sign = self:refresh_sign()
    if not sign then
        LOG_ERROR('view sign,refresh_sign failed!')
        return {errcode = Res.ErrCode.common}
    end 

    local now = Date.localtime()
    local opensvr = _opensvr_time()
    local can_sign_count = now.day 
    if now.month == opensvr.month and now.year == opensvr.year then 
        can_sign_count = now.day - opensvr.day + 1
    end

    local left_resign_count = resign_count_conf.amount - sign.resigned_this_month 
    return {
        errcode = Res.ErrCode.ok,
        sign = self.sign:gen_proto(),
        left_resign_count = left_resign_count,
        can_sign_count = can_sign_count,--本月到今天为止可以签到数量
    }
end

function apis:sign_in()
    --必须达到开放等级
    local level = self:get_level() 
    if level < Res.SysConst.sign_open_level then
        LOG_ERROR('sign in,level not enough!')    
        return {errcode = Res.ErrCode.level}
    end
   
    --补签次数配置
    local resign_count_conf = Res.ResignCount[self:get_vip()]
    if not resign_count_conf then 
        LOG_ERROR('sign in,resign_count_conf not exist!')
        return {errcode = Res.ErrCode.common}
    end
    
    --取得签到数据
    local sign = self:refresh_sign()
    if not sign then
        LOG_ERROR('sign in,refresh_sign failed!')
        return {errcode = Res.ErrCode.common}
    end 

    --今天已经签到了
    if sign.signed_today then
        LOG_ERROR('signed_today yet!')
        return {errcode = Res.ErrCode.signed}
    end

    local now = Date.localtime()
    local opensvr = _opensvr_time()

    --签到次数不得超过 今天的号数/或者开服日到今天的天数
    if now.month ~= opensvr.month or now.year ~= opensvr.year then 
       if sign.signed_this_month >= now.day then
            LOG_ERROR('full signed to now1')
            return {errcode = Res.ErrCode.common}
       end
    else 
        if sign.signed_this_month >= now.day - opensvr.day + 1 then
            LOG_ERROR('full signed to now2')
            return {errcode = Res.ErrCode.common}
        end
    end

    --背包满不准签到
    local award_list = _get_award(self:get_level(),sign.signed_this_month + 1)  
    if not award_list then
        LOG_ERROR('award_list is nil')
        return {errcode = Res.ErrCode.common}
    end

    --签到
    sign.signed_today = true
    sign.signed_this_month = sign.signed_this_month + 1 

    self:add_gold(award_list['gold'])
    self:add_exp(award_list['exp'])
   
    local can_sign_count = now.day 
    if now.month == opensvr.month and now.year == opensvr.year then 
        can_sign_count = now.day - opensvr.day + 1
    end

    return {
        errcode = Res.ErrCode.ok,
        base = self:gen_base_proto(),
        sign =self.sign:gen_proto(),
        left_resign_count = resign_count_conf.amount - sign.resigned_this_month,
        can_sign_count = can_sign_count,
    }

end

function apis:resign()
    --必须达到开放等级
    local level = self:get_level() 
    if level < Res.SysConst.sign_open_level then
        LOG_ERROR('sign in,level not enough!')    
        return {errcode = Res.ErrCode.level}
    end
   
    --补签次数配置
    local resign_count_conf = Res.ResignCount[self:get_vip()]
    if not resign_count_conf then 
        LOG_ERROR('sign in,resign_count_conf not exist!')
        return {errcode = Res.ErrCode.common}
    end
    
    --取得签到数据
    local sign = self:refresh_sign()
    if not sign then
        LOG_ERROR('sign in,refresh_sign failed!')
        return {errcode = Res.ErrCode.common}
    end 
    
    --取得补签消耗配置
    local resign_cost_conf = Res.ResignCost[sign.resigned_this_month+1]
    if not resign_cost_conf then
        LOG_ERROR('resign_cost_conf not exist!')
        return {errcode = Res.ErrCode.common}
    end

    local now = Date.localtime()
    local opensvr = _opensvr_time()

    --已经签到次数不得超过 今天的号数/或者开服日到今天的天数
    if now.month ~= opensvr.month or now.year ~= opensvr.year then 
       if sign.signed_this_month >= now.day then
            LOG_ERROR('full resigned to now1')
            return {errcode = Res.ErrCode.common}
       end
    else 
        if sign.signed_this_month >= now.day - opensvr.day + 1 then
            LOG_ERROR('full resigned to now2')
            return {errcode = Res.ErrCode.common}
        end
    end

    --如果今天还没有签到
    if not sign.signed_today then
        LOG_ERROR('not signed_today yet!')
        return {errcode = Res.ErrCode.notsigned}
    end

    --如果补签次数用完了
    local left_resign_count = resign_count_conf.amount - sign.resigned_this_month 
    if left_resign_count <= 0 then
        LOG_ERROR('no resign count left!')
        return {errcode = Res.ErrCode.resign_count}
    end

    --背包满了
    local award_list = _get_award(self:get_level(),sign.signed_this_month + 1)  
    if not award_list then
        LOG_ERROR('award_list is nil')
        return {errcode = Res.ErrCode.common}
    end

    --扣除点券
    local err = self:sub_coupon(resign_cost_conf.cost)
    if err.errcode ~= Res.ErrCode.ok then
        LOG_ERROR('sub coupon failed!')
        return {errcode = err.errcode}
    end
    
    sign.resigned_this_month = sign.resigned_this_month + 1
    sign.signed_this_month = sign.signed_this_month + 1

    --发奖励
    self:add_gold(award_list['gold'])
    self:add_exp(award_list['exp'])

    local can_sign_count = now.day 
    if now.month == opensvr.month and now.year == opensvr.year then 
        can_sign_count = now.day - opensvr.day + 1
    end
    
    return {
        errcode = Res.ErrCode.ok,
        base = self:gen_base_proto(),
        sign =self.sign:gen_proto(),
        left_resign_count = resign_count_conf.amount - sign.resigned_this_month,
        can_sign_count = can_sign_count,
    }

end

function apis:full_duty()
    --必须达到开放等级
    local level = self:get_level() 
    if level < Res.SysConst.sign_open_level then
        LOG_ERROR('resign,level not enough!')    
        return {errcode = Res.ErrCode.lv}
    end
    
    local sign = self:refresh_sign()
    if not sign then
        LOG_ERROR('full duty award,refresh_sign failed!')
        return {errcode = Res.ErrCode.common}
    end

     --取得补签次数配置
    local resign_count_conf = Res.ResignCount[self:get_vip()]
    if not resign_count_conf then 
        LOG_ERROR('resign_count_conf not exist!')
        return {errcode = Res.ErrCode.common}
    end
    
    --已经领取过全勤奖励了
    if sign.full_duty_awarded then
        LOG_ERROR('have got the full_duty award!')
        return {errcode = Res.ErrCode.full_duty_awarded}
    end

    --背包满了
    local award_list = Res.FullDutyAward
    if not award_list then
        LOG_ERROR('award_list is nil')
        return {errcode = Res.ErrCode.common}
    end

    local now = Date.localtime()
    local opensvr = _opensvr_time()
    local max_mday = Date.max_mday(now.month)
    
    --是否全勤
    local count = sign.signed_this_month
    if now.month ~= opensvr.month or now.year~= opensvr.year then
        if count < max_mday then
            LOG_ERROR('not full duty this month a !')
            return {errcode = Res.ErrCode.full_duty}
        end
    else
        if count < max_mday - opensvr.day + 1 then
            LOG_ERROR('not full duty this month b !')
            return {errcode = Res.ErrCode.full_duty}
        end
    end

    --领奖
    sign.full_duty_awarded = true
    
    local can_sign_count = now.day 
    if now.month == opensvr.month and now.year == opensvr.year then 
        can_sign_count = now.day - opensvr.day + 1
    end
        
    return {
        errcode = Res.ErrCode.ok,
        base = self:gen_base_proto(),
        sign =self.sign:gen_proto(),
        left_resign_count = resign_count_conf.amount - sign.resigned_this_month,
        can_sign_count = can_sign_count,
    }
end

local triggers = {
    [Const.EVT_ONLINE] = function(self)
        self:init_sign()
        return
    end,

    [Const.EVT_OFFLINE] = function(self)
        return
    end
}

return {apis = apis, triggers = triggers}
