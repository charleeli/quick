local Skynet = require 'skynet'

assert(Skynet['atexit'] == nil)
assert(Skynet['get_exit_cb'] == nil)

local SYS_CONTROL = 17

local exit_cb = nil
function Skynet.atexit(cb)
    exit_cb = cb
end

function Skynet.get_exit_cb()
    return exit_cb
end

local cmd = {}
function cmd.EXIT()
    local cb = Skynet.get_exit_cb()
    if cb then
        cb()
    end
    Skynet.exit()
end

Skynet.register_protocol {
    name = 'sys',
    id = SYS_CONTROL,
    unpack = Skynet.unpack,
    pack = Skynet.pack,
    dispatch = function(session, address, cmd_name, ...)
        local f = assert(cmd[cmd_name], cmd_name)
        f(...)
    end,
}
