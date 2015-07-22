package.cpath = "../3rd/skynet/luaclib/?.so;../build/luaclib/?.so"
package.path = package.path..';'.."../lualib/?.lua;../lualib/preload/?.lua"

local Cfg = require "config"
local enet = require "enet"
require "luaext"

local cfg = Cfg("../config/config.battle")

local host = enet.host_create()
local server = host:connect("127.0.0.1:"..cfg.udp.port)

local count = 1
while true do
	local event = host:service(100)
	if event then
		if event.type == "receive" then
			print("Got message: ",  event.data)
		else
			print("Got event", event.type)
		end
	end
	
	local data = '{"uuid":"55a79566e428a6ad2b9f4ad9"}'

	if count == 4 then
	    print (string.format("sending message:%s",data))
	    server:send(data)
	end

	count = count + 1
end

server:disconnect()
host:flush()

print"client closed"

