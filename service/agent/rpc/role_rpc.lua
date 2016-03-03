local Env = require 'env'
local RoleApi = require 'apis.role_api'

function load_role(args)
    return RoleApi.apis.load_role()
end

function gm(args)
    if not Env.role then
        LOG_ERROR('<%s> exec gm without role', Env.account)
        return {errcode = ERRNO.E_ERROR}
    end
    
    return Env.role:gm(args.cmd)
end

--[[
--会话级别安全锁示例
function gm(args)
    return Env.role:lock_session('gm',args.cmd)
end
--]]
