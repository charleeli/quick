local share_env = require 'share_env'
local env = share_env.init()

env.uid = nil
env.subid = nil
env.account = nil
env.role = nil
env.session_lock = nil
env.timer = nil
env.zinc_client = nil

return share_env.fini(env)

