local skynet = require "skynet"
local sproto_env = require "sproto_env"

skynet.start(function()
    local sp_root = skynet.getenv('sprotopath') or './build/sproto'
    sproto_env.init(sp_root)
    LOG_INFO("sproto config is loaded")
end)
