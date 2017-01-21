local env = require 'env'
local role_api = require 'apis.role_api'

function load_role(args)
    return role_api.apis.load_role()
end

function gm(args)
    if not env.role then
        LOG_ERROR('<%s> exec gm without role', env.account)
        return {errcode = ERRNO.E_ERROR}
    end
    
    return env.role:gm(args.cmd)
end

--[[
--会话级别安全锁示例
function gm(args)
    return env.role:lock_session('gm',args.cmd)
end
--]]
