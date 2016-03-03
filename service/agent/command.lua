local skynet = require "skynet"
local notify = require 'notify'
local env = require 'env'

local M = {}

function M.query_proto_info()
    skynet.retpack(env.role:gen_proto())
end

return M
