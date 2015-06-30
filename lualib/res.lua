local Skynet = require "skynet"
local ShareData = require "sharedata"

local M = {}

Skynet.init(function()
    local box = ShareData.query('resource')
    box = box.M
    setmetatable(M, {__index = box})
end, "resource")

return M

