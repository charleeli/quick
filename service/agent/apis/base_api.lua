local Date = require 'date'
local Const = require 'const'
local Notify = require 'notify'

local apis = {}

function apis:get_base()
    return self._role_td.base
end

function apis:_need_daily_update()
    local t_now = Date.second()
    local t_prev = self._role_td.base.daily_update_time
    
    if t_now > t_prev + Const.ONE_DAY_SECONDS then
        return true
    end

    local t_daily_update = Date.get_today_time(
        Const.ROLE_DAILY_UPDATE_HOUR, 0, 0
    )
    
    return t_prev < t_daily_update
end

function apis:daily_update()
    LOG_INFO("daily update begin")
    
    self._role_td.base.daily_update_time = Date.second()
    self.message:pub(Const.EVT_DAILY_UPDATE)
    Notify.daily_update()
    
    LOG_INFO("daily update end")
end

function apis:check_cron_update()
    if self:_need_daily_update() then
        self:lock_session('daily_update')
    end
end

function apis:init_base_apis()
    LOG_INFO("init base apis begin")
    local base = self:get_base()

    for name,_ in pairs(base) do
        if not apis['get_'..name] then
            self['get_'..name] = function(self)
                return base[name]
            end
        end
        
        if not apis['set_'..name] then
            self['set_'..name] = function(self, new_value)
                assert(new_value >= 0)
               
                local old_value = base[name]
                base[name] = new_value
                LOG_INFO('set_%s, old<%s> new<%s>', name, old_value, new_value)

                return {
                    errcode = ERRNO.E_OK,
                    base = self:gen_base_proto()
                }
            end
        end
        
        if not apis['add_'..name] then
            self['add_'..name] = function(self, value)
                assert(value >= 0)
                
                local old_value = base[name]
                local new_value = old_value + value
                base[name] = new_value
          
                LOG_INFO(
                    'add_%s, val<%s>, old<%s> new<%s>',
                    name, value, old_value, new_value
                )

                return {
                    errcode = ERRNO.E_OK,
                    base = self:gen_base_proto()
                }
            end
        end
        
        if not apis['sub_'..name] then
            self['sub_'..name] = function(self, value)
                assert(value >= 0)
               
                local old_value = base[name]
                local new_value = old_value - value
                if new_value < 0 then
                    LOG_ERROR(
                        'sub_%s, val<%s>, old<%s>, not enough',
                        name, value, old_value
                    )
                    new_value = 0
                end
                base[name] = new_value
                
                LOG_INFO(
                    'sub_%s, val<%s>, old<%s> new<%s>', 
                    name, value, old_value, new_value
                )

                return {
                    errcode = ERRNO.E_OK,
                    base = self:gen_base_proto(),
                }
            end
        end
    end
    LOG_INFO("init base apis end")
end

local triggers = {
    [Const.EVT_ONLINE] = function(self)
        LOG_INFO('base module trigger event online.')
    end,
    
    [Const.EVT_OFFLINE_BEGIN] = function(self)
        LOG_INFO('base module trigger event offline begin.')
    end,
    
    [Const.EVT_OFFLINE] = function(self)
        LOG_INFO('base module trigger event offline (end).')
    end,
}

return {apis = apis, triggers = triggers}
