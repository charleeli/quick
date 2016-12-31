local skynet = require "skynet"
local socket = require "socket"

skynet.start(function()
    local worker_num = tonumber(skynet.getenv("web_worker_num")) or 4

    local worker = {}
    for i= 1, worker_num do
        worker[i] = skynet.newservice("web_worker")
    end
    
    local web_port = tonumber(skynet.getenv("web_port"))
    local balance = 1
    local id = socket.listen("0.0.0.0", web_port)
    LOG_INFO("Listen web port %s",web_port)
    
    socket.start(id , function(id, addr)
        if not worker[balance] then
            worker[balance] = skynet.newservice("web_worker")
            LOG_INFO('add worker<%s>', balance)
        end
        
        skynet.send(worker[balance], "lua", id)
        LOG_INFO(
            string.format("%s connected, pass it to worker :%08x", 
            addr, worker[balance])
        )
        
        balance = balance + 1
        if balance > #worker then
            balance = 1
        end
    end)
    
    skynet.register('.web_master')
    LOG_INFO("web_master booted, web_port<%s>", web_port)
end)
