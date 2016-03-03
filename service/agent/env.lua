local share_env = require 'share_env'
local env = share_env.init()

env.uid = nil
env.account = nil
env.role = nil
env.session_lock = nil
env.timer_mgr = nil
env.zinc_client = nil

return share_env.fini(env)

