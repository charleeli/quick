local Skynet = require 'skynet'
local Cluster = require 'cluster'
local Const = require 'const'
local Acceptor = require 'acceptor'

local chat_cache = {}
local listeners = {}
local chat_max_buffer = 256

local function _call(node, service, ...)
    if NODE_NAME == node then
        return pcall(Skynet.call, service, 'lua', ...)
    end
    return pcall(Cluster.call, node, service, ...)
end

local Repeater = {}

function Repeater.new_chat(chat_channel, chat_info)
    table.insert(chat_cache[chat_channel], chat_info)
end

function Repeater._dispatch(chat_channel, chat_buffer)
    table.print(listeners)
    
    for node, _ in pairs(listeners) do
        Skynet.fork(function()
            local ok, err = _call(
                node,".chat_listener", 
                "dispatch", chat_channel, chat_buffer
            )

            if not ok then
                LOG_ERROR(
                    "dispatch fail, chat_channel<%s>, node:<%s>, err<%s>",
                    chat_channel, node, err
                )
            end
        end)
    end
end

function Repeater.dispatch(chat_channel)
    local cache = chat_cache[chat_channel]
    chat_cache[chat_channel] = {}

    local max_len = #cache
    if max_len == 0 then
        return false
    end

    local begin_idx = 1
    local buffer_len = chat_max_buffer
    while begin_idx <= max_len do
        local buffer = {
            table.unpack(cache, begin_idx, begin_idx + buffer_len - 1)
        }
        begin_idx = begin_idx + buffer_len
        Repeater._dispatch(chat_channel, buffer)
    end

    return next(chat_cache[chat_channel]) ~= nil
end

function Repeater.start()
    for _, chat_channel in ipairs(Const.CHAT_CHANNEL_KEYS) do
        chat_cache[chat_channel] = {}
        Skynet.fork(function() 
            while true do
                if not Repeater.dispatch(chat_channel) then
                    Skynet.sleep(1 * 100)
                end
            end
        end)
    end
end

local Cmd = {}

function Cmd.world(uuid, message)
    Repeater.new_chat(Const.CHAT_CHANNEL_WORLD, {uuid, message})
end

function Cmd.private(uuid, to_uuid, message)
    Repeater.new_chat(Const.CHAT_CHANNEL_PRIVATE,{uuid, to_uuid, message})
end

function Cmd.system(message)
    Repeater.new_chat(Const.CHAT_CHANNEL_SYSTEM, {message})
end

function Cmd.register_listener(node)
    listeners[node] = true
    LOG_INFO("register_listener, node<%s>", node)
    Skynet.retpack({errcode = ERRNO.E_OK})
end

function Cmd.connect(...)
    return Acceptor.connect_handler(...)
end

Skynet.start(function()
    Skynet.dispatch("lua", function(session, from, cmd, ...)
        local f = assert(Cmd[cmd], cmd)
        f(...)
    end)

    Repeater.start()

    Skynet.register('.chat_speaker')
    LOG_INFO('chat_speaker booted')
end)

