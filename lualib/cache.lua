local Date = require 'date'

local Cache = class()

function Cache:ctor(obj,...)
    self._obj = obj
    self._ref_cnt = 0
    self.last_access_time = Date.second()
    self.last_save_time = Date.second()
end

function Cache:dtor()
end

function Cache:get_id()
    assert(false, 'Cache:get_id() must be implemented')
end

function Cache:_save()
    assert(false, 'Cache:_save() must be implemented')
end

function Cache:get_obj()
    return self._obj
end

function Cache:save()
    self:_save()
    self:update_save_time()
end

function Cache:inc_ref()
    self._ref_cnt = self._ref_cnt + 1
end

function Cache:dec_ref()
    self._ref_cnt = self._ref_cnt - 1
end

function Cache:has_ref()
    return self._ref_cnt > 0
end

function Cache:update_save_time()
    self.last_save_time = Date.second()
end

function Cache:update_access_time()
    self.last_access_time = Date.second()
end

return Cache

