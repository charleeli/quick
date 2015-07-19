package.cpath = "../3rd/skynet/luaclib/?.so;../build/luaclib/?.so"
package.path = package.path..';'.."../lualib/?.lua;../lualib/preload/?.lua"

local Cfg = require "config"
local enet = require "enet"
require "luaext"

local cfg = Cfg("../config/config.battle")

local host = enet.host_create()
local server = host:connect("127.0.0.1:"..cfg.udp.port)

local count = 0
while count < 100 do
	local event = host:service(100)
	if event then
		if event.type == "receive" then
			print("Got message: ",  event.data)
		else
			print("Got event", event.type)
		end
	end

	if count%4 == 0 then
		print "sending message"
		server:send('{"uuid":"133245223"}')
	end

	count = count + 1
end

server:disconnect()
host:flush()

print"client closed"

