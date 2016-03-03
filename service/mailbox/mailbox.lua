local class = require 'pl.class'
local Cache = require 'cache'

local Mailbox = class(Cache)

function Mailbox:_init(obj,role_uuid)
    self.role_uuid = role_uuid
end

function Mailbox:_save()
    --return Loader.save_mailbox(self.role_uuid, self:get_obj())
end

function Mailbox:get_id()
    return self.role_uuid
end

return Mailbox
