package.cpath = "./3rd/skynet/luaclib/?.so;./build/luaclib/?.so"
package.path = package.path..';'.."./lualib/?.lua;./lualib/preload/?.lua"
require "luaext"

local Lsocket = require "lsocket"
local Lutil = require "lutil"
local Enet = require 'enet'
local Json = require 'json'
local Cfg = require 'config'
local GsBsCmd = require 'battle.gsbscmd'
local BufferMgr = require 'battle.buffer_mgr'

local BS_KEEP_RUN = true

local cfg = Cfg('./config/config.battle')
local TCP_ADDR = cfg.tcp.ip
local TCP_PORT = cfg.tcp.port
local TCP_BUFFER_ID = 1
local UDP_ADDRESS = cfg.udp.ip .. ':' .. cfg.udp.port

local tcp_read_sockets = {}
local tcp_write_sockets = {}
local tcp_socket_info = {}
local tcp_socket_receive = {}
local tcp_socket_send = {}

local connectinfo = {}
local userinfo = {}
local lobby = {}

local function add_socket(sock, ip, port)
    tcp_read_sockets[#tcp_read_sockets + 1] = sock
    tcp_write_sockets[#tcp_write_sockets + 1] = sock
    tcp_socket_info[sock] = {ip, port}
    tcp_socket_receive[sock] = BufferMgr:create_buffer(TCP_BUFFER_ID)
    tcp_socket_send[sock] = ""
    TCP_BUFFER_ID = TCP_BUFFER_ID + 1
end

local function del_socket(sock)
    local i, s
     
    for i, s in ipairs(tcp_read_sockets) do
        if s == sock then
            table.remove(tcp_read_sockets, i)
            break
        end
    end
    
    for i, s in ipairs(tcp_write_sockets) do
        if s == sock then
            table.remove(tcp_write_sockets, i)
            break
        end
    end
    
    tcp_socket_info[sock] = nil
    tcp_socket_receive[sock] = nil
    tcp_socket_send[sock] = nil
end

local function _bs2gs_send(sock, data)
    local send_data = tcp_socket_send[sock]
    tcp_socket_send[sock] = send_data .. data
end

local function _gs2bs_logic(sock, ptype, plength, pcontent)
    if ptype == GsBsCmd.APPLY_TEAM_BATTLE then
        local t = Json:decode(pcontent)
        local room_id = math.floor(t.room_id)
        local uuid_list = t.uuid_list
        local stage_id = math.floor(t.stage_id)
        
        local result = {}

        local flag = true
        for _, v in ipairs(uuid_list) do
            if not userinfo[v] then--userinfo还没有登记v
                flag = false
                break
            end
        end

        if flag then
            lobby[room_id] = {}
            for _, v in ipairs(uuid_list) do
                local user = userinfo[v]
                
                if user.room_id then--从旧的房间剔除
                    lobby[user.room_id][v] = nil
                    if not next(lobby[user.room_id]) then
                        lobby[user.room_id] = nil
                    end
                end
                
                user.room_id = room_id--加入新房间
                if not lobby[user.room_id] then
                    lobby[user.room_id] = {}
                end
                lobby[user.room_id][v] = true
            end

            result.room_id = room_id
            result.stage_id = stage_id
            result.flag = true
        else
            result.room_id = room_id
            result.stage_id = stage_id
            result.flag = false
        end
      
        local send_data = Json:encode(result)
        local send_type = Lutil.uint322netbytes(GsBsCmd.APPLY_TEAM_BATTLE_RESULT)
        local send_length = Lutil.uint322netbytes(#send_data)
        _bs2gs_send(sock, send_type .. send_length .. send_data)
    end
end

local function _gs2bs_cmd(sock, str)
    local buf = tcp_socket_receive[sock]
    buf:add(str)
    local ptype, plength, pcontent = buf:read()
    if ptype then
        if ptype <= 0 then
            BS_KEEP_RUN = false
        else
            _gs2bs_logic(sock, ptype, plength, pcontent)
        end
    end
end

local function _tcp_work(tcp_server_sock)
    local ready_read, ready_write = Lsocket.select(tcp_read_sockets, tcp_write_sockets, 0)
    if not ready_read then
        return
    end

    for _, sock in ipairs(ready_read) do
        if sock == tcp_server_sock then
			local s1, ip, port = sock:accept()
			print("Connection established from "..ip..", port "..port)
			add_socket(s1, ip, port)
        else
            local info = tcp_socket_info[sock]
			local str, err = sock:recv()
			if str ~= nil then
				print("recv from "..info[1]..":"..info[2])
				_gs2bs_cmd(sock, str)
			elseif err == nil then
				print("client "..info[1]..":"..info[2].." disconnected")
				sock:close()
				del_socket(sock)
			else
				print("error: "..err)
			end
        end
    end

    for _, sock in ipairs(ready_write) do
        if sock ~= tcp_server_sock then
            local info  = tcp_socket_info[sock]
            local sdata = tcp_socket_send[sock]
            if info and sdata and #sdata>0 then
                local nbytes = sock:send(sdata)
                if nbytes and nbytes > 0 then
                    print("write to "..info[1]..":"..info[2])
                    tcp_socket_send[sock] = string.sub(sdata, nbytes + 1, -1)
                end
            end
        end
    end
end

local function _client2bs_cmd(event)
    local data = event.data
    local peer = event.peer
    local t = Json:decode(data)
    local uuid = t.uuid

    local user = userinfo[uuid]
    if not user then
        user = {peer = peer}
        userinfo[uuid] = user --登记userinfo
        connectinfo[peer:connect_id()] = uuid
    else
        if user.peer:connect_id() ~= peer:connect_id() then
            user.peer:disconnect_now()
            connectinfo[user.peer:connect_id()] = nil
            user.peer = peer --更新userinfo
            connectinfo[user.peer:connect_id()] = uuid
        end
    end

    if user.room_id then
        local room = lobby[user.room_id] 
        if room then
            for k, v in pairs(room) do
                local u = userinfo[k]
                if u and u.peer then
                    u.peer:send(data)
                end
            end
        end
    end
end

local function _udp_work(udp_server_sock)
    local event = udp_server_sock:service(0)
    if event then
        if event.type == "receive" then
            print("got message:", event.data, event.peer)
            _client2bs_cmd(event)
        elseif event.type == "connect" then
            print("connect:", event.peer)
        elseif event.type == "disconnect" then
            print("disconnect", event.peer)
            local uuid = connectinfo[event.peer:connect_id()]
            if uuid then
                userinfo[uuid] = nil
                connectinfo[event.peer:connect_id()] = nil
            end
        end
    end
end

local function main()
    local tcp_server_sock, err = Lsocket.bind(TCP_ADDR, TCP_PORT, 10)
    if not tcp_server_sock then
        print("error " .. err)
        return
    end
    
    local server_socket = tcp_server_sock:info("socket")
    add_socket(tcp_server_sock, server_socket.addr, server_socket.port)
    print("tcp battle server booted")

    local udp_server_sock = Enet.host_create(UDP_ADDRESS)
    print("udp battle server booted")

    while BS_KEEP_RUN do
        _tcp_work(tcp_server_sock)
        _udp_work(udp_server_sock)
    end
end

main()
