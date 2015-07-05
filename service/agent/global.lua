local Sharenv = require 'sharenv'
local Global = Sharenv.init()

Global.uid = nil 
Global.account = nil 
Global.role = nil
Global.session_lock = nil
Global.timer_mgr = nil
Global.zinc_client = nil

return Sharenv.fini(Global)

