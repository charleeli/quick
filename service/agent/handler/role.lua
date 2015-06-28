local Env = require 'global'
local Const = require 'const'
local RoleApi = require 'apis.role_api'

function load_role(args)
    return RoleApi.apis.load_role()
end

function gm(args)
    if not Env.role then
        LOG_ERROR('<%s> exec gm without role', Env.account)
        return {errcode = Const.ERROR}
    end
    
    return Env.role:gm(args.cmd)
end
