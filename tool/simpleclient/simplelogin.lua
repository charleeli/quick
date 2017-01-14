package.path = package.path..';./deps/?.lua;'
package.cpath = package.cpath..';./deps/?.so;'

local socket = require "simplesocket"
local crypt = require "crypt"
require "luaext"

local USERNAME
local UID
local index = 0
local fd
local secret

local function login (conf, message, token, sdkid)
    assert(conf and token and sdkid)

	local LOGIN_HOST = conf.login_host
	local LOGIN_PORT = conf.login_port
	local GAME_HOST = conf.game_host
	local GAME_PORT = conf.game_port
	local gameserver = conf.game_server

    -- 以下代码登录 loginserver
    socket.connect(LOGIN_HOST, LOGIN_PORT)

    local challenge = crypt.base64decode(socket.read())    -- 读取用于握手验证的challenge

    local clientkey = crypt.randomkey() -- 用于交换secret的clientkey
    socket.write(crypt.base64encode(crypt.dhexchange(clientkey)))
    local serverkey = crypt.base64decode(socket.read())    -- 读取serverkey
    secret = crypt.dhsecret(serverkey, clientkey)       -- 计算私钥

    print("sceret is ", crypt.hexencode(secret))

    local hmac = crypt.hmac64(challenge, secret)
    socket.write(crypt.base64encode(hmac))       -- 回应服务器第一步握手的挑战码，确认握手正常

    token = string.format("%s:%s:%s", gameserver, token, sdkid)
    print('token: ' ,token)

    local etoken = crypt.desencode(secret, token)
    socket.write(crypt.base64encode(etoken))

    local result = socket.read()
    local code = tonumber(string.sub(result, 1, 3))
    assert(code == 200)
    socket.close()    -- 认证成功，断开与登录服务器的连接

    local user = crypt.base64decode(string.sub(result, 4,#result))      -- base64(uid:subid)
    local result = string.split(user, ":")
    UID = tonumber(result[1])

    print(string.format("login ok, user %s, uid %d", user, UID))

    -- 以下代码与游戏服务器握手
    message.peer(GAME_HOST, GAME_PORT)
    message.connect()
    index = index + 1
    local handshake = string.format("%s@%s#%s:%d",
        crypt.base64encode(result[1]),
        crypt.base64encode(gameserver),
        crypt.base64encode(result[2]),
        index)
    print("handshake=%s", handshake)
    local hmac = crypt.hmac64(crypt.hashkey(handshake), secret)

    message.write(handshake .. ":" .. crypt.base64encode(hmac))

    result = socket.read()
    code = tonumber(string.sub(result, 1, 3))
    assert(code == 200)
    print("handshake ok...")
end

return login
