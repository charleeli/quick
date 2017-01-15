local class = require 'pl.class'
local snax = require "snax"
local td = require 'td'
local CacheMgr = require 'cache_mgr'
local Mailbox = require 'mailbox.mailbox'

local MailboxMgr = class(CacheMgr)

function MailboxMgr:get_item(role_uuid)
    if not role_uuid or type(role_uuid) ~= "string" then
        return nil
    end
    
    local item = self:get_cache(role_uuid)
    if item ~= nil then
        return item
    end

    local mailboxdb_snax = snax.uniqueservice("mailboxdb_snax")
    local raw_json_text = mailboxdb_snax.req.get('Mailbox:'..role_uuid)

    local data
    if raw_json_text then
        data =  td.LoadFromJSON('Mailbox',raw_json_text)
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
    
    item = Mailbox(td.LoadFromLUA('Mailbox',obj),role_uuid)

    self:add_cache(item)
    return item
end

return MailboxMgr
