local Skynet  = require "skynet"
local Lcrab = require 'crab'
local Bson   = require 'bson'
local Date    = require "date"
local Const   = require "const"
local Quick = require 'quick'

local _call_mailbox = Quick.caller('mailbox')

local _send_mailbox = function(...) Skynet.fork(_call_mailbox, ...) end

local M = {}

function M.send_system_mail(to_uuid, subject, content, attachment)
    local _,new_uuid = Bson.type(Bson.objectid())
    
    local mailobj = {
        uuid = new_uuid,
        type = Const.MAIL_TYPE_SYSTEM,
        to_uuid = to_uuid, 
        subject = subject, 
        content = content, 
        attachment = attachment,
        create_time = Date.second(),
        is_read = false
    }

    _send_mailbox('send_mail', 'system', mailobj)
    
    LOG_INFO("send_system_mail to_uuid = %s",to_uuid)
end

function M.send_private_mail(to_uuid, from_account, from_uuid, subject, content)
    local _,new_uuid = Bson.type(Bson.objectid())
    
    local mailobj = {
        uuid = new_uuid,
        type = Const.MAIL_TYPE_PRIVATE,
        to_uuid = to_uuid,
        from_account = from_account,
        from_uuid = from_uuid, 
        subject = subject,
        content = content,
        create_time = Date.second(),
        is_read = false
    }
  
    _send_mailbox('send_mail', 'private', mailobj) 
    
    LOG_INFO("send_private_mail to_uuid=%s,from_uuid=%s",to_uuid,from_uuid)
end

function M.pull_mails(role_uuid)
    return _call_mailbox('pull_mails', role_uuid)
end

return M

