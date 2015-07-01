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

M.OK = 0
M.ERROR = -1

M.VIRTUAL_NAME2ID = {
    coupon = 1000,
    exp = 1001,
    level = 1002,
    vip = 1003,
    gold = 1004,
    sign_score = 1005,
}
return M
