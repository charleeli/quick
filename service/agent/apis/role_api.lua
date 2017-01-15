local snax = require "snax"
local td = require "td"
local Lock = require 'lock'
local bson = require 'bson'
local env = require 'env'
local Role = require 'cls.role'

local M = {}

M.load_role_lock = Lock()

function M._load_role(role_td)
    local role = Role(role_td)
    env.role = role
    role:init_apis()

    env.timer:set_interval(60, function()
        role:save_db()
    end)
    
    env.timer:set_interval(20, function()
        role:check_cron_update()
    end)
    
    env.timer:set_interval(80, function()
        role:lock_session('update_mailbox')
    end)

    collectgarbage("collect")
    return role
end

function M.load_role()
    return M.load_role_lock:lock_func(function()
        assert(env.uid)
        env.account = tostring(env.uid) --TODO:暂时第三方账号即为游戏服账号
        
        if not env.role then
            local gamedb_cli = snax.uniqueservice("gamedb_snax")

            local raw_json_text = gamedb_cli.req.get(env.uid)

            local role_td
            if not raw_json_text then
                role_td = M.create_role("charleeli", 1)
            else
                role_td =  td.LoadFromJSON('Role',raw_json_text)
                M._load_role(role_td)
                env.role:online()
            end
        end
        
        LOG_INFO(
            'load role<%s|%s|%s>',
            env.account,env.role:get_uid(), env.role:get_uuid()
        )

        return env.role:gen_proto()
    end)
end

function M.create_role(name, gender)
    local role = td.CreateObject('Role')
    local _,new_uuid = bson.type(bson.objectid())
    
    role.uid = env.uid
    role.account = env.account
    role.uuid = new_uuid
    
    role.base.uid = env.uid
    role.base.name = name or 'anonym'
    role.base.gender = gender or 1
    role.base.exp = 0
    role.base.level = 1
    role.base.vip = 0

    local gamedb_cli = snax.uniqueservice("gamedb_snax")

    local ret = gamedb_cli.req.set(env.uid, td.DumpToJSON('Role', role))

    if not ret then
        LOG_ERROR('ac: <%d> create fail', env.uid)
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

local triggers = {
}

return {apis = M, triggers = triggers}
