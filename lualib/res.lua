local Skynet = require "skynet"
local ShareData = require "sharedata"

local M = {}

Skynet.init(function()
    local box = ShareData.query('res')
    box = box.M
    
    setmetatable(M, {__index = box})
end, "res")

return M

