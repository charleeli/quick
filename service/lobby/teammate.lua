local TeamMate = class()

function TeamMate:ctor(uuid, time)
    self.uuid = uuid        --队友uuid
    self.lefthp = nil       --剩余血量
    self.use_medicine = nil --使用药水
    self.star_map = nil     --星级条件表
    self.begin_time = time  --开始时间
    self.finish_time = nil  --结束时间
    self.drop = {}          --战斗掉落
end

function TeamMate:dtor()
end

function TeamMate:finish(time)--设置结束时间
    self.finish_time = time
end

return TeamMate
