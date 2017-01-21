local skynet = require 'skynet'
local quick  = require 'quick'
local const  = require 'const'
local date   = require 'date'
local env    = require 'env'

local _send_speaker = function(...)
    local _call_speaker = quick.caller('chat_speaker')
    skynet.fork(_call_speaker, ...)
end

local _call_listener = function (cmd, ...)
    return skynet.call('.chat_listener', 'lua', cmd, ...)
end

local _send_listener = function (cmd, ...)
    skynet.send('.chat_listener', 'lua', cmd, ...)
end

local M = {}

function M.send_world(uuid, message)
    _send_speaker('world', uuid, message)
end

function M.send_private(uuid, to_uuid, message)
    _send_speaker('private', uuid, to_uuid, message)
end

function M.send_system(plain_text, sub_type)
    _send_speaker('system', {
        type = const.CHAT_TYPE_SYSTEM,
        sub_type = sub_type,
        uuid = const.NoneUUID,
        name = "",
        time = date.second(),
        msg = plain_text,
    })
end

function M.subscribe(uuid)
    _send_listener('subscribe', uuid, skynet.self(), env.zinc_client)
end

function M.unsubscribe(uuid)
    _send_listener('unsubscribe', uuid)
end

return M
