local Skynet = require "skynet"
local Lutil = require "lutil"
local Json = require 'json'
local Config = require 'config'
local LobbyClient = require "client.lobby"
local Socketchannel = require "socketchannel"

local fd = nil
local tcp_addr = nil
local tcp_port = nil
local udp_addr = nil
local udp_port = nil

local APPLY_TEAM_BATTLE = 1

local Cmd = {}

function Cmd.query_udp_addr()
    return Skynet.retpack{udp_ip = udp_addr, udp_port = udp_port}
end

function Cmd.apply_team_battle(room_id, stage_id, uuid_list)
    local s1 = Lutil.uint322netbytes(APPLY_TEAM_BATTLE)
    
    local t = {}
    t.room_id = room_id
    t.uuid_list = uuid_list
    t.stage_id = stage_id
  
    local data = Json:encode(t)
    local data_len = #data
    local s2 = Lutil.uint322netbytes(data_len)
    fd:request(s1..s2..data)
end

Skynet.start(function()
    Skynet.dispatch("lua", function(session, address, cmd, ...)
        local f = assert(Cmd[cmd])
        f(...)
    end)
    
    local bs_config = Config(Skynet.getenv('battle'))
    local bs_tcp_ip = bs_config.tcp.ip
    local bs_tcp_port = tonumber(bs_config.tcp.port)
    local bs_udp_ip = bs_config.udp.ip
    local bs_udp_port = tonumber(bs_config.udp.port)

    tcp_addr = bs_tcp_ip
    tcp_port = bs_tcp_port
    udp_addr = bs_udp_ip
    udp_port = bs_udp_port

    fd = Socketchannel.channel{
        host = bs_tcp_ip,
        port = bs_tcp_port,
    }
    fd:connect(true)
    
    assert(fd, "connect to battle<%s:%s> failed", bs_tcp_ip,bs_tcp_port)

    Skynet.fork(function()
        while true do
            local package = fd:response(function(sock)
                local ptype = sock:read(4)
                local pcontent_len = sock:read(4)
                ptype = Lutil.netbytes2uint32(ptype)
                pcontent_len = Lutil.netbytes2uint32(pcontent_len)
                
                local pcontent = sock:read(pcontent_len)

                LobbyClient.from_battle_proxy(ptype, pcontent_len, pcontent)

                return true, pcontent
            end)
        end
    end)

    Skynet.register('.battle_proxy')
    LOG_INFO("battle_proxy booted")
end)
