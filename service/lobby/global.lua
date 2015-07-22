local Sharenv = require("sharenv")
local GLOBAL = Sharenv.init()

GLOBAL.players = {}
GLOBAL.room_mgr = nil

return Sharenv.fini(GLOBAL)

