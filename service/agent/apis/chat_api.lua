local utf8 = require "utf8"
local date = require 'date'
local crab = require 'crab'
local const = require 'const'
local notify = require 'notify'
local chat_cli = require 'chat_cli'

local CHAT_MSG_MAXLEN = 128

local function _check_message(msg)
    local msg_len = utf8.len(msg)
    
    if msg_len == 0 then
        return ERRCODE.E_CHAT_EMPTY
    end

    if msg_len > CHAT_MSG_MAXLEN then
        return ERRCODE.E_CHAT_OVENLEN
    end
    
    if not crab.is_crabbed(msg) then
        LOG_ERROR("check chat failed: content sensitive !")
        return ERRCODE.E_CONTENT_SENSITIVE
    end

    return ERRCODE.E_OK
end

local apis = {}

function apis:init_chat()
    self.next_world_chat_sendtime = 0
end

function apis:send_world_chat(msg_data)
    if msg_data == nil then
        LOG_ERROR("send_world_chat , args nil!")
        return { errcode = ERRCODE.E_ARGS }
    end
    
    local now = date.second()
    if now < self.next_world_chat_sendtime then
        LOG_ERROR("send_world_chat too frequrecy!")
        return {errcode = ERRCODE.E_FREQUENCY }
    end
    
    local ret = _check_message(msg_data)
    if ret ~= ERRCODE.E_OK then
        LOG_ERROR("send_world_chat msg_data illegal!")
        return {errcode = ret }
    end
    
    self.next_world_chat_sendtime = now + const.SEND_WORLD_CHAT_LIMIT
    
    local my_uuid = self:get_uuid()
    
    local chat_obj = {
        type = const.CHAT_TYPE_WORLD,
        sub_type = const.CHAT_SUB_TYPE_PLAYER,
        uuid = my_uuid,
        name = self:get_name(),
        time = date.second(),
        msg = msg_data,
    }
    
    chat_cli.send_world(my_uuid, chat_obj)
    
    LOG_INFO('<%s>send world chat succeed :<%s>', my_uuid, msg_data)
    return {errcode = ERRCODE.E_OK}
end

function apis:send_private_chat(to_uuid, msg_data)
    if to_uuid == nil or msg_data == nil then
        LOG_ERROR("send_private_chat , args nil!")
        return { errcode = ERRCODE.E_ARGS }
    end
    
    local ret = _check_message(msg_data)
    if ret ~= ERRCODE.E_OK then
        LOG_ERROR("send_private_chat msg_data illegal!")
        return {errcode = ret }
    end
    
    local my_uuid = self:get_uuid()
    
    local chat_obj = {
        type = const.CHAT_TYPE_PRIVATE,
        sub_type = const.CHAT_SUB_TYPE_PLAYER,
        uuid = my_uuid,
        name = self:get_name(),
        time = date.second(),
        msg = msg_data,
    }
    
    chat_cli.send_private(my_uuid, to_uuid, chat_obj)
    
    LOG_INFO('<%s>send private chat succeed :<%s>', my_uuid, msg_data)
    
    local to_name = ""

    notify.chat{
        type = const.CHAT_TYPE_PRIVATE,
        sub_type = const.CHAT_SUB_TYPE_RECEIPT,
        uuid = to_uuid,
        name = to_name,
        time = date.second(),
        msg = msg_data,
    }
    
    return { errcode = ERRCODE.E_OK }
end

function apis:online_chat_trigger()
    chat_cli.subscribe(self:get_uuid())
end

function apis:offline_chat_trigger()
    chat_cli.unsubscribe(self:get_uuid())
end

local triggers = {
    [const.EVT_ONLINE] = function(self)
        self:init_chat()
        self:online_chat_trigger()
    end,

    [const.EVT_OFFLINE] = function(self)
        self:offline_chat_trigger()
    end
}

return {apis = apis, triggers = triggers}
