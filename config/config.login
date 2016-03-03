skynetroot = "./3rd/skynet/"
thread = 8
logger = nil
logpath = "."
harbor = 0
start = "main"	-- main script
bootstrap = "snlua bootstrap"	-- The service for bootstrap

-- 集群名称配置文件
cluster = "./config/common/clustername.lua"

--账号中心配置文件
accountdb= './config/common/config.accountdb'

log_dirname = "log"
log_basename = "login"

loginservice = "./service/login/?.lua;" ..
			   "./service/?.lua;"

-- LUA服务所在位置
luaservice = skynetroot .. "service/?.lua;" .. loginservice
snax = loginservice

-- 用于加载LUA服务的LUA代码
lualoader = skynetroot .. "lualib/loader.lua"

-- run preload.lua before every lua service run
preload = "./lualib/preload/preload.lua"	

-- C编写的服务模块路径
cpath = skynetroot .. "cservice/?.so"

-- 将添加到 package.path 中的路径，供 require 调用。
lua_path = skynetroot .. "lualib/?.lua;" ..
		   "./lualib/?.lua;" ..
		   "./lualib/preload/?.lua"

-- 将添加到 package.cpath 中的路径，供 require 调用。
lua_cpath = skynetroot .. "luaclib/?.so;" .. "./build/luaclib/?.so"

-- 后台模式
--daemon = "./login.pid"

-- 监听端口
port = 5188					
