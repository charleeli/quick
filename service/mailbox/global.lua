local share_env = require "share_env"
local env = share_env.init()

env.cache_max_cnt = 5000
env.cache_ttl = 1000
env.cache_save_cd = 600
env.mailbox_mgr = nil

return share_env.fini(env)
