local Env = require 'global'

function view_sign(args)
    return Env.role:view_sign()
end

function sign_in(args)
    return Env.role:sign_in()
end

function resign(args)
    return Env.role:resign()
end

function full_duty(args)
    return Env.role:full_duty()
end
