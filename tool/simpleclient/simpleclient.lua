package.path = package.path..';./deps/?.lua;'
package.cpath = package.cpath..';./deps/?.so;'

local login = require 'simplelogin'
local message = require "simplemessage"
require "luaext"

local event = {}

message.register('../../build/sproto')
message.bind({}, event)

function event:__error(what, err, req, session)
	print("error", what, err)
end

function event:load_role(req, resp)
	print('-------------------------------------------')
	print("load_role", req)
	if resp then
		table.print(resp)
		message.request "view_sign"
	else
		print('load_role error')
	end
end

function event:view_sign(req, resp)
	print('-------------------------------------------')
	print("view_sign", req)
	if resp then
		table.print(resp)
	else
		print('view_sign error')
	end
end

login({
	login_host = "127.0.0.1",
	login_port = 5188,
	game_host  = "127.0.0.1",
	game_port  = 5189,
	game_server= "game",
}, message, 80, 1)

message.request("load_role")

while true do
	message.update()
end
