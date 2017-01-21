local skynet = require "skynet"
local cluster = require "cluster"
local snax = require "snax"
local quick = require "quick"
local lfs = require"lfs"
local td = require "td"
local Message = require 'message'
local const = require 'const'
local env = require 'env'
local class = require 'pl.class'

local Role = class()

function Role:_init(role_td)
    assert(role_td, "new role has no role_td")
    self._role_td = role_td
    self.message = Message()
end

function Role:get_uid()
    return self._role_td.uid
end

function Role:get_account()
    return self._role_td.account
end

function Role:get_uuid()
    return self._role_td.uuid
end

function Role:get_role()
    return self._role_td
end

function Role:init_apis()
    LOG_INFO("init apis begin")
    
    local path = skynet.getenv('apispath') or './service/agent/apis'
    
    for file in lfs.dir(path) do
        local mod_name,suffix = file:match "([^.]*).(.*)"
        if suffix == 'lua' then
            local mod_obj = require('apis.' .. mod_name)
            
            if not mod_obj.apis then 
                error(string.format("illegal %s.apis", mod_name))
            end
            
            if not mod_obj.triggers then
                error(string.format("illegal %s.triggers", mod_name))
            end
            
            for func_name, func_obj in pairs(mod_obj.apis) do
                if func_name == nil or func_name == "" then
                    error(string.format("illegal func<%s>", func_name))
                end
                
                if Role[func_name] then
                    error(string.format("redefine func<%s>!", func_name))
                end
                
                Role[func_name] = func_obj
            end
            
            for evt_id, handler in pairs(mod_obj.triggers) do
                self.message:sub(evt_id, function(data) handler(self, data) end)
            end
        end
    end
    
    self:init_base_apis()
 
    LOG_INFO("init apis end")
end

function Role:lock_session(func_name,...)
    local ret = table.pack(
        env.session_lock:lock_session(func_name, self[func_name],self, ...)
    )

    if not ret[1] then
        LOG_ERROR("<%s>session lock fail", func_name)
        return {errcode = ERRNO.E_ERROR}
    end
    
    return table.unpack(ret, 2)
end

function Role:online()
    LOG_INFO("role online begin")

    local online_cli = cluster.snax(quick.center_node_name(), "online_snax")
    online_cli.req.online(NODE_NAME, skynet.self(), env.uid, env.subid)

    self.message:pub(const.EVT_ONLINE)

    LOG_INFO("role online end")
end

function Role:_offline()
    LOG_INFO("Role offline begin")

    local online_cli = cluster.snax(quick.center_node_name(), "online_snax")
    online_cli.req.offline(env.uid)

    env.timer:stop()

    self.message:pub(const.EVT_OFFLINE_BEGIN)
    
    LOG_INFO("session lock quit begin")
    env.session_lock:lock_quit()
    LOG_INFO("session lock quit end")
    
    self.message:pub(const.EVT_OFFLINE)

    local suc = self:save_db()
    LOG_INFO("Role offline end")
    return suc
end

function Role:offline()
    local ok, ret = pcall(self._offline, self)
    if ok then
        LOG_INFO("normal offline<%s>", ret)
        return ret
    end

    LOG_ERROR("error when offline, err<%s>", ret)
    self:save_db()
    return false
end

function Role:save_db()
    local gamedb_snax = snax.uniqueservice("gamedb_snax")

    local suc = gamedb_snax.req.set(self:get_account(),td.DumpToJSON('Role', self._role_td))

    LOG_INFO('role <account = %s> save db <%s>', self:get_account(), suc)
    return suc
end

function Role:gen_base_proto()
    local base = self:get_base()
    
    if not base then
        return nil
    end

    return {
        name = base.name,
        gender = base.gender,
        exp = base.exp,
        level = base.level,
        vip = base.vip,
    }
end

function Role:gen_proto()
    local ret = {}
    ret.uid = self._role_td.uid
    ret.account = self._role_td.account
    ret.uuid = self._role_td.uuid
    ret.base = self:gen_base_proto()
    
    return ret
end

return Role
