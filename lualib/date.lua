local Skynet = require "skynet"
local starttime = Skynet.starttime()

local date = {}

local TZ = tonumber(Skynet.getenv("TZ")) or 8
local TD =  TZ * 3600

function date.now()
    return Skynet.now()/100 + starttime
end

function date.second()
    return math.floor(Skynet.now()/100) + starttime
end

function date.client_timestamp()
    return date.second() - 30
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

function date.max_mday(month)
    if month < 1 or month > 12 then
        assert(false,"para err!")
    end

    local max_mdays = {
        [1] = 31,
        [3] = 31,
        [5] = 31,
        [7] = 31,
        [8] = 31,
        [10]= 31,
        [12]= 31,
        [4] = 30,
        [6] = 30,
        [9] = 30,
        [11]= 30,
    }
    
    if month == 2 then
        local now = date.localtime()
        if now.year%100 == 0 then
            if now.year%400 == 0 then
                max_mdays[2] = 29
            else
                max_mdays[2] = 28
            end
        else
            if now.year%4 == 0 then
                max_mdays[2] = 29
            else
                max_mdays[2] = 28
            end
        end
    end

    return max_mdays[month]
end
    
return date
