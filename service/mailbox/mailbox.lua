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
    print('+++++++++++++++++++')
    local gamedb_snax = snax.uniqueservice("gamedb_snax")
    gamedb_snax.req.set('Mailbox:'..self.role_uuid,td.DumpToJSON('Mailbox', self:get_obj()))
end

function Mailbox:get_id()
    return self.role_uuid
end

return Mailbox
