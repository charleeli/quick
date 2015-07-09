local Env = require 'global'
local Quick = require 'quick'

local function _send(proto, ...)
    if Env.zinc_client then
        Quick.notify(Env.zinc_client, proto, ...)
    end
end

local M = {}

function M.daily_update()
    if not Env.role then return end
    _send('daily_update')
end

function M.chat(msg)
    if not Env.role then return end
    _send('chat', {
        chats = {msg}
    })
end

function M.mail(private_mails, system_mails)
    if not Env.role then return end
    _send('mail', {
        private_mails = private_mails, 
        system_mails = system_mails
    })
end

return M
