local M = {}

local function create_enum(begin_idx)
    local enum_idx = (begin_idx or 0) - 1
    return function()
        enum_idx = enum_idx + 1
        return enum_idx
    end
end

M.ROLE_DAILY_UPDATE_HOUR = 0 -- 玩家每日更新时间
M.ONE_DAY_SECONDS = 24 * 3600

local EVT_ENUM = create_enum(0)
M.EVT_ONLINE = EVT_ENUM()
M.EVT_OFFLINE_BEGIN = EVT_ENUM()
M.EVT_OFFLINE = EVT_ENUM()
M.EVT_DAILY_UPDATE = EVT_ENUM()

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

-- mailbox begin
M.MAIL_TYPE_SYSTEM = 0
M.MAIL_TYPE_PRIVATE = 1
M.MAIL_EXPIRE_TIME = 30 * 24 * 3600 -- 一个月之前的邮件强制删除
M.MAIL_UPDATE_INTERVAL = 100        -- 玩家更新邮箱时间间隔 100秒
M.MAIL_SUBJECT_LIMIT = 10           -- 邮件标题长度限制 
M.MAIL_CONTENT_LIMIT = 50           -- 邮件内容长度限制
M.MAILBOX_LIMIT = 5                 -- 系统和用户邮箱上限
M.MAIL_CACHE_LIMIT = 10             -- 缓存中某个玩家的邮箱中邮件数量限制
-- mailbox end

M.VIRTUAL_NAME2ID = {
    coupon = 1000,
    exp = 1001,
    level = 1002,
    vip = 1003,
    gold = 1004,
    sign_score = 1005,
}
return M
