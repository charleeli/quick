Base {
    uid integer          #quick游服账号，来自登陆系统mysql自增
    name string         #姓名
    gender integer       #性别
    exp integer          #经验
    level integer        #等级
    vip integer          #VIP
    coupon integer       #点券 需用人民币购买
    gold integer         #金币 用点券购买或游戏内获得
    sign_score integer   #签到积分
    daily_update_time integer #每日更新时间戳
}
