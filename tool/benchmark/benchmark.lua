package.cpath = "../../3rd/skynet/luaclib/?.so;../../build/luaclib/?.so;../../build/luaclib/levent/?.so;"
local service_path = "../../lualib/?.lua;" .. "../../service/?.lua;"
        .. "../../lualib/preload/?.lua;".."../../build/lualib/?.lua;"
package.path = package.path ..";../../3rd/skynet/lualib/?.lua;../../3rd/skynet/service/?.lua;"
        .. service_path

local levent = require "levent.levent"
local timeout = require "levent.timeout"
local queue  = require "levent.queue"
local argparse = require "argparse"
local Robot = require 'robot'
require "luaext"

local timeoutSec = 2 --脚本执行超时时间 秒

local first_send_time = 0 --第一个协程发送开始时间
local last_send_time = 0  --最后一个协程发送开始时间
local first_recv_time = 0 --第一个协程接收开始时间
local last_recv_time = 0  --最后一个协程接收开始时间

local sendCh = queue.queue()--所有发送的信息
local recvCh = queue.queue()--所有接收的消息
local resmap = {}--结果分析表

local function init_argparse()
    local parser = argparse()
    parser:description("Cmd Client")

    parser:option("-a --host"):default("127.0.0.1"):description("Server IP")
    parser:option("-p --port"):default("5189"):description("Server Port"):convert(tonumber)
    parser:option("-c --concurrency"):default("2"):description("Concurrency"):convert(tonumber)
    parser:option("-s --script"):description("Script")
    return parser
end

local function asyncCall(co_id,concurrency,host,port,script)
    local interval = 1/concurrency
    levent.sleep(co_id * interval)

    local robot = Robot()
    robot.account = "test_account_"..co_id
    robot:login("dg56vs38", co_id, true) --登陆
    
    local _,nodelay = timeout.run(0, function()
        return timeout.run(timeoutSec, robot.run_script,robot,script)
    end)
 
    if last_send_time ==0 or last_send_time < robot.first_send_time then
        last_send_time = robot.first_send_time--可能有并发写安全问题
    end
    
    for i=1,#robot.sendCh do
        local e = robot.sendCh:get()
        sendCh:put(e)
    end
    
    for i=1,#robot.recvCh do
        local e = robot.recvCh:get()
        recvCh:put(e)
    end
end

local function main()
    local args = init_argparse():parse()
    table.print(args)
    if not args.script then
        print('no script!')
        return 
    end
  
    for co_id =1,args.concurrency do
        levent.spawn(asyncCall,co_id,args.concurrency,args.host,args.port,args.script)
    end
    
    --等待所有协程完成
    print("please wait servial seconds...")
    levent.sleep(3)  

    --print('-------------------------------------------')
    local send_count = #sendCh
    for i = 1,send_count do
        local info = sendCh:get()
        --print(info.session,info.send_time,info.cmd,info.args)
        if first_send_time == 0 or first_send_time > info.send_time then
            first_send_time = info.send_time
        end
            
    end
    
    --print('-------------------------------------------')
    local recv_count = #recvCh
    for i = 1, recv_count do
        local info = recvCh:get()
        --print(info.elapse,info.errcode,info.session,info.recv_time,info.cmd,info.args)
        if first_recv_time == 0 or first_recv_time > info.recv_time then
            first_recv_time = info.recv_time
        end
        
        if last_recv_time == 0 or last_recv_time < info.recv_time then
            last_recv_time = info.recv_time
        end
        
        if not resmap[info.cmd] then
            resmap[info.cmd] = {count = 1, elapse=info.elapse}
        else
            resmap[info.cmd] = {
                count  = resmap[info.cmd].count  + 1,
                elapse = resmap[info.cmd].elapse + info.elapse,
            } 
        end
    end
    
    print('-------------------------------------------')
    for k,v in pairs(resmap) do
        print(k, v.count, v.elapse/v.count)
    end

    print('-------------------------------------------')
    if args.concurrency >= 2 then
        local duration = last_send_time - first_send_time
        print("duration:",duration)
        print("qps:",send_count/duration)
        print("tps:",recv_count/(last_recv_time - first_recv_time))
        print("concurrency:",args.concurrency/duration)
    end

end

levent.start(main)

