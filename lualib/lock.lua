local Skynet = require "skynet"
local class = require 'pl.class'

local Lock = class()

function Lock:_init()
    self.locked = false
    self.lock_count = 0
    self.lock_waiter = {}
end

function Lock:_lock(co)
    assert(self.locked == false)
    self.locked = co
    self.lock_count = 1
end

function Lock:lock()
    local co = coroutine.running()
    if self.locked == co then
        self.lock_count = self.lock_count + 1
        return
    end

    if not self.locked then
        self:_lock(co)
        return
    end
    table.insert(self.lock_waiter, co)
    Skynet.wait()
    assert(self.locked == co)
end

function Lock:unlock()
    local co = coroutine.running()
    assert(self.locked == co)
    self.lock_count = self.lock_count - 1
    if self.lock_count > 0 then
        return
    end
    self.locked = false
    self.lock_count = nil

    local co = table.remove(self.lock_waiter, 1)
    if co then
        self:_lock(co)
        Skynet.wakeup(co)
    end
end

function Lock:lock_func(func, ...)
    self:lock()
    local ret = { xpcall(func, debug.traceback, ...) }
    self:unlock()
    assert(ret[1], "in lock:" .. tostring(ret[2]))
    return table.unpack(ret, 2)
end

return Lock
