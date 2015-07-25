package.cpath = package.cpath .. ";../../build/luaclib/?.so"
package.path = package.path .. ";../../lualib/?.lua;../../3rd/skynet/lualib/?.lua"

local argparse = require "argparse"
local Robot = require 'robot'
require "luaext"

local function init_argparse()
    local parser = argparse()
    parser:description("Cmd Client")

    parser:option("-a", "--host"):default("127.0.0.1"):description("Server IP")
    parser:option("-p", "--port"):default("5189"):description("Server Port"):convert(tonumber)
    parser:option("-s", "--script"):description("Script")
    return parser
end


local function main()
    local args = init_argparse():parse()
    local client = Robot.new()
    client:login("dg56vs38", 1, true)
    
    if args.script then
        client:run_script(args.script)
    end
    client:console()
end

main()
