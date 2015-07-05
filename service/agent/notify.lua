local Env = require 'global'
local Quick = require 'quick'

local function _send(proto, ...)
    if Env.zinc_client then
        Quick.notify(Env.zinc_client, proto, ...)
    end
end

local M = {}

function M.chat(msg)
    if not Env.role then return end
    _send('chat', {chats = {msg}})
end

return M
