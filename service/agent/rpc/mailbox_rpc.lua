local Env = require 'env'

function send_private_mail(args)
    return Env.role:send_private_mail(args.to_uuid, args.subject, args.content)
end

function read_mail(args)
    return Env.role:read_mail(args.mail_uuid, args.mail_type)
end

function delete_mail(args)
    return Env.role:delete_mail(args.mail_uuid, args.mail_type,args.safe)
end

function delete_mails(args)
    return Env.role:delete_mails(args.mail_uuid_list, args.mail_type, args.safe)
end

function get_mailbox(args)
   return Env.role:get_mailbox()
end

function update_mailbox(args)
    --会话级别安全锁示例
    return Env.role:lock_session('update_mailbox',args)
end

