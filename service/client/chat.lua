local Skynet = require "skynet"
local Quick = require 'quick'
local Const = require 'const'
local Date = require 'date'
local Env   = require "global"

local _send_speaker = function(...)
    local _call_speaker = Quick.caller('chat_speaker')
    Skynet.fork(_call_speaker, ...)
end

local _call_listener = function (cmd, ...)
    return Skynet.call('.chat_listener', 'lua', cmd, ...)
end

local _send_listener = function (cmd, ...)
    Skynet.send('.chat_listener', 'lua', cmd, ...)
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
        type = Const.CHAT_TYPE_SYSTEM,
        sub_type = sub_type,
        uuid = Const.NoneUUID,
        name = "",
        time = Date.second(),
        msg = plain_text,
    })
end

function M.subscribe(uuid)
    _send_listener('subscribe', uuid, Skynet.self(), Env.zinc_client)
end

function M.unsubscribe(uuid)
    _send_listener('unsubscribe', uuid)
end

return M
