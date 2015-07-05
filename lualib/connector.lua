local Skynet = require 'skynet'

local STAT_NONE = 0         
local STAT_CONNECTED = 1   

local Connector = class()

function Connector:ctor(connect_cb, connected_cb, disconnect_cb, reconnect_wait)
    self.useable = true
    self.status = STAT_NONE
    self.connect_cb = connect_cb
    self.connected_cb = connected_cb
    self.disconnect_cb = disconnect_cb
    self.reconnect_wait = reconnect_wait or 3
end

function Connector:dtor()
end

function Connector:set_status_none()
    self.status = STAT_NONE
end

function Connector:set_status_connected()
    self.status = STAT_CONNECTED
end

function Connector:is_connected()
    return self.status == STAT_CONNECTED
end

function Connector:stop()
    self.useable = false
end

function Connector:connect()
    local delay = 0
    if self:is_connected() then 
        delay = -1
    end

    local ret = self.connect_cb(delay)
    if ret.errcode ~= ERRNO.E_OK then
        if self:is_connected() and self.disconnect_cb then
            pcall(self.disconnect_cb)
        end
        self:set_status_none()
        LOG_ERROR("remote service disconnecting, errcode<%s>", ret.errcode)
        return false
    end

    if self:is_connected() then
        return true
    end

    LOG_INFO("remote service connected, init begin")
    if self.connected_cb then
        local ok, suc = pcall(self.connected_cb)
        if not ok then
            LOG_ERROR("remote service connected, init fail<%s>", suc)
        end
        
        if not suc then
            LOG_ERROR("remote service connected, init fail<%s>", suc)
            return false
        end
    end

    self:set_status_connected()
    LOG_INFO("remote service connected, init end")
    return true
end

function Connector:start()
    self:set_status_none()
    Skynet.fork(function()
        while self.useable do
            if not self:connect() then
                Skynet.sleep(self.reconnect_wait * 100)
            end
        end
    end)
end

return Connector

