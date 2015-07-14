local Sharenv = require("sharenv")
local GLOBAL = Sharenv.init()

GLOBAL.cache_max_cnt = 5000
GLOBAL.cache_ttl = 1000
GLOBAL.cache_save_cd = 600
GLOBAL.base_mgr = nil

return Sharenv.fini(GLOBAL)
