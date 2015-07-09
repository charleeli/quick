local CacheMgr = require 'cache_mgr'
local Loader = require 'mongo_loader'
local MailBox = require 'mailbox.mailbox'

local MailBoxMgr = class(CacheMgr)

function MailBoxMgr:get_item(role_uuid)
    if not role_uuid or type(role_uuid) ~= "string" then
        return nil
    end
    
    local item = self:get_cache(role_uuid)
    if item ~= nil then
        return item
    end

    local data = Loader.load_mailbox(role_uuid)
    if not data then
        if not Loader.has_role(role_uuid) then 
            return nil
        end
    end
    
    item = self:get_cache(role_uuid)
    if item ~= nil then
        return item
    end
    
    local obj
    if not data then
        obj = {
            private_mails = {},
            system_mails = {},
        }
    else 
        obj = {
            private_mails = data.private_mails,
            system_mails = data.system_mails,
        }
    end
    
    obj.role_uuid = role_uuid
    
    item = MailBox.new(obj,role_uuid)

    self:add_cache(item)
    return item
end

return MailBoxMgr

