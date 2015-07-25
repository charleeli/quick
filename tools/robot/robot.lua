package.cpath = "../../3rd/skynet/luaclib/?.so;../../build/luaclib/?.so"
local service_path = "../../lualib/?.lua;" .. "../../service/?.lua;" .. "../../lualib/preload/?.lua"
package.path = "../../3rd/skynet/lualib/?.lua;../../3rd/skynet/service/?.lua;" .. service_path

local netpack = require "netpack"
local socket = require "clientsocket"
local crypt = require "crypt"
require "luaext"

local SprotoLoader = require "sprotoloader"
local SprotoCore = require "sproto.core"
local SprotoEnv = require "sproto_env"
SprotoEnv.init('../../build/sproto')

local sp_s2c = SprotoLoader.load(SprotoEnv.PID_S2C)
local sp_c2s = SprotoLoader.load(SprotoEnv.PID_C2S)
local sproto_server = sp_s2c:host(SprotoEnv.BASE_PACKAGE)
local sproto_client = sproto_server:attach(sp_c2s)

local function req_has_resp(sp, name)
    local tag, req, resp = SprotoCore.protocol(sp.__cobj, name)
    return resp ~= nil
end

local Robot = class()

function Robot:ctor()
    self.LOGIN_HOST = "127.0.0.1"
    self.LOGIN_PORT = 5188

    self.GAME_HOST = "127.0.0.1"
    self.GAME_PORT = 5189
    self.gameserver = "game"

    self.secret = nil
    self.USERNAME = nil
    self.UID = nil

    self.index = 0
    self.session = 0
    
    self.last = ""
    self.fd = nil
end

function Robot:send_package(pack)
    socket.send(self.fd, string.pack(">s2", pack))
end

function unpack_package(text)
    local size = #text
    if size < 2 then
        return nil, text
    end
    local s = text:byte(1) * 256 + text:byte(2)
    if size < s+2 then
        return nil, text
    end

    return text:sub(3,2+s), text:sub(3+s)
end

function Robot:recv_package()
    local result
    result, self.last = unpack_package(self.last)
    if result then 
        return result, self.last
    end
    local r = socket.recv(self.fd)
    if not r then
        return nil, self.last
    end
    if r == "" then
        error "Server closed"
    end
    return unpack_package(self.last .. r)
end

function Robot:print_notify(name, args)
    print("NOTIFY", name)
    if args then
        table.print(args)
    end
    print('-------------------------------------------')
end

function Robot:print_request(name, session,args)
    print("REQUEST", name,session)
    if args then
        table.print(args)
    end
    print('-------------------------------------------')
end

function Robot:print_response(session, ret)
    print("RESPONSE", session)
    if ret then
        table.print(ret)
    end
    print('-------------------------------------------')
end

function Robot:send_request(name, args)
    self.session = self.session + 1
    local v = sproto_client(name, args, self.session)
    local size = #v + 4
    local package = string.pack(">I2", size)..v..string.pack(">I4", self.session)
    socket.send(self.fd, package)
    self:print_request(name, self.session,args)
end

function Robot:print_package(t, ...)
    if t == "REQUEST" then
        self:print_notify(...)
    else
        assert(t == "RESPONSE")
        self:print_response(...)
    end
end

function Robot:dispatch_package()
    while true do
        local v
        v, self.last = self:recv_package()
        if not v then
            break
        end
        
        local size = #v - 5
        local content, ok, session = string.unpack("c"..tostring(size).."B>I4", v)
        
        self:print_package(sproto_server:dispatch(content))
    end
end

local function unpack_f(f,self)
	local function try_recv(fd, last)
		local result
		result, last = f(last)
		if result then
			return result, last
		end
		local r = socket.recv(fd)
		if not r then
			return nil, last
		end
		
		if r == "" then
			error "Server closed"
		end
		
		return f(last .. r)
	end

	return function()
		while true do
			local result
			result, self.last = try_recv(self.fd, self.last)
			if result then
				return result
			end
			socket.usleep(100)
		end
	end
end

function Robot:login(token, sdkid, noclose)
	assert(token and sdkid)
	
	-- 以下代码登录 loginserver
	self.fd = assert(socket.connect(self.LOGIN_HOST, self.LOGIN_PORT))

    local read_package = unpack_f(unpack_package,self)
	local challenge = crypt.base64decode(read_package())	-- 读取用于握手验证的challenge
	local clientkey = crypt.randomkey()	-- 用于交换secret的clientkey
	self:send_package(crypt.base64encode(crypt.dhexchange(clientkey)))	
	local serverkey = crypt.base64decode(read_package())	-- 读取serverkey	
	self.secret = crypt.dhsecret(serverkey, clientkey)		-- 计算私钥

	print("sceret is ", crypt.hexencode(self.secret))

	local hmac = crypt.hmac64(challenge, self.secret)
	self:send_package(crypt.base64encode(hmac))		-- 回应服务器第一步握手的挑战码，确认握手正常

	token = string.format("%s:%s:%s", self.gameserver, token, sdkid)
	local etoken = crypt.desencode(self.secret, token)
	self:send_package(crypt.base64encode(etoken))

	local result = read_package()
	local code = tonumber(string.sub(result, 1, 3))
	assert(code == 200)
	socket.close(self.fd)	-- 认证成功，断开与登录服务器的连接

	local user = crypt.base64decode(string.sub(result, 4,#result))		-- base64(uid:subid)
	local result = string.split(user, ":")
	self.UID = tonumber(result[1])

	print(string.format("login ok, user %s, uid %d", user, self.UID))

	-- 以下代码与游戏服务器握手
	self.fd = assert(socket.connect(self.GAME_HOST, self.GAME_PORT))
	self.index = self.index + 1
	local handshake = string.format("%s@%s#%s:%d",
		crypt.base64encode(result[1]),
		crypt.base64encode(self.gameserver),
		crypt.base64encode(result[2]),
		self.index)
	print("handshake=%s", handshake)
	local hmac = crypt.hmac64(crypt.hashkey(handshake), self.secret)

	self:send_package(handshake .. ":" .. crypt.base64encode(hmac))

	result = read_package()
	code = tonumber(string.sub(result, 1, 3))
	assert(code == 200)

	if not noclose then
		socket.close(self.fd)
	end

	print("handshake ok...")
	print('-------------------------------------------')
end

function Robot:check_cmd(s)
    if s == "" or s == nil then
        return s
    end

    local cmd = ""
    local args = nil
    local b, e = string.find(s, " ")
    if b then
        cmd = s:sub(0, b - 1)
        local args_data = "return " .. s:sub(e + 1)
        local f, err = load(args_data)
        if f == nil then
            print("illegal cmd", s, _args)
            return
        end

        local ok, _args = pcall(f)
        if (not ok) or (type(_args) ~= 'table') then
            print("illegal cmd", s, _args)
            return
        else
            args = _args
        end
    else
        cmd = s
    end

    local ok, err = pcall(self.send_request,self, cmd, args)
    if not ok then
        print('send err', cmd, args, err)
    end
end

function Robot:parse_cmd(s)
    if s == "" or s == nil then
        return false
    end

    local cmd = ""
    local args_data = nil
    local b, e = string.find(s, " ")
    if b then
        cmd = s:sub(0, b - 1)
        args_data = s:sub(e + 1)
    else
        cmd = s
    end

    if cmd == "script" then
        if not args_data then
            print("illegal cmd", s)
            return false
        end
        return true, cmd, args_data
    end

    local args
    if args_data then
        local f, err = load("return " .. args_data)
        if f == nil then
            print("illegal cmd", s)
            return false
        end

        local ok, _args = pcall(f)
        if (not ok) or (type(_args) ~= 'table') then
            print("illegal cmd", s)
            return false
        end
        args = _args
    end

    return true, cmd, args
end

function Robot:run_cmd(cmd, args)
    print('[COMMAND]', cmd, args)
    local ok, err = pcall(self.send_request, self, cmd, args)
    if not ok then
        print('run cmd fail', cmd, args, err)
        return false
    end

    if req_has_resp(sp_c2s, cmd) then
        self:dispatch_package()
    end
end

function Robot:run_script(script)
    print('[script]', script)
    local env = setmetatable(
        {
            client = self,
        },
        {__index = _ENV}
    )

    local func, err = loadfile(script, "bt", env)
    if not func then
        print('load script fail, err', err)
        return
    end
    func()
end

function Robot:console()
    print('enter console mode, please input cmd:')
    while true do
        self:dispatch_package()
        local s = socket.readstdin()
        if s == "quit" then
            break
        end

        if (s ~= nil and s ~= "") then
            local ok, cmd, args = self:parse_cmd(s)
            if ok then
                if cmd == "script" then
                    self:run_script(args)
                else
                    self:run_cmd(cmd, args)
                end
            end
        end
        socket.usleep(100)
    end
end

return Robot

