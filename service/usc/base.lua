local Cache = require 'cache'
local Loader = require 'mongo_loader'

local Base = class(Cache)

function Base:ctor(obj,role_uuid)
    self.role_uuid = role_uuid
end

function Base:_save()
end

function Base:get_id()
    return self.role_uuid
end

return Base
