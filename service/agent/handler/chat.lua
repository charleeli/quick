local Env = require 'global'

function send_private_chat(args)
    return Env.role:send_private_chat(args.uuid, args.msg)
end

function send_world_chat(args)
    print('handler args.msg = ',args.msg)
    return Env.role:send_world_chat(args.msg)
end
