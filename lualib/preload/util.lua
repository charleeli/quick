local skynet = require "skynet"

function LOG_DEBUG(fmt, ...)
    local msg = string.format(fmt, ...)
    local info = debug.getinfo(2)
    if info then
        msg = string.format("[%s:%d] %s", info.short_src, info.currentline, msg)
    end
    skynet.send("log", "lua", "debug", SERVICE_NAME, msg)
end

function LOG_INFO(fmt, ...)
    local msg = string.format(fmt, ...)
    local info = debug.getinfo(2)
    if info then
        msg = string.format("[%s:%d] %s", info.short_src, info.currentline, msg)
    end
    skynet.send("log", "lua", "info", SERVICE_NAME, msg)
end

function LOG_WARN(fmt, ...)
    local msg = string.format(fmt, ...)
    local info = debug.getinfo(2)
    if info then
        msg = string.format("[%s:%d] %s", info.short_src, info.currentline, msg)
    end
    skynet.send("log", "lua", "warning", SERVICE_NAME, msg)
end

function LOG_ERROR(fmt, ...)
    local msg = string.format(fmt, ...)
    local info = debug.getinfo(2)
    if info then
        msg = string.format("[%s:%d] %s", info.short_src, info.currentline, msg)
    end
    skynet.send("log", "lua", "error", SERVICE_NAME, msg)
end

function LOG_FATAL(fmt, ...)
    local msg = string.format(fmt, ...)
    local info = debug.getinfo(2)
    if info then
        msg = string.format("[%s:%d] %s", info.short_src, info.currentline, msg)
    end
    skynet.send("log", "lua", "fatal", SERVICE_NAME, msg)
end
