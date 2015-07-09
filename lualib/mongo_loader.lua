local skynet = require "skynet"
local factory = require 'factory'

local M = {}
M.TYPE_ROLE = 'Role'
M.TYPE_MAIL = 'Mail'

local RoleTable = 'role'
local MailboxTable = 'mailbox'

local function _call(op, ...)
    return skynet.call('.gamedb', 'lua', op, ...)
end

--role
function M.has_role(uuid)
    local data = _call('find_one', RoleTable, {uuid=uuid}, {uuid=true})
    return data ~= nil
end

function M.load_role(account)
    local data = _call('find_one', RoleTable, {account=account})
    if not data then return nil end
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

--mailbox
function M.load_mailbox(role_uuid)
    local data = _call('find_one', MailboxTable, {role_uuid = role_uuid})
    if not data then return nil end
    return data
end

function M.create_mailbox(role_uuid, obj)
    return _call('insert', MailboxTable, obj)
end

function M.save_mailbox(role_uuid, obj)
    if M.load_mailbox(role_uuid) then
        return _call('update', MailboxTable, {role_uuid = role_uuid}, obj)
    else
        return _call('insert', MailboxTable, obj)
    end
end

return M
