local Skynet = require "skynet"
local Date   = require "date"

local mt = {}
mt.__index = mt

function mt:add_timer(interval, func, immediate, times)
    assert(interval >= self.check_interval, interval)
    local handle = self.handle
    self.handle = handle + 1

    self.pending[handle] = {interval = interval, 
        func = func, 
        wakeup = immediate and 0 or interval,
        times = times or 0,
        timestamp = Date.second(),
    }
    return handle
end

function mt:remove_timer(handle)
    self.to_deleted[handle] = true
end

function mt:update()
    for k,v in pairs(self.pending) do
        self.timers[k] = v
    end
    for k,_ in pairs(self.to_deleted) do
        self.timers[k] = nil
    end
    local second = Date.second()
    for k,v in pairs(self.timers) do
        local interval = second - v.timestamp
        if v.wakeup <= interval then
            v.wakeup = v.wakeup + v.interval
            local ok, err = pcall(v.func)
            if not ok then
                LOG_ERROR("time mgr update err<%s>", err)
            end
            if v.times > 0 then
                if v.times == 1 then
                    self:remove_timer(k)
                else
                    v.times = v.times - 1
                end
            end
        end
    end
end

function mt:start()
    if self.running then
        return
    end
    self.running = true
    self.timestamp = Date.second()
    Skynet.fork(function ()
        while self.running do
            self:update()
            Skynet.sleep(self.check_interval * 100)
        end
    end)
    return
end

function mt:stop()
    self.running = false
end

local M = {}

function M.new(check_interval)
    local obj = {}
    obj.running = false
    obj.timestamp = 0
    obj.check_interval = check_interval
    obj.handle = 1
    obj.to_deleted = {}
    obj.pending = {}
    obj.timers = {}
    return setmetatable(obj, mt)
end

return M

