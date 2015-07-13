local Skynet = require "skynet"
local Sharedata = require "sharedata"

local function _call(cmd, ...)
    return Skynet.call('.service_state', 'lua', cmd, ...)
end

local function _send(cmd, ...)
    Skynet.send('.service_state', 'lua', cmd, ...)
end

local M = {}

function M.check_init()
    if not M.service_state then
        M.service_state = Sharedata.query("service_state")
    end
end

function M.check_version(version)
    M.check_init()
    return M.service_state.version == version
end

function M.clone_service_state()
    M.check_init()
    local obj = M.service_state
    local service_map = {}
    for k, v in pairs(obj.service_map) do
        local black_apis = {}
        for _k, _v in pairs(v.black_apis) do
            black_apis[_k] = _v
        end
        service_map[k] = {
            useable = v.useable,
            black_apis = black_apis,
        }
    end

    return {
        useable = obj.useable,
        version = obj.version,
        service_map = service_map,
    }
end

function M.add_service_state(sevice_name)
    assert(sevice_name, 'sevice_name is nil')
    _call('add_service_state', sevice_name)
end

function M.update_service_state(data)
    assert(type(data.service_map) == 'table', 'service_map is not table')
    for k, v in pairs(data.service_map) do
        assert(type(v.black_apis) == 'table','service_map.black_apis not table')
    end

    _call('update_service_state', data)
end

function M.close_all(version)
    local data = M.clone_service_state()
    data.useable = false
    data.version = version
    M.update(data)
end

function M.is_useable(service_name, api_name)
    M.check_init()
    if not M.service_state.useable then
        return false
    end

    local service_info = M.service_state.service_map[service_name]
    if not service_info then
        return false
    end

    if not service_info.useable then
        return false
    end
    
    if not api_name then
        return true
    end

    return service_info.black_apis[api_name] == nil
end

return M
