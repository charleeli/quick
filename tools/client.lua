package.cpath = "../3rd/skynet/luaclib/?.so;../build/luaclib/?.so"
local service_path = "../lualib/?.lua;" .. "../service/?.lua;" .. "../lualib/preload/?.lua"
package.path = "../3rd/skynet/lualib/?.lua;../3rd/skynet/service/?.lua;" .. service_path

local netpack = require "netpack"
local socket = require "clientsocket"
local crypt = require "crypt"
require "luaext"

local SprotoLoader = require "sprotoloader"
local SprotoCore = require "sproto.core"
local SprotoEnv = require "sproto_env"
SprotoEnv.init('../build/sproto')

local sp_s2c = SprotoLoader.load(SprotoEnv.PID_S2C)
local sproto_server = sp_s2c:host(SprotoEnv.PACKAGE)
local sproto_client = sproto_server:attach(SprotoLoader.load(SprotoEnv.PID_C2S))

local LOGIN_HOST = "127.0.0.1"
local LOGIN_PORT = 5188

local GAME_HOST = "127.0.0.1"
local GAME_PORT = 5189
local gameserver = "game"
local secret
local USERNAME
local UID

local index = 0

local fd = nil

local function send_package(fd, pack)
    socket.send(fd, string.pack(">s2", pack))
end

local function unpack_package(text)
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

local function recv_package(last)
    local result
    result, last = unpack_package(last)
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
    return unpack_package(last .. r)
end

local function print_notify(name, args)
    print("NOTIFY", name)
    if args then
        table.print(args)
    end
    print('-------------------------------------------')
end

local function print_request(name, session,args)
    print("REQUEST", name,session)
    if args then
        table.print(args)
    end
    print('-------------------------------------------')
end

local function print_response(session, ret)
    print("RESPONSE", session)
    if ret then
        table.print(ret)
    end
    print('-------------------------------------------')
end

local session = 0

local function send_request(name, args)
    session = session + 1
    local v = sproto_client(name, args, session)
    local size = #v + 4
    local package = string.pack(">I2", size)..v..string.pack(">I4", session)
    socket.send(fd, package)
    print_request(name, session,args)
end

local last = ""

local function print_package(t, ...)
    if t == "REQUEST" then
        print_notify(...)
    else
        assert(t == "RESPONSE")
        print_response(...)
    end
end

local function dispatch_package()
    while true do
        local v
        v, last = recv_package(last)
        if not v then
            break
        end
        
        local size = #v - 5
        local content, ok, session = string.unpack("c"..tostring(size).."B>I4", v)
        
        print_package(sproto_server:dispatch(content))
    end
end

local default_args = {
    ['login'] = {account = "test_account"},
}

local function unpack_f(f)
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
			result, last = try_recv(fd, last)
			if result then
				return result
			end
			socket.usleep(100)
		end
	end
end

local read_package = unpack_f(unpack_package)

local function login(token, sdkid, noclose)
	assert(token and sdkid)

	-- 以下代码登录 loginserver
	fd = assert(socket.connect(LOGIN_HOST, LOGIN_PORT))

	local challenge = crypt.base64decode(read_package())	-- 读取用于握手验证的challenge

	local clientkey = crypt.randomkey()	-- 用于交换secret的clientkey
	send_package(fd,crypt.base64encode(crypt.dhexchange(clientkey)))
	local serverkey = crypt.base64decode(read_package())	-- 读取serverkey
	secret = crypt.dhsecret(serverkey, clientkey)		-- 计算私钥

	print("sceret is ", crypt.hexencode(secret))

	local hmac = crypt.hmac64(challenge, secret)
	send_package(fd,crypt.base64encode(hmac))		-- 回应服务器第一步握手的挑战码，确认握手正常

	token = string.format("%s:%s:%s", gameserver, token, sdkid)
    print('token: ' ,token)

	local etoken = crypt.desencode(secret, token)
	send_package(fd,crypt.base64encode(etoken))

	local result = read_package()
	local code = tonumber(string.sub(result, 1, 3))
	assert(code == 200)
	socket.close(fd)	-- 认证成功，断开与登录服务器的连接

	local user = crypt.base64decode(string.sub(result, 4,#result))		-- base64(uid:subid)
	local result = string.split(user, ":")
	UID = tonumber(result[1])

	print(string.format("login ok, user %s, uid %d", user, UID))

	-- 以下代码与游戏服务器握手
	fd = assert(socket.connect(GAME_HOST, GAME_PORT))
	index = index + 1
	local handshake = string.format("%s@%s#%s:%d",
		crypt.base64encode(result[1]),
		crypt.base64encode(gameserver),
		crypt.base64encode(result[2]),
		index)
	print("handshake=%s", handshake)
	local hmac = crypt.hmac64(crypt.hashkey(handshake), secret)

	send_package(fd,handshake .. ":" .. crypt.base64encode(hmac))

	result = read_package()
	code = tonumber(string.sub(result, 1, 3))
	assert(code == 200)

	if not noclose then
		socket.close(fd)
	end

	print("handshake ok...")
    print('-------------------------------------------')
end

local function check_cmd(s)
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

    local args = args or default_args[cmd]
    local ok, err = pcall(send_request, cmd, args)
    if not ok then
        print('send err', cmd, args, err)
    end
end

local function main()
    login(80, 1, true)

    while true do
        dispatch_package()
        check_cmd(socket.readstdin())
        socket.usleep(100)
    end

    print('quit')
end

main()

