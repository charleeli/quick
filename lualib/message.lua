local class = require 'pl.class'
local Message = class()

function Message:_init()
    self._handlers = {}
end

function Message:sub(topic, handler)
    assert(handler)
    local handlers = self._handlers[topic]
    if handlers == nil then
        self._handlers[topic] = {handler}
        return
    end
    for _,v in ipairs(handlers) do
        if v == handler then
            return
        end
    end
    table.insert(handlers, handler)
end

function Message:unsub(topic, handler)
    assert(handler)
    local handlers = self._handlers[topic]
    assert(handlers)
    for i,v in ipairs(handlers) do
        if v == handler then
            table.remove(handlers, i) 
            return
        end
    end
end

function Message:pub(topic, ...)
    local handlers = self._handlers[topic]
    if handlers == nil then
        return
    end
    for _,func in ipairs(handlers) do
        local ok, msg = pcall(func, ...)
        if not ok then
            LOG_ERROR("error:<%s>, traceback:<%s>", msg, debug.traceback())
        end
    end
end

return Message
