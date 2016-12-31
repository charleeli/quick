local skynet = require "skynet"
local socket = require "socket"
local string = require "string"

skynet.start(function()
    local worker_num = tonumber(skynet.getenv("ws_worker_num")) or 4

    local worker = {}
    for i= 1, worker_num do
        worker[i] = skynet.newservice("ws_worker")
    end

    local ws_worker_port = tonumber(skynet.getenv("ws_worker_port")) or 9527
    local balance = 1
    local id = socket.listen("0.0.0.0", ws_worker_port)
    LOG_INFO("Listen ws worker port %s",ws_worker_port)

    socket.start(id , function(id, addr)
        if not worker[balance] then
            worker[balance] = skynet.newservice("ws_worker")
            LOG_INFO('add ws_worker<%s>', balance)
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
end)
