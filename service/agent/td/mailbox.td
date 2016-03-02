Mail {
    uuid string             #邮件自己的uuid
    type integer             #邮件类型
    sub_type integer         #用在发送agent邮件时填充邮件标题使用
    to_uuid string          #收件人
    from_account string     #发件人账号
    from_uuid string        #发件人
    subject string          #邮件标题
    content string          #邮件正文
    attachment string       #附件
    create_time integer      #发送时间
    is_read boolean         #是否已读 
}

MailBox {
    role_uuid string                #角色自己的uuid
    private_mails <string, Mail>    #个人邮件
    system_mails <string, Mail>     #系统邮件
}
