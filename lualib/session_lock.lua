local Lock = require "lock"

SessionLock = class()

function SessionLock:ctor()
    self.quit = false
    self.lock = Lock.new()
    self.pending = {}
end

function SessionLock:dtor()
end

function SessionLock:lock_session(reason, f, ...)
    assert(type(reason) == "string")

    if self.quit then
        return false
    end

    local co = coroutine.running()
    self.pending[co] = reason

    local function filter(...)
        self.pending[co] = nil
        return true, ...
    end
    return filter(self.lock:lock_func(f, ...))
end

function SessionLock:lock_quit()
    self.quit = true

    for _, reason in pairs(self.pending) do
        LOG_ERROR("pending lock:", reason)
    end
    self.lock:lock()
end

return SessionLock

