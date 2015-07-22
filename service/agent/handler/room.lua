local Env = require 'global'

function create_room(args)
    return Env.role:create_room()
end

function enter_room(args)
    return Env.role:enter_room(args.room_id)
end

function exit_room(args)
    return Env.role:exit_room()
end

function show_all_rooms(args)
    return Env.role:show_all_rooms()
end

function show_room_detail(args)
    return Env.role:show_room_detail(args.room_id)
end
