local Env = require 'env'

function send_private_chat(args)
    return Env.role:send_private_chat(args.uuid, args.msg)
end

function send_world_chat(args)
    return Env.role:send_world_chat(args.msg)
end
