local skynet = require "skynet"
local socket = require "socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"

local function response(id, ...)
    local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
    if not ok then
        skynet.error(string.format("fd = %d, %s", id, err))
    end
end

local function handle_home(args)
    return [[
        <html>
           <head>
             <script src="http://code.jquery.com/jquery-2.1.4.min.js"></script>
           </head>
           <body>welcome to quick cluster!</body>
        </html>
    ]]
end

local Cmd = {
    ['home'] = handle_home,--http://0.0.0.0:8080/quick?cmd=home
    ['json'] = handle_json,
}

skynet.start(function()
    skynet.dispatch("lua", function (_,_,id)
        socket.start(id)
        -- limit request body size to 8192 (you can pass nil to unlimit)
        local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
        if code then
            if code ~= 200 then
                response(id, code)
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
                        response(id, code, result)
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
                response(id, code, table.concat(tmp,"\n"))
            end
        else
            if url == sockethelper.socket_error then
                skynet.error("socket closed")
            else
                skynet.error(url)
            end
        end
        socket.close(id)
    end)
end)
