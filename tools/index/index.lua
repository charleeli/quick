package.cpath = "../../build/luaclib/?.so"
local LFS = require 'lfs'

local function isfile(name)
    local f=io.open(name,"r")
    if f then 
        io.close(f) 
        return true 
    end 
        
    return false 
end

local db_config_fpath  = '../../config/config.database'
local db_config = {}
loadfile(db_config_fpath, "t", db_config)()

local cmd_list = {}
local function create_cmd(js_name, db_cfg)
    local host = db_cfg.host
    local port = db_cfg.port
    local dbname = db_cfg.db
    local username = db_cfg.username
    local password = db_cfg.password
    local script = string.format("%s/%s.js", LFS.currentdir(), js_name)
    if not isfile(script) then
        local s = string.format("[ERROR]js not exists, path<%s>", script)
        print(s)
        os.exit(1)
    end

    if username == nil and password == nil then
        local cmd = string.format(
            "mongo %s:%s/%s %s",
            host, port, dbname, script
        )
        table.insert(cmd_list, cmd)
        return
    end

    if username ~= nil and password ~= nil then
        local cmd = string.format(
            "mongo %s:%s/%s -u %s -p %s %s",
            host, port, dbname, username, password, script
        )
        table.insert(cmd_list, cmd)
        return
    end
    
    local s = string.format(
        "[ERROR]illegal db cfg, cfg path<%s> db type:<%s>",
        db_config_fpath, js_name
    )
    print(s)
    os.exit(1)
end

-- create cmd by mongodb config
create_cmd("gamedb", db_config.gamedb)

-- run cmd
for _,v in ipairs(cmd_list) do
    print(string.format("[SCRIPT]<%s>", v))
    local ok, ret, code = os.execute(v)
    print(string.format("[RESULT]suc<%s>, ret<%s>, code<%s>\n", ok, ret, code))
    if code ~= 0 then
        os.exit(code)
    end
    
    if not ok then
        os.exit(2)
    end

    if ret ~= 'exit' then
        os.exit(3)
    end
end
