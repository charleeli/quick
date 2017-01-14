local sprotoloader = require "sprotoloader"
local sprotocore = require "sproto.core"

local M = {}
M.PACKAGE = "package"
M.PID_C2S = 1
M.PID_S2C = 2

M.sproto_list = {
    {
        id = M.PID_C2S,
        filename = 'c2s.spb',
    },

    {
        id = M.PID_S2C,
        filename = 's2c.spb',
    }, 
}

function M.init(sp_root)
    for _, item in ipairs( M.sproto_list ) do
        local fpath = sp_root .. "/" .. item.filename
        local fp = assert(io.open(fpath, "rb"), "Can't open sproto file")
        local bin = fp:read "*all"
        sprotoloader.save(bin, item.id)
    end
end

return M

