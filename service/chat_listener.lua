local skynet = require "skynet"
local const = require "const"
local timer = require 'timer'
local connector = require 'connector'
local quick = require 'quick'

local players   = {}
local chat_cache = {}
local speaker_connector

local function _send_client(zinc_client, proto, ...)
    if zinc_client then
        quick.notify(zinc_client, proto, ...)
    end
end

local function _dispatch_system_msg(msg)
    for uuid, player in pairs(players) do
        _send_client(player.zinc_client, "chat",  { chats = {msg} })
    end
end

local function _dispatch_world_msg(uuid, msg)
    local cache = chat_cache[const.CHAT_TYPE_WORLD]
    if not cache then
        cache = {}
        chat_cache[const.CHAT_TYPE_WORLD] = cache
    end
    table.insert(cache, {uuid=uuid, chats = {msg} })
end

local function _dispatch_private_msg(uuid, to_uuid, msg)
    local player = players[to_uuid]
    if not player then return end

    if player.zinc_client then
        _send_client(player.zinc_client, "chat", { chats = {msg} })
    else
        LOG_ERROR("to_player.zinc_client is nil")        
    end
end

local repeater = {}

repeater.channel_handlers = {
    [const.CHAT_CHANNEL_SYSTEM]  = _dispatch_system_msg,
    [const.CHAT_CHANNEL_PRIVATE] = _dispatch_private_msg,
    [const.CHAT_CHANNEL_WORLD] = _dispatch_world_msg,
}

function repeater.update_world_chat()
    local cache = chat_cache[const.CHAT_TYPE_WORLD]
  
    if type(cache) == "table" and cache ~= {} then
        local max_idx = #cache
        local min_idx = math.max(1, max_idx - const.GLOBAL_CHAT_BROADCAST_MAX_NUM + 1)
        
        local all_chats = {}
        for idx, item in ipairs(cache) do
            if idx >= min_idx and idx <= max_idx then
                for _, msg in ipairs(item.chats) do
                    table.insert(all_chats, msg)
                end
            end
        end
        
        if min_idx ~= 1 then
           LOG_INFO(tostring(min_idx-1).." world messages have been cuted")
        end
        
        for to_uuid, player in pairs(players) do
            if #all_chats > 0 then
                _send_client(player.zinc_client, "chat", { chats = all_chats})
            end
        end
        
        chat_cache[const.CHAT_TYPE_WORLD] = {}
    end
end

local Cmd = {}

function Cmd.subscribe(uuid, agent, zinc_client)
    local player = players[uuid]
    if player then
        players[uuid] = nil
    end
    
    players[uuid] = {
        agent = agent, 
        zinc_client = zinc_client,
    }
end

function Cmd.unsubscribe(uuid)
    local player = players[uuid]
    if player then
        players[uuid] = nil
    end
end

function Cmd.dispatch(chat_type, chats)
    skynet.retpack(nil)
    local handler = repeater.channel_handlers[chat_type]
    if not handler then return end

    for _, args in ipairs(chats) do
        handler(table.unpack(args))
    end
end

function Cmd.connect_speaker_cb(...)
    LOG_INFO("send heartbeat to chat_speaker", ...)
    local _call_speaker = quick.caller('chat_speaker')
    local  r = _call_speaker('connect', ...)
    return r
end

function Cmd.connected_speaker_cb()
    LOG_INFO("chat_speaker connected")
    local _call_speaker = quick.caller('chat_speaker')
    
    local ret = _call_speaker('register_listener', NODE_NAME)
    if ret.errcode ~= ERRCODE.E_OK then
        LOG_ERROR("register listener fail, errcode<%s>", ret.errcode)
        return false
    end
    
    return true
end

function Cmd.disconnect_speaker_cb()
    --LOG_ERROR("chat_speaker disconnected")
end

skynet.start(function()
    skynet.dispatch("lua", function(session, from, cmd, ...)
        local f = assert(Cmd[cmd], cmd)
        f(...)
    end)

    local timer = timer(1)
    timer:start()
    timer:add_timer(
        const.GLOBAL_CHAT_BROADCAST_INTERVAL,
        function()
            local ok, err = pcall(repeater.update_world_chat)
            if not ok then
                LOG_ERROR("update world chat fail<%s>", err)
                chat_cache = {}
            end
        end
    )
    
    speaker_connector = connector(
        Cmd.connect_speaker_cb,
        Cmd.connected_speaker_cb,
        Cmd.disconnect_speaker_cb
    )
    speaker_connector:start()

    skynet.register('.chat_listener')
    LOG_INFO('chat_listener booted')
end)

