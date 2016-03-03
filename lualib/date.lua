local skynet = require "skynet"

local starttime = skynet.starttime()

local date = {}

local TZ = tonumber(skynet.getenv("TZ")) or 8
local TD =  TZ * 3600

function date.now()
    return Skynet.now()/100 + starttime
end

function date.second()
    return math.floor(skynet.now()/100) + starttime
end

function date.format(sec, ms)
    local f = os.date("%Y-%m-%d %H:%M:%S",sec)
    if ms then
        f = string.format("%s.%02d",ms)
    end
    return f
end

function date.localtime(time)
    local t = time or date.second()
    return os.date("!*t", t + TD)
end

function date.get_today_time(hour, min, sec)
    local dt = date.localtime()
    dt.hour = hour or 0
    dt.min = min or 0
    dt.sec = sec or 0
    return os.time(dt)
end

return date
