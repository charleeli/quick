local Skynet = require 'skynet'

local _send_ranking = function(api, ...)
    local ok, ret = pcall(Skynet.send, '.ranking', "lua", api, ...)
    if ok then return ret end
    return {errcode = ERRNO.E_SERVICE_UNAVAILABLE, errdata=ret}
end

local M = {}

function M.zadd(...)
    return _send_ranking('zadd', ...)
end

return M
