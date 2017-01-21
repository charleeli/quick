local skynet = require "skynet"
local queue = require "skynet.queue"
local snax = require "snax"
local ctime = require "ctime"
local lfs = require"lfs"
local sprotoloader = require "sprotoloader"
local sproto_env = require "sproto_env"
local cmd = require 'cmd'

local c2s_sp = sprotoloader.load(sproto_env.PID_C2S)
local c2s_host = c2s_sp:host(sproto_env.PACKAGE)

local cs = queue()
local UID
local SUB_ID
local SECRET
local FD
local afktime = 0

local gate		-- 游戏服务器gate地址
local CMD = {}
local zinc_client   -- msgagent对应的zinc_client服务

local worker_co
local running = false

local timer_list = {}

local function add_timer(id, interval, f)
	local timer_node = {}
	timer_node.id = id
	timer_node.interval = interval
	timer_node.callback = f
	timer_node.trigger_time = skynet.now() + interval

	timer_list[id] = timer_node
end

local function del_timer(id)
	timer_list[id] = nil
end

local function clear_timer()
	timer_list = {}
end

local function dispatch_timertask()
	local now = skynet.now()
	for k, v in pairs(timer_list) do
		if now >= v.trigger_time then
			v.callback()
			v.trigger_time = now + v.interval
		end
	end
end

local function worker()
	local t = skynet.now()
	while running do
		dispatch_timertask()
		local n = 100 + t - skynet.now()
		skynet.sleep(n)
		t = t + 100
	end
end

local function logout()
	if running then
		running = false
		skynet.wakeup(worker_co)	-- 通知协程退出
	end

	if gate then
		skynet.call(gate, "lua", "logout", UID, SUB_ID)
	end

	gate = nil
	UID = nil
	SUB_ID = nil
	SECRET = nil

	ti = {}
	afktime = 0

    skynet.kill(zinc_client)
	zinc_client = nil

	cmd.close()	-- 卸载玩家数据
	--这里不退出agent服务，以便agent能复用
	--skynet.exit()
end

-- 空闲登出
local function idle()
	if afktime > 0 then
		if skynet.time() - afktime >= 60 then		-- 玩家断开连接后一分钟强制登出
			logout()
		end
	end
end

local function reg_timers()
	add_timer(1, 500, idle)
end

-- 玩家登录游服后调用
function CMD.login(source, uid, subid, secret)
	-- you may use secret to make a encrypted data stream
	LOG_INFO("[%s] %d is login", skynet.address(skynet.self()), uid)
	gate = source
	UID = uid
	SUB_ID = subid
	SECRET = secret

	ti = {}
	afktime = 0
end

-- 玩家登录游服，握手成功后调用
function CMD.auth(source, uid, client_fd)
	FD = client_fd
	LOG_INFO("[%s] %d is real login", skynet.address(skynet.self()), uid)

    zinc_client = skynet.launch("zinc_client", FD)
    LOG_INFO(
	    "[%s] init agent's environmnet uid=%d fd=%d zinc_client=%x",
	    skynet.address(skynet.self()), uid, FD, zinc_client
    )

    cmd.start({uid = uid, subid = SUB_ID, zinc_client = zinc_client})

	if not running then
		running = true
		reg_timers()
		worker_co = skynet.fork(worker)
    end
end

function CMD.online(source, uid, client_fd)

end

function CMD.logout(source)
	-- NOTICE: The logout MAY be reentry
	LOG_INFO("[%s] %s is logout", skynet.address(skynet.self()), UID)
	logout()
end

function CMD.afk(source)
	-- the connection is broken, but the user may back
	afktime = skynet.time()
	skynet.error(string.format("[%s] AFK", skynet.address(skynet.self())))
end

local request_handlers = {}

local function load_request_handlers()
    local path = skynet.getenv('rpc_path') or './service/agent/rpc'
    for file in lfs.dir(path) do
        local _,suffix = file:match "([^.]*).(.*)"
        if suffix == 'lua' then
            local module_data = setmetatable({}, { __index = _ENV })
            local routine, err = loadfile(path..'/'..file, "bt", module_data)
            assert(routine, err)()

            for k, v in pairs(module_data) do
                if type(v) == 'function' then
                    request_handlers[k] = v
                end
            end
        end
    end
end

local function msg_unpack(msg, sz)
	local netmsg = skynet.tostring(msg, sz)
	if not netmsg then
		LOG_ERROR("[%s] msg_unpack error", skynet.address(skynet.self()))
		error("[%s] msg_unpack error", skynet.address(skynet.self()))
	end
	
	return netmsg
end

local function msg_dispatch(netmsg)
    local begin = ctime.timestamp()
	local type, name, request, response = c2s_host:dispatch(netmsg)

	if not request_handlers[name] then
	    LOG_ERROR('[%s] request_handler %s not exist or not loaded',skynet.address(skynet.self()), name)
	end

	if cmd.verify(name) then
		local r = request_handlers[name](request)
    	skynet.send(zinc_client, "zinc_client", string.pack(">s2",response(r)))
	else
		skynet.send(zinc_client, "zinc_client", string.pack(">s2",response{errcode = ERRCODE.E_ONLINE}))
	end

	LOG_INFO("[%s] process %s time used %f ms", skynet.address(skynet.self()), name, (ctime.timestamp()-begin)*1000)
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,

	unpack = function (msg, sz)
		return msg_unpack(msg, sz)
	end,

	dispatch = function (_, _, netmsg)
		msg_dispatch(netmsg)
	end
}

skynet.start(function()
    -- If you want to fork a work thread , you MUST do it in CMD.login
	skynet.dispatch("lua", function(session, source, command, ...)
		if cmd[command] then
		    cmd[command](...)
		else
		    local f = assert(CMD[command], string.format('illegal command:%s',command))
		    skynet.retpack(cs(f, source, ...))
	    end
	end)

	load_request_handlers()
end)
