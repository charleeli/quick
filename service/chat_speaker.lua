local skynet = require 'skynet'
local cluster = require 'cluster'
local const = require 'const'
local acceptor = require 'acceptor'

local chat_cache = {}
local listeners = {}
local chat_max_buffer = 256

local function _call(node, service, ...)
    if NODE_NAME == node then
        return pcall(skynet.call, service, 'lua', ...)
    end
    return pcall(cluster.call, node, service, ...)
end

local repeater = {}

function repeater.new_chat(chat_channel, chat_info)
    table.insert(chat_cache[chat_channel], chat_info)
end

function repeater._dispatch(chat_channel, chat_buffer)
    for node, _ in pairs(listeners) do
        skynet.fork(function()
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

function repeater.dispatch(chat_channel)
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
        repeater._dispatch(chat_channel, buffer)
    end

    return next(chat_cache[chat_channel]) ~= nil
end

function repeater.start()
    for _, chat_channel in ipairs(const.CHAT_CHANNEL_KEYS) do
        chat_cache[chat_channel] = {}
        skynet.fork(function()
            while true do
                if not repeater.dispatch(chat_channel) then
                    skynet.sleep(1 * 100)
                end
            end
        end)
    end
end

local Cmd = {}

function Cmd.world(uuid, message)
    print(const.CHAT_CHANNEL_WORLD,uuid, message)
    repeater.new_chat(const.CHAT_CHANNEL_WORLD, {uuid, message})
end

function Cmd.private(uuid, to_uuid, message)
    repeater.new_chat(const.CHAT_CHANNEL_PRIVATE,{uuid, to_uuid, message})
end

function Cmd.system(message)
    repeater.new_chat(const.CHAT_CHANNEL_SYSTEM, {message})
end

function Cmd.register_listener(node)
    listeners[node] = true
    LOG_INFO("register_listener, node<%s>", node)
    skynet.retpack({errcode = ERRCODE.E_OK})
end

function Cmd.connect(...)
    local r = acceptor.connect_handler(...)
    skynet.retpack(r)
end

skynet.start(function()
    skynet.dispatch("lua", function(session, from, cmd, ...)
        local f = assert(Cmd[cmd], cmd)
        f(...)
    end)

    repeater.start()

    skynet.register('.chat_speaker')
    LOG_INFO('chat_speaker booted')
end)

