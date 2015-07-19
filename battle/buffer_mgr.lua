local lutil = require 'lutil'

READ_TYPE = 0
READ_LENGTH = 1
READ_CONTENT = 2

local buffer = {}

function buffer:new(id)
    local self = {}
    setmetatable(self, {__index = buffer})
    self.id = id
    self.data = ""
    self.state = READ_TYPE
    self.package_readed = 0
    self.need_read = 4
    return self
end

function buffer:add(data)
    self.data = self.data .. data
end

function buffer:read()
    local remain = #self.data - self.package_readed
    if self.need_read > remain then
        self.need_read = self.need_read - remain
        self.package_readed = self.package_readed + remain
        return nil
    else
        while self.need_read <= remain do
            self.package_readed = self.package_readed + self.need_read
            self.need_read = 0
            self.state = (self.state + 1)%3

            if self.state == READ_TYPE then
                local s1 = string.sub(self.data, 1, 4)
                local s2 = string.sub(self.data, 5, 8)
                local s3 = string.sub(self.data, 9, self.package_readed)
                local ret_type = lutil.netbytes2uint32(s1)
                local ret_length = lutil.netbytes2uint32(s2)
                local ret_content = s3
                
                self.data = string.sub(self.data, self.package_readed+1, -1)
                self.need_read = 4
                self.package_readed = 0

                return ret_type, ret_length, ret_content
                
            elseif self.state == READ_LENGTH then
                self.need_read = 4
            else
                local length = string.sub(self.data, 5, 8)
                length = lutil.netbytes2uint32(length)
                self.need_read = length
            end
            remain = #self.data - self.package_readed
        end
    end
    return nil
end

local buffer_mgr = {}

function buffer_mgr:create_buffer(id)
    local b = buffer:new(id)
    buffer[id] = b
    return b
end

function buffer_mgr:remove_buffer(id)
    buffer[id] = nil
end

function buffer_mgr:get_buffer(id)
    return buffer[id]
end

return buffer_mgr

