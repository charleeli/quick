local class = require 'pl.class'
local Cache = require 'cache'
local snax = require 'snax'
local td = require 'td'

local Mailbox = class(Cache)

function Mailbox:_init(obj,role_uuid)
    self._obj = obj
    self.role_uuid = role_uuid
end

function Mailbox:_save()
    local mailboxdb_snax = snax.uniqueservice("mailboxdb_snax")
    mailboxdb_snax.req.set('Mailbox:'..self.role_uuid, td.DumpToJSON('Mailbox', self:get_obj()))
end

function Mailbox:get_id()
    return self.role_uuid
end

return Mailbox
