local Skynet = require "skynet"
local Cluster = require 'cluster'
local netpack = require "netpack"
local SprotoLoader = require "sprotoloader"
local SprotoEnv = require "sproto_env"

local c2s_sp = SprotoLoader.load(SprotoEnv.PID_C2S)
local c2s_host = c2s_sp:host(SprotoEnv.BASE_PACKAGE)
local s2c_sp = SprotoLoader.load(SprotoEnv.PID_S2C)
local s2c_encode_req = c2s_host:attach(s2c_sp)

local ZINC_CLIENT = 16

Skynet.register_protocol {
    name = "zinc_client",
    id = ZINC_CLIENT,
    
    pack = function (...) 
        return ...
    end,
}

local Quick = {}

function Quick.notify(zinc_client, api, args)
    Skynet.send(
        zinc_client, 
        "zinc_client", 
        netpack.pack_string(s2c_encode_req(api, args)..string.pack("B>I4",1,0))
    )
end

function Quick.send(node, service, api, ...)
    local caller = function(node, service, api, ...)
        local ok, ret = pcall(Cluster.call, node, service, api, ...)
        if ok then return ret end
        return {errcode = ERRNO.E_SERVICE_UNAVAILABLE, errdata=ret}
    end
     
    Skynet.fork(caller, node, service, api, ...)
end

function Quick.center_node_name()
    local center_cfg = Skynet.getenv('center')
    if not center_cfg then
        error("no center cfg!")
    end
    
    local env = {}
    local f = assert(loadfile(center_cfg,"t",env))
    f()
    return env.centernode
end

function Quick.caller(g_service)
    local node = Quick.center_node_name()
    
    if node ~= NODE_NAME then
        return function(api, ...)
            local ok, ret = pcall(Cluster.call, node, '.'..g_service, api, ...)
            if ok then return ret end
            return {errcode = ERRNO.E_SERVICE_UNAVAILABLE, errdata=ret}
        end
    end
 
    return function(api, ...)
        local ok, ret = pcall(Skynet.call, '.'..g_service, "lua", api, ...)
        if ok then return ret end
        return {errcode = ERRNO.E_SERVICE_UNAVAILABLE, errdata=ret}
    end
end

return Quick
