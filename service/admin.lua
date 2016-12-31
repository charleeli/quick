local skynet = require "skynet"
local socket = require "socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local json = require "cjson"
local OnlineClient = require 'client.online'
local ClusterMonitorClient = require 'client.cluster_monitor'

local function response(id, ...)
    local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
    if not ok then
        -- if err == sockethelper.socket_error , that means socket closed.
        skynet.error(string.format("fd = %d, %s", id, err))
    end
end

local function quick_shutdown(args)
    LOG_INFO('request the whole quick cluster shutdown')
    ClusterMonitorClient.shutdown()
    return "the whole quick cluster will shutdown\n"
end

local function quick_reload_res(args)
    LOG_INFO('request the whole quick cluster reload_res')
    local ret = ClusterMonitorClient.reload_res()
    return json.encode(ret.result)
end

local function quick_kick(args)
    LOG_INFO('request the whole quick cluster kick')
    
    local ret = OnlineClient.kick(tonumber(args.uid),"force kick")
    if ret.errcode ~= ERRNO.E_OK then
        LOG_INFO("kick uid<%s> fail,errcode<%s>",uid,ret.errcode)
    end
    
    return json.encode(ret)
end

local Cmd = {
    ['shutdown']    = quick_shutdown,   --http://0.0.0.0:8080/quick?cmd=shutdown
    ['reload_res']  = quick_reload_res, --http://0.0.0.0:8080/quick?cmd=reload_res
    ['kick']        = quick_kick,       --http://0.0.0.0:8080/quick?cmd=kick&uid=6
}

skynet.start(function()
    local admin_port = tonumber(skynet.getenv("admin_port"))
  
    local master_id = socket.listen("0.0.0.0", admin_port)
    LOG_INFO("Listen admin port %s",admin_port)

    socket.start(master_id , function(master_id, addr)
        socket.start(master_id)
       
        local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(master_id), 8192)
        if code then
            if code ~= 200 then
                response(master_id, code)
            else
                local tmp = {}
                
                if header.host then
                    table.insert(tmp, string.format("host: %s", header.host))
                end
                
                local path, query = urllib.parse(url)
                if path ~= '/quick' then
                    response(master_id, code, "path error")
                end
                table.insert(tmp, string.format("path: %s", path))
                
                if query then
                    local q = urllib.parse_query(query)
                    
                    local cmd = q['cmd']
                    if cmd and Cmd[cmd] then
                        local result = Cmd[cmd](q)
                        table.insert(tmp, string.format("result = %s",result))
                    end
                    
                    for k, v in pairs(q) do
                        table.insert(tmp, string.format("query: %s = %s", k,v))
                    end
                end
                table.insert(tmp, "-----header----")
                
                for k,v in pairs(header) do
                    table.insert(tmp, string.format("%s = %s",k,v))
                end
                table.insert(tmp, "-----body----\n" .. body)
                
                response(master_id, code, table.concat(tmp,"\n"))
            end
        else
            if url == sockethelper.socket_error then
                skynet.error("socket closed")
            else
                skynet.error(url)
            end
        end
        socket.close(master_id)
    end)

    skynet.register('.admin')
    LOG_INFO("admin booted, admin <%s>", admin_port)
end)
