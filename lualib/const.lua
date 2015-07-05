local M = {}

local function create_enum(begin_idx)
    local enum_idx = (begin_idx or 0) - 1
    return function()
        enum_idx = enum_idx + 1
        return enum_idx
    end
end

local EVT_ENUM = create_enum(0)
M.EVT_ONLINE = EVT_ENUM()
M.EVT_OFFLINE_BEGIN = EVT_ENUM()
M.EVT_OFFLINE = EVT_ENUM()

-- chat begin
M.CHAT_CHANNEL_PRIVATE = "CHAT_CHANNEL_PRIVATE"
M.CHAT_CHANNEL_WORLD =   "CHAT_CHANNEL_WORLD"
M.CHAT_CHANNEL_SYSTEM =  "CHAT_CHANNEL_SYSTEM"
M.CHAT_CHANNEL_KEYS = { 
    M.CHAT_CHANNEL_PRIVATE,
    M.CHAT_CHANNEL_WORLD,
    M.CHAT_CHANNEL_SYSTEM,
}
M.GLOBAL_CHAT_BROADCAST_INTERVAL = 1
M.GLOBAL_CHAT_BROADCAST_MAX_NUM = 32
M.SEND_WORLD_CHAT_LIMIT = 8
M.NoneUUID = ""
M.CHAT_TYPE_SYSTEM = 0
M.CHAT_TYPE_PRIVATE = 1 
M.CHAT_TYPE_WORLD = 2
M.CHAT_SUB_TYPE_RECEIPT = 1 
M.CHAT_SUB_TYPE_PLAYER = 0
M.CHAT_SUB_TYPE_SYSTEM_1 = 0 
M.CHAT_SUB_TYPE_SYSTEM_2 = 1
-- chat end

M.VIRTUAL_NAME2ID = {
    coupon = 1000,
    exp = 1001,
    level = 1002,
    vip = 1003,
    gold = 1004,
    sign_score = 1005,
}
return M
