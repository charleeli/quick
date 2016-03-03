local Utf8 = require "utf8"
local Const = require 'const'
local class = require 'pl.class'
local MailBox = class()

function MailBox:_init(mailbox_td,mail_pcount,mail_scount)
    assert(mailbox_td, "new mailbox has no mailbox_td")
    self.mailbox = mailbox_td
    self.mail_pcount = mail_pcount
    self.mail_scount = mail_scount
end

function MailBox:get_mailbox()
    return self.mailbox
end

function MailBox:gen_proto()
    local obj = self:get_mailbox()
    
    local private_mails, system_mails = {}, {}
    
    for uuid, mail in pairs(obj.private_mails) do
        table.insert(private_mails, mail)
    end
    
    for uuid, mail in pairs(obj.system_mails) do
        table.insert(system_mails, mail)
    end
    
    return { 
        private_mails = private_mails,
        system_mails = system_mails,
        update_time = obj.update_time,
    }
end

function MailBox:get_mail(mail_uuid, mail_type)
    if type(mail_uuid)~="string" or type(mail_type) ~= "number" then
        return nil
    end
    
    local mailbox = self:get_mailbox()
    
    if mail_type == Const.MAIL_TYPE_SYSTEM then
       return mailbox.system_mails[mail_uuid]
    elseif mail_type == Const.MAIL_TYPE_PRIVATE then
       return mailbox.private_mails[mail_uuid]
    else
       return nil
    end
end

local function _arrange_pl(mail_type, pm)
    local new_pl = {}

    if mail_type == Const.MAIL_TYPE_PRIVATE then
        for id, mail in pairs(pm) do
            table.insert(new_pl, mail)
        end
    elseif mail_type == Const.MAIL_TYPE_SYSTEM then
        for id, mail in pairs(pm) do
           if Utf8.len(mail.attachment) ~= 0 then
             table.insert(new_pl, mail)
           end
        end
    end
    
    table.sort(new_pl, function(x, y) return x.create_time < y.create_time end)

    return {table.unpack(new_pl)}
end

function MailBox:delete_mail(mail_uuid, mail_type)
    if type(mail_uuid)~="string" or type(mail_type) ~= "number" then
        LOG_ERROR("delete mail error, reason: param error")
        return { errcode = ERRNO.E_ARGS }
    end

    local mailbox = self:get_mailbox()
    
    if mail_type == Const.MAIL_TYPE_PRIVATE then
        local pm = mailbox.private_mails
   
        if pm[mail_uuid] then
            pm[mail_uuid] = nil
            self.mail_pcount = self.mail_pcount -1
        end
    elseif mail_type == Const.MAIL_TYPE_SYSTEM then
        local sm = mailbox.system_mails
        
        if sm[mail_uuid] then
            sm[mail_uuid] = nil
            self.mail_scount = self.mail_scount -1
        end
    end
    
    return { errcode = ERRNO.E_OK }
end

function MailBox:delete_mails(mail_uuid_list, mail_type)
    if type(mail_uuid)~="string" or type(mail_type) ~= "number" then
          LOG_ERROR("delete mails error, reason: param error")        
          return { errcode = ERRNO.E_ARGS }
    end
  
    for _, mail_uuid in ipairs(mail_uuid_list) do
        self:delete_mail(mail_uuid, mail_type)
    end

    return {errcode = ERRNO.E_OK}
end

--删除c个mail_type型最老邮件
function MailBox:delete_old_mails(mail_type,c)
    local mailbox = self:get_mailbox()
    
    if mail_type == Const.MAIL_TYPE_PRIVATE then
        local pm = {}
        for k,v in pairs(mailbox.private_mails) do
            table.insert(pm,v)
        end
        
        if c >= #pm then
            mailbox.private_mails = {}
            self.mail_pcount = 0
            return 
        end

        local pl = _arrange_pl(mail_type, pm)
        pm = {table.unpack(pl,c+1)}
        self.mail_pcount = self.mail_pcount - c
        
        mailbox.private_mails = {}
        for k,v in ipairs(pm) do 
            mailbox.private_mails[v.uuid] = v
        end
 
    elseif mail_type == Const.MAIL_TYPE_SYSTEM then
        local sm = {}
        for k,v in pairs(mailbox.system_mails) do
            table.insert(sm,v)
        end
        
        if c >= #sm then
            mailbox.system_mails = {}
            self.mail_scount = 0
            return 
        end
        
        local pl = _arrange_pl(mail_type, sm)
        sm = {table.unpack(pl,c+1)}
        self.mail_scount = self.mail_scount - c
        
        mailbox.system_mails = {}
        for k,v in ipairs(sm) do 
            mailbox.system_mails[v.uuid] = v
        end
    end
end

function MailBox:add_mails(mail_type, add_mails)
    local mailbox = self:get_mailbox()
    
    local c = #add_mails
    self:delete_old_mails(mail_type,c)
    
    if mail_type == Const.MAIL_TYPE_PRIVATE then
        local pm = mailbox.private_mails
        for i = 1, c do
            local uuid = add_mails[i].uuid
            pm[uuid] = add_mails[i]
        end
    elseif mail_type == Const.MAIL_TYPE_SYSTEM then
        local sm = mailbox.system_mails
        for i = 1, c do
            local uuid = add_mails[i].uuid
            sm[uuid] = add_mails[i]
        end
    end
end

return MailBox
