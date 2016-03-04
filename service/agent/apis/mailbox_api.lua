local Utf8 = require "utf8"
local Date = require 'date'
local Bson = require 'bson'
local Lcrab = require 'crab'
local Const = require 'const'
local Notify = require 'notify'
local td = require 'td'
local Mailbox = require 'cls.mailbox'
local MailboxClient = require 'client.mailbox'

local function _check_message(subject, content)
   local subject_len = Utf8.len(subject)
   local content_len = Utf8.len(content)

   if not subject_len or not content_len then
        return ERRNO.E_ERROR, "mail illegal"
   end
   
   if subject_len > Const.MAIL_SUBJECT_LIMIT then
        return ERRNO.E_SUBJECT_LONG, "mail subject too long"
   end
   
   if content_len > Const.MAIL_CONTENT_LIMIT then
        return ERRNO.E_CONTENT_LONG, "mail content too long"
   end
   
   if not Lcrab.is_crabbed(subject) then
        return ERRNO.E_CONTENT_SENSITIVE, "subject sensitive : "..subject
   end
   
   if not Lcrab.is_crabbed(content) then
        return ERRNO.E_CONTENT_SENSITIVE, "content sensitive: "..content
   end
   
   return ERRNO.E_OK 
end

local apis = {}

function apis:init_mailbox()
    local mail_pcount = 0
    local mail_scount = 0
    
    for _,_ in pairs(self._role_td.mailbox.private_mails) do
        mail_pcount = mail_pcount +1
    end
    
    for _, _ in pairs(self._role_td.mailbox.system_mails) do
        mail_scount = mail_scount +1
    end
    
    self.mailbox = Mailbox(self._role_td.mailbox,mail_pcount,mail_scount)
end

function apis:send_private_mail(to_uuid, subject, content)
    local errcode, detail = _check_message(subject, content)
    if errcode ~= ERRNO.E_OK then
        LOG_ERROR("send private mail error, reason: %s", detail)
        return { errcode = errcode }
    end
    
    MailboxClient.send_private_mail(
        to_uuid, self:get_account(), self:get_uuid(), subject, content
    )
    
    return { errcode = ERRNO.E_OK }
end

function apis:read_mail(mail_uuid, mail_type)
    local mail = self.mailbox:get_mail(mail_uuid, mail_type)
    if not mail then
        LOG_ERROR("read mail failed, reason: param error/mail not exist")
        return { errcode = ERRNO.E_ARGS }
    end
    
    mail.is_read = true
    
    return { errcode = ERRNO.E_OK }
end

function apis:send_agent_mail(sub_type, attachment, subject, content)
    local mailobj = td.CreateObject('Mail')
    local _,new_uuid = Bson.type(Bson.objectid())
    
    mailobj.uuid = new_uuid
    mailobj.type = Const.MAIL_TYPE_SYSTEM 
    mailobj.sub_type = sub_type
    mailobj.attachment = attachment
    mailobj.is_read = false 
    mailobj.create_time = Date.second()
    
    if subject then
        mailobj.subject = subject
    end
    
    if content then
        mailobj.content = content
    end
    
    self.mailbox:add_mails(mailobj.type, {mailobj})
    
    Notify.mail({}, {mailobj})
    
    return { errcode = ERRNO.E_OK }
end

function apis:get_mailbox()
    return { mailbox = self.mailbox:gen_proto() }
end

function apis:delete_mail(mail_uuid, mail_type, safe)
    if not safe then
        LOG_ERROR("delete mail error, reason: safe error")
        return { errcode = ERRNO.E_ARGS }
    end
    
    return self.mailbox:delete_mail(mail_uuid, mail_type)
end

function apis:delete_mails(mail_uuid_list, mail_type, safe)
    if not safe then
        LOG_ERROR("delete mails error, reason: safe error")        
        return { errcode = ERRNO.E_ARGS }
    end
  
    for _, mail_uuid in ipairs(mail_uuid_list) do
        self:delete_mail(mail_uuid, mail_type, true)
    end

    return {errcode = ERRNO.E_OK}
end

function apis:clear_month_mails()
    local mailbox = self.mailbox:get_mailbox()
    local pr, sr = {}, {}

    for mail_uuid, mail in pairs(mailbox.private_mails) do
        if Date.second() - mail.create_time >= Const.MAIL_EXPIRE_TIME then
            table.insert(pr, mail_uuid)
        end
    end
    
    for mail_uuid, mail in pairs(mailbox.system_mails) do
        if Date.second() - mail.create_time >= Const.MAIL_EXPIRE_TIME then
            table.insert(sr, mail_uuid)
        end
    end
    
    for _, mail_uuid in ipairs(pr) do
        mailbox.private_mails[mail_uuid] = nil
    end
    
    for _, mail_uuid in ipairs(sr) do
        mailbox.system_mails[mail_uuid] = nil
    end
end

function apis:update_mailbox()
    local mailbox = self.mailbox:get_mailbox()
  
    local ret = MailboxClient.pull_mails(self:get_uuid())
    if ret.errcode and ret.errcode ~= ERRNO.E_OK then
        return ret.errcode
    end
    
    local add_pmails, add_smails = {}, {}
    
    for _, mail in ipairs(ret.private_mails) do
        table.insert(add_pmails, mail)
    end
    table.sort(add_pmails, function(x, y) 
        return x.create_time < y.create_time 
    end)
    
    for _, mail in ipairs(ret.system_mails) do
        table.insert(add_smails, mail)
    end
    table.sort(add_smails, function(x, y) 
        return x.create_time < y.create_time 
    end)
    
    self.mailbox:add_mails(Const.MAIL_TYPE_PRIVATE, add_pmails)
    self.mailbox:add_mails(Const.MAIL_TYPE_SYSTEM, add_smails)
    
    local pmails, smails = {}, {}
    for _, mail in pairs(mailbox.private_mails) do
        table.insert(pmails, mail)
    end
    
    for _, mail in pairs(mailbox.system_mails) do
        table.insert(smails, mail)
    end
    
    if #smails~=0 or #pmails~=0 then
        Notify.mail(pmails,smails)
    end
    
    return ERRNO.E_OK
end

local triggers = {
    [Const.EVT_ONLINE] = function(self)
        self:init_mailbox()
        return
    end,

    [Const.EVT_OFFLINE] = function(self)
        return
    end,
    
    [Const.EVT_DAILY_UPDATE] = function(self)
        self:clear_month_mails()
        LOG_INFO('daily clear mails a month ago')
    end
}

return {apis = apis, triggers = triggers}
