local CacheMgr = require 'cache_mgr'
local Loader = require 'mongo_loader'
local Base = require 'usc.base'

local BaseMgr = class(CacheMgr)

function BaseMgr:get_item(role_uuid)
    if not role_uuid or type(role_uuid) ~= "string" then
        return nil
    end
    
    local item = self:get_cache(role_uuid)
    if item ~= nil then
        return item
    end

    local data = Loader.load_base(role_uuid)
    if not data then
        if not Loader.has_role(role_uuid) then 
            return nil
        end
    end
    
    item = self:get_cache(role_uuid)
    if item ~= nil then
        return item
    end
    
    local obj = data
    obj.role_uuid = role_uuid
    
    item = Base.new(obj,role_uuid)

    self:add_cache(item)
    return item
end

return BaseMgr
