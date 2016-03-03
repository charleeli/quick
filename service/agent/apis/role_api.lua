local skynet = require "skynet"
local snax = require "snax"
local Cluster = require 'cluster'
local Lock = require 'lock'
local SessionLock = require 'session_lock'
local Date = require 'date'
local TimerMgr = require 'timer_mgr'
local Const = require 'const'
local Bson   = require 'bson'
local Env = require 'env'
local Role = require 'cls.role'
local td = require "td"

local M = {}

M.load_role_lock = Lock.new()

function M.start(env)
    Env.uid = env.uid
    Env.zinc_client = env.zinc_client

    if not Env.uid then
        LOG_ERROR("msgagent start fail, no uid")
        return false
    end

    Env.session_lock = SessionLock()

    LOG_INFO('msgagent start, uid<%s>', Env.uid)
    return true
end

function M.reset_timer()
    if Env.timer_mgr then
        Env.timer_mgr:stop()
    end
    Env.timer_mgr = TimerMgr.new(8)
end

function M._load_role(role_td)
    local role = Role(role_td)
    Env.role = role
    role:init_apis()
 
    M.reset_timer()
    Env.timer_mgr:add_timer(
        120,
        function()
            role:save_db() 
        end
    )
    
    Env.timer_mgr:add_timer(
        18,
        function() 
            role:check_cron_update()
        end
    )
    
    Env.timer_mgr:add_timer(
        Const.MAIL_UPDATE_INTERVAL,
        function()
            role:lock_session('update_mailbox')
        end
    )

    Env.timer_mgr:start()
    collectgarbage("collect")
    return role
end

function M.load_role()
    return M.load_role_lock:lock_func(function()
        assert(Env.uid)
        Env.account = tostring(Env.uid) --TODO:暂时第三方账号即为游戏服账号
        
        if not Env.role then
            local gamedb_snax = snax.uniqueservice("gamedb_snax")

            local raw_json_text = gamedb_snax.req.get(Env.account)

            local role_td
            if not raw_json_text then
                role_td = M.create_role("charleeli", 1)
            else
                role_td =  td.LoadFromJSON('Role',raw_json_text)
            end

            M._load_role(role_td)
            Env.role:online()
        end
        
        LOG_INFO(
            'load role<%s|%s|%s>',
            Env.account,Env.role:get_uid(), Env.role:get_uuid()
        )
       
        return Env.role:gen_proto()
    end)
end

function M.create_role(name, gender)
    local role = td.CreateObject('Role')
    local _,new_uuid = Bson.type(Bson.objectid())
    
    role.uid = Env.uid
    role.account = Env.account
    role.uuid = new_uuid
    
    role.base.uid = Env.uid
    role.base.name = name or 'anonym'
    role.base.gender = gender or 1
    role.base.exp = 0
    role.base.level = 1
    role.base.vip = 0

    local gamedb_snax = snax.uniqueservice("gamedb_snax")

    local ret = gamedb_snax.req.set(Env.account,td.DumpToJSON('Role', role))

    if not ret then
        LOG_ERROR('ac: <%s> create fail', Env.account)

        return {errcode = -2}

    end

    LOG_INFO(
        "create_role, uid<%s>,account<%s>, uuid<%s>, name<%s>, gender<%s>",
        role.uid,role.account, role.uuid, role.base.name, role.base.gender
    )

    local self = M._load_role(role)
    self:online()
    return {errcode = 0}
end

local alread_close = false

-- 0-成功下线 1-下线失败 2-已经下线
function M.close()
    local ok, msg = pcall(function()
        if alread_close then
            return 2
        end

        skynet.fork(function()
            local ts = Date.second()
            while true do
                local now = Date.second()
                if now - ts > 300 then
                    LOG_ERROR("msgagent close failed in 5 mins")
                    if Env.role then
                        Env.role:save_db()
                    end

                    LOG_ERROR("agent force offline!")
                    break
                end
                skynet.sleep(5*100)
            end
        end)
        alread_close = true

        if Env.role then
            if not Env.role:offline() then
                return 1
            end
        end
        
        return 0
    end)
    
    return ok
end

local triggers = {
}

return {apis = M, triggers = triggers}
