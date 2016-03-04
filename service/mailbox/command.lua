local Skynet = require "skynet"
local Env = require "env"
local Date = require "date"
local Const = require 'const'
local pretty = require 'pl.pretty'
local td = require 'td'

local M = {}

function M.send_mail(mail_type, mailobj)
    if mail_type ~= "system" and mail_type ~= "private" then
        Skynet.retpack({errcode = ERRNO.E_ERROR})
        return 
    end
    
    local to_uuid = mailobj.to_uuid
    local mail_uuid = mailobj.uuid

    local m = Env.mailbox_mgr:get_item(to_uuid)
    if not m then
       Skynet.retpack({errcode = ERRNO.E_ERROR}) 
    end

    local mailbox = m:get_obj()
    if not mailbox then
        Skynet.retpack({errcode = ERRNO.E_ERROR})
    end
    
    local mail_key = mail_type.."_mails"
    mailobj.create_time = Date.second()
    
    -- 如果邮箱中未取出的邮件数量已经超限，不予存储
    if #mailbox[mail_key] >= Const.MAIL_CACHE_LIMIT then
        LOG_ERROR("send mail failed, reason: too many mail unread")
        Skynet.retpack({errcode = ERRNO.E_ERROR})
        return 
    end
   
    table.insert(mailbox[mail_key], mailobj)

    --print(mailbox)

    Skynet.retpack({errcode = ERRNO.E_OK})
end

function M.pull_mails(role_uuid)
    local m = Env.mailbox_mgr:get_item(role_uuid)
    --print(m)
    if not m then
        Skynet.retpack({private_mails= {}, system_mails = {}})
        return
    end
    
    local mailbox = m:get_obj()
    
    local ret_p_mails, ret_s_mails = {}, {}
    
    local system_mails, private_mails = {}, {}
    system_mails = mailbox.system_mails
    private_mails = mailbox.private_mails
    
    local p, s = 0, 0
    for _, mail in ipairs(private_mails) do
        if Date.second() - mail.create_time < Const.MAIL_EXPIRE_TIME then
            table.insert(ret_p_mails, mail)
            p = p+1
            -- 限制返回的私人邮件不能多于邮箱上限
            if p >=Const.MAILBOX_LIMIT then
                break
            end
        end
    end
    
    local tmp = {table.unpack(private_mails, p+1)}
    mailbox.private_mails = tmp
    
    for _, mail in ipairs(system_mails) do
        if Date.second() - mail.create_time < Const.MAIL_EXPIRE_TIME then
            table.insert(ret_s_mails, mail)
            s = s+1
            if s >= Const.MAILBOX_LIMIT then
                break
            end
        end
    end
    tmp = {table.unpack(system_mails, s+1)}
    mailbox.system_mails = tmp

    --print(ret_p_mails)
    Skynet.retpack{ 
        private_mails = ret_p_mails,
        system_mails = ret_s_mails,
    }
end

function M.on_exit()
    LOG_INFO("shutdown mailbox service")
    Env.mailbox_mgr:exit()
end

return M
