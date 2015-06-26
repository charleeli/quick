local skynet = require "skynet"
require "skynet.manager"
local factory = require 'factory'

local M = {}
M.TYPE_ROLE = 'Role'

local RoleTable = 'role'

local function _call(op, ...)
    return skynet.call('.gamedb', 'lua', op, ...)
end

function M.has_role(uuid)
    local data = _call('find_one', RoleTable, {uuid=uuid}, {uuid=true})
    return data ~= nil
end

function M.load_role(account)
    local data = _call('find_one', RoleTable, {account=account})
    if not data then
        return nil
    end
    return factory.load_mongo(data, M.TYPE_ROLE)
end

function M.create_role(account, obj)
    local data = factory.dump_mongo(obj, M.TYPE_ROLE)
    return _call('insert', RoleTable, data)
end

function M.save_role(account, obj)
    local data = factory.dump_mongo(obj, M.TYPE_ROLE)
    return _call('update', RoleTable, {account=account}, data)
end

return M
