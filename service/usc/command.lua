local Skynet = require "skynet"
local Env = require "global"
local Date = require "date"
local Const = require 'const'
local Loader = require 'mongo_loader'
local Base = require 'usc.base'

local M = {}

function M.update(role_uuid)
    if not role_uuid then
        return nil
    end
    
    local data = Loader.load_base(role_uuid)
    
    if not data then
        if not Loader.has_role(role_uuid) then 
            return nil
        end
    end

    local obj = data
    obj.role_uuid = role_uuid
    
    local item = Base.new(obj,role_uuid)

    Env.base_mgr:add_cache(item)
    return item
end

function M.gen_basic(base)
    if not base then
        return nil
    end

    return {
        name = base.name,
        gender = base.gender,
        exp = base.exp,
        level = base.level,
        vip = base.vip,
        gold = base.gold,
        coupon = base.coupon,
        sign_score = base.sign_score,
    }
end

function M.query_basic(role_uuid)
    local m = Env.base_mgr:get_item(role_uuid)
    if not m then
        return Skynet.retpack{errcode = ERRNO.E_ERROR}
    end

    local base = m:get_obj()

    if not base then
        return Skynet.retpack({errcode = ERRNO.E_ROLE_NOT_EXISTS})
    end

    return Skynet.retpack{
        errcode = ERRNO.E_OK,
        base = M.gen_basic(base),
    }
end

function M.query_full(role_uuid)
    return M.query_basic(role_uuid)
end

function M.on_exit()
    LOG_INFO("shutdown usc service")
    Env.base_mgr:exit()
end

return M
