Base {
    uid integer          #quick游服账号，来自登陆系统accountdb自增
    uuid string          #uuid
    name string          #姓名
    gender integer       #性别
    exp integer          #经验
    level integer        #等级
    vip integer          #VIP
    daily_update_time integer
}
