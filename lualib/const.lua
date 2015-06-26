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

return M
