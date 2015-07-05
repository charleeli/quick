local Skynet = require "skynet"
local Lcrab = require "crab"

Skynet.start(function()
    Lcrab.init(Skynet.getenv("black_words_path") or './config/words.txt')
    LOG_INFO("crab config is loaded")
end)
