local skynet = require 'skynet'

local ZINC_CLIENT = 16

skynet.register_protocol {
    name = "zinc_client",
    id = ZINC_CLIENT,

    pack = function (...)
        return ...
    end,
}

assert(skynet['atexit'] == nil)
assert(skynet['get_exit_cb'] == nil)

local SYS_CONTROL = 17

local exit_cb

function skynet.atexit(cb)
    exit_cb = cb
end

function skynet.get_exit_cb()
    return exit_cb
end

local cmd = {}
function cmd.EXIT()
    local cb = skynet.get_exit_cb()
    if cb then
        cb()
    end
    skynet.exit()
end

skynet.register_protocol {
    name = 'sys',
    id = SYS_CONTROL,
    unpack = skynet.unpack,
    pack = skynet.pack,
    dispatch = function(_, _, cmd_name, ...)
        local f = assert(cmd[cmd_name], cmd_name)
        f(...)
    end,
}
