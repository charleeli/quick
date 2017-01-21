local skynet = require "skynet"
local lcrab = require "crab"

skynet.start(function()
    lcrab.init(skynet.getenv("black_words_path") or './config/common/words.txt')
    LOG_INFO("crab config is loaded")
end)
