local Skynet = require "skynet"
local Sharedata = require "sharedata"

local function init_sharedata()
    local data = {
        version = '',
        useable = true,
        service_map = {
            chat_speaker = {
                useable = true,
                black_apis = {}
            }
        },
    }

    Sharedata.new('service_state', data)
end

local Cmd = {}

function Cmd.add_service_state(sevice_name)
    local service_state = Sharedata.query("service_state")
    
    local service_map = {}
    for k, v in pairs(service_state.service_map) do
        local black_apis = {}
        for _k, _v in pairs(v.black_apis) do
            black_apis[_k] = _v
        end
        service_map[k] = {
            useable = v.useable,
            black_apis = black_apis,
        }
    end
    
    if not service_state.useable or service_map[sevice_name] then
        return Skynet.retpack(false)
    end
    
    service_map[sevice_name] = {
        useable = true,
        black_apis = {}
    }
    
    Sharedata.update("service_state", {
        useable = service_state.useable,
        version = service_state.version,
        service_map = service_map,
    })
    
    return Skynet.retpack(true)
end

function Cmd.update_service_state(data)
    Sharedata.update("service_state", data)
    return Skynet.retpack(true)
end

Skynet.start(function()
    Skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = assert(Cmd[cmd], cmd)
        f(...)
    end)

    init_sharedata()

    Skynet.register(".service_state")
    LOG_INFO("service_state booted")
end)
