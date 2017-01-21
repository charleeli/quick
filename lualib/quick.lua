local skynet = require "skynet"
local cluster = require 'cluster'
local sprotoloader = require "sprotoloader"
local sproto_env = require "sproto_env"

local c2s_sp = sprotoloader.load(sproto_env.PID_C2S)
local c2s_host = c2s_sp:host(sproto_env.PACKAGE)
local s2c_sp = sprotoloader.load(sproto_env.PID_S2C)
local s2c_encode_req = c2s_host:attach(s2c_sp)

local quick = {}

function quick.notify(zinc_client, api, args)
    skynet.send(
        zinc_client, 
        "zinc_client", 
        string.pack(">s2", s2c_encode_req(api, args))
    )
end

function quick.send(node, service, api, ...)
    local caller = function(node, service, api, ...)
        local ok, ret = pcall(cluster.call, node, service, api, ...)
        if ok then return ret end
        return {errcode = ERRCODE.E_SERVICE, errdata=ret}
    end
     
    skynet.fork(caller, node, service, api, ...)
end

function quick.center_node_name()
    local center_cfg = skynet.getenv('center')
    if not center_cfg then
        error("no center cfg!")
    end
    
    local env = {}
    local f = assert(loadfile(center_cfg,"t",env))
    f()
    return env.centernode
end

function quick.caller(g_service)
    local center_node_name = quick.center_node_name()
    
    if center_node_name ~= NODE_NAME then
        return function(api, ...)
            local ok, ret = pcall(
                cluster.call, center_node_name, '.'..g_service, api, ...
            )

            if ok then return ret end

            LOG_ERROR('cluster.call %s %s %s failed', center_node_name, g_service, api)
            return {errcode = ERRCODE.E_SERVICE, errdata=ret}
        end
    end
 
    return function(api, ...)
        local ok, ret = pcall(skynet.call, '.'..g_service, "lua", api, ...)
        if ok then
            return ret
        end
        LOG_ERROR('skynet.call this node(%s) %s %s failed', NODE_NAME, g_service, api)
        return {errcode = ERRCODE.E_SERVICE, errdata=ret}
    end
end

return quick
