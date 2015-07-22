local Room = require 'room'

local RoomMgr = class()

function RoomMgr:ctor()
    self.room_list = {}     --房间列表
    self.dispatch_id = 1    --房间号分配 
end

function RoomMgr:dtor()
end

function RoomMgr:new_room()
    local r = Room.new(self.dispatch_id)
    self.room_list[self.dispatch_id] = r
    self.dispatch_id = self.dispatch_id + 1
    return r
end

function RoomMgr:del_room(room_id)
    self.room_list[room_id] = nil
end

function RoomMgr:get_room(room_id)
    return self.room_list[room_id]
end

function RoomMgr:get_room_list()
    return self.room_list
end

return RoomMgr
