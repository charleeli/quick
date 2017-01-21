local env = require 'env'

function send_private_chat(args)
    return env.role:send_private_chat(args.uuid, args.msg)
end

function send_world_chat(args)
    return env.role:send_world_chat(args.msg)
end
