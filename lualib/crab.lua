local Skynet = require 'skynet'
local Lcrab = require 'lcrab'
local UTF8 = require 'utf8'
local M = {}

local function _toutf8(line) 
    local words = {}
    for p, c in utf8.codes(line) do
        table.insert(words, c)
    end
    return words
end

function M.init(path)
    if not path then
        return
    end
    local words = {}
    for line in io.lines(path) do
        local t = _toutf8(line)
        table.insert(words, t)
    end
    Lcrab.open(words)
end

function M.is_crabbed(str)
    if not str then 
        return true 
    end

    local t = _toutf8(str)
    return not Lcrab.filter(t)
end

return M
