local LobbyClient = require 'client.lobby'

local apis = {}

function apis:create_room()
    return LobbyClient.create_room(self:get_uuid())
end

function apis:enter_room(room_id)
    return LobbyClient.enter_room(self:get_uuid(), room_id)
end

function apis:exit_room()
    return LobbyClient.exit_room(self:get_uuid())
end

function apis:show_all_rooms()
    return LobbyClient.show_all_rooms()
end

function apis:show_room_detail(room_id)
    return LobbyClient.show_room_detail(room_id)
end

local triggers = {

}

return {apis = apis, triggers = triggers}

