local Skynet = require "skynet"
local Env = require 'global'
local Const = require 'const'

local apis = {}

function apis:gm(cmd)
    assert(Skynet.getenv('test_environment'))
    
    local base_ops = {
        ['set'] = true,
        ['add'] = true,
    }
    
    LOG_INFO('run gm cmd<%s>', cmd)
    local errcode = Const.OK
    local errdata = ""
    local base = {}
    
    local it = cmd:gmatch('[{}=,_%w]+')
    local op = it()
    
    if base_ops[op] then
        local name = it()
        local val = tonumber(it())
        if val > 0x7fffffff then
            return {errcode = Const.ERROR, errdata = "val is too large"}
        end

        local func = self[op .. '_'.. name]
        if not func then
            return {errcode = Const.ERROR, errdata = "no request handler"}
        end

        local ok, ret = pcall(func, self, val)
        if ok then
            errcode = ret.errcode
            base = ret.base
        else
            errcode = Const.ERROR
            errdata = ret
        end
        return {errcode = errcode, errdata = errdata, base = base}
    end
    
    return {errcode = Const.ERROR, errdata = "illegal op"}
end

local triggers = {
}

return {apis = apis, triggers = triggers}
