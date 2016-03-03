Role {
    uid integer     #quick游服账号，来自登陆系统accountdb自增
    account string  #第三方平台账号，没有时即为tostring(uid)
    uuid string     #由bson产生的唯一ID，方便索引查询
    base Base       #角色的基本信息
    sign Sign       #每月累计签到信息
    mailbox Mailbox #邮箱
}
