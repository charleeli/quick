local Skynet = require "skynet"
local Acceptor = require 'acceptor'
local Connector = require 'connector'
local ClusterMonitorClient = require 'client.cluster_monitor'

local is_shutdown = false
local services_monitered = {}
local cluster_monitor_connector = nil

local function connect_cluster_monitor_cb(...)
    LOG_INFO("trying to connect cluster_monitor", ...)
    return ClusterMonitorClient.connect(...)
end

local function connected_cluster_monitor_cb()
    LOG_INFO("cluster_monitor is connected")
    
    local ret = ClusterMonitorClient.register_node(NODE_NAME, Skynet.self())
    if ret.errcode ~= ERRNO.E_OK then
        LOG_ERROR(
            "cluster_monitor is connected, register node fail, errcode<%s>",
            ret.errcode
        )
        return false
    end
    
    return true
end

local function disconnect_cluster_monitor_cb()
    LOG_ERROR("cluster_monitor is disconnect !")
    return true
end

local Cmd = {}

function Cmd.connect(...)
    return Acceptor.connect_handler(...)
end

function Cmd.register(service_addr, service_name)
    assert(service_addr, 'illgal service_addr')
    assert(service_name, 'illgal service_name')
    
    if is_shutdown then
        LOG_ERROR(
            "system is shutdown, register fail, addr<%s> type<%s>",
            service_addr, service_name
        )
        return
    end

    services_monitered[service_addr] = service_name
    
    LOG_INFO(
        "register service_addr<%x> service_name<%s>", 
        service_addr, service_name
    )
    
    local ret = ClusterMonitorClient.register_service_name(NODE_NAME,service_name)
    if ret.errcode ~= ERRNO.E_OK then
        LOG_ERROR(
            "cluster_monitor is connected, register_service_name fail, errcode<%s>",
            ret.errcode
        )
        return false
    end
end

function Cmd.unregister(service_addr)
    assert(service_addr, 'illgal service_addr')
    
    local service_name = services_monitered[service_addr]
    if not service_name then
        LOG_INFO("service<%x> exit", service_addr)
        return
    end
    
    services_monitered[service_addr] = nil
    
    LOG_INFO(
        "service<%s> exit, unregister service_name<%s>", 
        service_addr,service_name
    )
end

function Cmd.get_service_num(service_name)
    assert(service_name, 'illgal service_name')
    
    local count = 0
    for _addr, _name in pairs(services_monitered) do
        if _name == service_name then
            count = count + 1
        end
    end
    
    Skynet.retpack(count)
end

function Cmd.close_service(service_name)
    for _addr, _name in pairs(services_monitered) do
        if _name == service_name then
            LOG_INFO(
                "close service, addr<%s>, type<%s>", 
                _addr, _name
            )
            
            Skynet.send(_addr, "sys", "EXIT")
        end
    end
    
    Skynet.retpack({errcode = ERRNO.E_OK})
end

function Cmd.close_node()
    is_shutdown = true
    Skynet.retpack({errcode = ERRNO.E_OK})

    local seconds = 3
    LOG_INFO("node will close in %s seconds", seconds)
    Skynet.sleep(seconds * 100)
    Skynet.abort()
end

Skynet.register_protocol {
    name = "client",
    id = 3,
    unpack = function() end,
    dispatch = function(_, service_addr)
        Cmd.unregister(service_addr)
    end
}

Skynet.start(function()
    Skynet.dispatch("lua",function(session, addr, cmd, ...)
        local f = assert(Cmd[cmd], cmd)
        f(...)
    end)
    
    cluster_monitor_connector = Connector.new(
        connect_cluster_monitor_cb,
        connected_cluster_monitor_cb,
        disconnect_cluster_monitor_cb
    )
    cluster_monitor_connector:start()
    
    LOG_INFO('node_moniter booted')
end)

