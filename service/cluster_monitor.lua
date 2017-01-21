local skynet = require "skynet"
local cluster = require "cluster"
local acceptor = require 'acceptor'
local connector = require 'connector'
local date = require 'date'

local is_shutdown = false
local node_monitors = {}
local service_name_list = {}

local function _call(node_name, service_addr, ...)
    if NODE_NAME == node_name then
        return pcall(skynet.call, service_addr, 'lua', ...)
    end
    return pcall(cluster.call, node_name, service_addr, ...)
end

local function _close_node(node_name, monitor_addr)
    skynet.fork(function()
        local ok, ret = pcall(
            cluster.call,node_name, monitor_addr, 'close_node'
        )
        
        if not ok then
            LOG_ERROR(
                "close node fail, node:<%s>, err<%s>",
                node_name, ret
            )
        end
    end)
end

local function _close_service_bytype(service_name)
    for node_name, info in pairs(node_monitors) do
        local monitor_addr = info.addr
        skynet.fork(function()
            LOG_INFO(
                "try close service, node:<%s>, service_name<%s>", 
                node_name, service_name
            )
                
            local ok, ret = _call( 
                node_name, monitor_addr, 'close_service', service_name
            )
            
            if not ok then
                LOG_ERROR(
                    "close service fail, node:<%s>, service_name<%s>, err<%s>",
                    node_name, service_name, ret
                )
            end
        end)
    end

    while true do
        local all_ok = true
        local count = 0
        for node_name, info in pairs(node_monitors) do
            local monitor_addr = info.addr
            
            local ok, ret
            if NODE_NAME == node_name then
                ok, ret = pcall(
                    skynet.call,monitor_addr, 'lua', 'get_service_num',service_name
                )
            else
                ok, ret = pcall(
                    cluster.call,node_name, monitor_addr, 'get_service_num',service_name
                )
            end

            if ok then
                if ret > 0 then
                    LOG_INFO(
                        "waiting node<%s> service_name<%s> exit: %s left",
                        node_name, service_name, ret
                    )
                    count = count + ret
                end
            else
                all_ok = false
                LOG_ERROR(
                    "get service num fail, node:<%s>, service_name<%s>, err<%s>",
                    node_name, service_name, ret
                )
            end
        end

        if all_ok and count == 0 then
            break
        end

        LOG_INFO(
            "waiting all %s service exit: %s left, all ok<%s>", 
            service_name, count, all_ok
        )
        
        skynet.sleep(1 * 100)
    end
end

local Cmd = {}

function Cmd.connect(...)
    local r = acceptor.connect_handler(...)
    skynet.retpack(r)
end

function Cmd.unregister_node(node_name, version)
    local info = node_monitors[node_name]
    if not info then return end
    
    if version ~= nil then
        if info.version ~= version then
            LOG_INFO(
                "unregister node<%s> fail, version error, now<%s>, want<%s>",
                node_name, info.version, version
            )
        end
    end

    node_monitors[node_name] = nil
    
    if info.connector then
        info.connector:stop()
    end
    
    LOG_INFO("unregister node<%s> version<%s>", node_name, info.version)
end

function Cmd.register_node(node_name, node_monitor_addr)
    if is_shutdown then
        LOG_ERROR("reset node<%s> fail, is shutdown", node_name)
        return skynet.retpack({errcode = ERRCODE.E_ERROR})
    end

    Cmd.unregister_node(node_name)

    local version = string.format("%s-%s",date.second(),math.random(1, 1000000))
  
    local node_monitor_connector = connector(
        function(...)
            local ok, ret = _call(node_name, node_monitor_addr,'connect', ...)
            if not ok then
                return {errcode = ERRCODE.E_ERROR}
            end
            return ret
        end,

        function(...)
            LOG_INFO("node<%s> is connected", node_name)
            return true
        end,

        function(...)
            LOG_INFO("node<%s> is disconnected, unregister", node_name)
            Cmd.unregister_node(node_name, version)
        end
    )

    node_monitors[node_name] = {
        addr = node_monitor_addr,
        connector = node_monitor_connector,
        version = version,
    }
    node_monitor_connector:start()

    LOG_INFO(
        "register node<%s> suc, monitor<%s>, version<%s>",
        node_name, node_monitor_addr, version
    )

    return skynet.retpack({errcode = ERRCODE.E_OK})
end

function Cmd.register_service_name(node_name, service_name)
    if is_shutdown then
        LOG_ERROR("register_service_name<%s> fail, is shutdown", node_name)
        return skynet.retpack({errcode = ERRCODE.E_ERROR})
    end
    
    if not node_monitors[node_name] then
        LOG_ERROR("register_service_name fail, <%s>is's registered", node_name)
        return skynet.retpack({errcode = ERRCODE.E_ERROR})
    end
    
    service_name_list[service_name] = true
    
    LOG_INFO("<%s>register_service_name <%s> succeed",node_name,service_name)
    return skynet.retpack({errcode = ERRCODE.E_OK})
end

function Cmd.shutdown()
    skynet.retpack({errcode = ERRCODE.E_OK})
    
    LOG_INFO("system begin shutdown")
    is_shutdown = true

    for service_name,_ in pairs(service_name_list) do
        LOG_INFO("trying to close service<%s>", service_name)
        _close_service_bytype(service_name)
    end

    for node_name, info in pairs(node_monitors) do
        if node_name ~= NODE_NAME then
            LOG_INFO("trying to close other node<%s>", node_name)
            _close_node(node_name, info.addr)
        end
    end

    LOG_INFO("trying to close node<%s>", NODE_NAME)
    
    local seconds = 8
    LOG_INFO("cluster will shutdown in %s seconds", seconds)
    skynet.sleep(seconds * 100)
    skynet.abort()
end

function Cmd.reload_res()
    LOG_INFO("system begin reload_res")
    
    local count = 0
    local result = {}
    
    for node_name, info in pairs(node_monitors) do
        local ok, ret = pcall(
            cluster.call,node_name, info.addr, 'reload_res'
        )
        
        if not ok then
            LOG_ERROR(
                "reload_res fail, node:<%s>, err<%s>",
                node_name, ret
            )
        end
        
        count = count + 1
        table.insert(result,{
            node = node_name,
            reloaded = ret.errcode == ERRCODE.E_OK
        })
    end

    LOG_INFO("system end reload_res")
    skynet.retpack({errcode = ERRCODE.E_OK, result = result})
end

skynet.start(function ()
    skynet.dispatch("lua", function(session, addr, cmd, ...)
        local f = assert(Cmd[cmd], cmd)
        f(...)
    end)

    skynet.register('.cluster_monitor')
    LOG_INFO("cluster_monitor booted")
end)

