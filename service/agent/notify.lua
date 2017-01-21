local env = require 'env'
local quick = require 'quick'

local function _send(proto, ...)
    if env.zinc_client then
        quick.notify(env.zinc_client, proto, ...)
    end
end

local M = {}

function M.daily_update()
    if not env.role then return end
    _send('daily_update')
end

function M.chat(msg)
    if not env.role then return end
    _send('chat', {
        chats = {msg}
    })
end

function M.mail(private_mails, system_mails)
    if not env.role then return end
    _send('mail', {
        private_mails = private_mails, 
        system_mails = system_mails
    })
end

return M
