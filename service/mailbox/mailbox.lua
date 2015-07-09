local Cache = require 'cache'
local Loader = require 'mongo_loader'

local MailBox = class(Cache)

function MailBox:ctor(obj,role_uuid)
    self.role_uuid = role_uuid
end

function MailBox:_save()
    return Loader.save_mailbox(self.role_uuid, self:get_obj()) 
end

function MailBox:get_id()
    return self.role_uuid
end

return MailBox
