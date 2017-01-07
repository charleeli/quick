local skynet = require "skynet"
local socket = require "socket"
local string = string
local webpage = require "webpage"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local json = require "cjson"
local OnlineClient = require 'client.online'
local ClusterMonitorClient = require 'client.cluster_monitor'

local function response(id, code, result,header)
    local statusline = string.format("HTTP/1.1 %03d %s\r\n", code, "")
	sockethelper.writefunc(id)(statusline)
    sockethelper.writefunc(id)(string.format("content-type: text/html\r\n"))
    local ok, err = httpd.write_response(sockethelper.writefunc(id), code, result)
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

local function index()
    webpage.load("./service/admin/html/index.html")
    webpage.set("prompt", "Welcome to index page!")
    webpage.set("runtime", math.floor(skynet.now()/100))
    webpage.set_block("INDEX")
    return webpage.render()
end

local function login(args)
    if(args["username"] ~= "admin" or args["password"] ~= "admin") then
        webpage.load("./service/admin/html/login.html");
        return webpage.render()
    end

    return index()
end

local Cmd = {
    ['shutdown']    = quick_shutdown,   --http://0.0.0.0:10086/quick?cmd=shutdown
    ['reload_res']  = quick_reload_res, --http://0.0.0.0:10086/quick?cmd=reload_res
    ['kick']        = quick_kick,       --http://0.0.0.0:10086/quick?cmd=kick&uid=6
    ['index']       = index,            --http://0.0.0.0:10086/quick?cmd=index
    ['login']       = login,            --http://0.0.0.0:10086/quick?cmd=login&username='admin'&password='admin'
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
                local path, query = urllib.parse(url)
                if path ~= '/quick' then
                    response(master_id, code, "path error")
                end
                
                if query then
                    local q = urllib.parse_query(query)
                    
                    local cmd = q['cmd']
                    if cmd and Cmd[cmd] then
                        local result = Cmd[cmd](q)
                        response(master_id, code, result)
                    end
                end
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
