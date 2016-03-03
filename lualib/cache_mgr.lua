local Skynet = require 'skynet'
local Date = require 'date'
local Lock = require 'lock'
local Fork = require 'fork'
local class = require 'pl.class'
local CacheMgr = class()

function CacheMgr:_init(opts)
    self.hot_map = {}
    self.cold_map = {}
    self.gc_map = {}
    self.hot_cnt = 0
    self.cold_cnt = 0
    self.gc_cnt = 0
    self.gc_lock = Lock.new()
    self.last_swap_time = Date.second()

    self.cache_max_cnt = opts.max_cnt or 5000
    self.cache_ttl = opts.ttl or 1000
    self.cache_save_cd = opts.save_cd or 600
    self.fork_max = opts.fork_max or 1024
    self.is_running = false
end

function CacheMgr:add_hot(item_id, item)
    if self.hot_map[item_id] then
        return
    end
    
    self.hot_map[item_id] = item
    self.hot_cnt = self.hot_cnt + 1
    if self.hot_cnt < self.cache_max_cnt then
        return
    end

    local t_now = Date.second()
    local min_access_time = t_now - self.cache_ttl
    local old_cold_map = self.cold_map
    self.cold_map = self.hot_map
    self.cold_cnt = self.hot_cnt
    self.hot_map = {}
    self.hot_cnt = 0
    for item_id, item in pairs(old_cold_map) do
        if item:has_ref() and item.last_access_time > min_access_time then
            self:add_cold(item_id, item)
        else
            self:add_gc(item_id, item)
        end
    end

    local t_swap = t_now - self.last_swap_time
    self.last_swap_time = t_now
    LOG_INFO("db cache swap time<%s>", t_swap)
    Skynet.fork(self.gc, self)
end

function CacheMgr:del_hot(item_id)
    if not self.hot_map[item_id] then
        return
    end

    self.hot_map[item_id] = nil
    self.hot_cnt = self.hot_cnt - 1
end

function CacheMgr:add_cold(item_id, item)
    if self.cold_map[item_id] then
        return
    end
    
    self.cold_map[item_id] = item
    self.cold_cnt = self.cold_cnt + 1
end

function CacheMgr:del_cold(item_id)
    if not self.cold_map[item_id] then
        return
    end
    
    self.cold_map[item_id] = nil
    self.cold_cnt = self.cold_cnt - 1
end

function CacheMgr:add_gc(item_id, item)
    self.gc_map[item_id] = item
end

function CacheMgr:del_gc(item_id)
    self.gc_map[item_id] = nil
end

function CacheMgr:add_cache(item)
    self:add_hot(item:get_id(), item)
end

function CacheMgr:get_cache(item_id)
    local item = self.hot_map[item_id]
    if item then
        item:update_access_time()
        return item
    end

    item = self.cold_map[item_id]
    if item then
        self:del_cold(item_id)
        self:add_hot(item_id, item)
        item:update_access_time()
        return item
    end

    item = self.gc_map[item_id]
    if item then
        self:del_gc(item_id)
        self:add_hot(item_id, item)
        item:update_access_time()
        return item
    end

    return nil
end

function CacheMgr.gc_item(args)
    local self, item_id, item_obj = table.unpack(args)
    item_obj:save() 
    Skynet.sleep(10*100)
    self:del_gc(item_id) 
end

function CacheMgr:_gc()
    LOG_INFO("db cache gc begin")
    local t_begin = Skynet.now()
    local count = 0
    local gc_idx = 0
    while true do
        gc_idx = gc_idx + 1
        local item_list = {} 
        for item_id, item in pairs(self.gc_map) do
            table.insert(item_list, {self, item_id, item})
        end
        local item_num = #item_list
        if item_num == 0 then 
            break
        end

        count = count + item_num
        local t = Skynet.now()
        Fork.multi_fork(item_list, self.gc_item, self.fork_max)
        local time_cost = (Skynet.now() - t)/100
        LOG_INFO(
            "db cache sub gc<%s> end, time:%s, num:%s", 
            gc_idx, time_cost, item_num
        )
    end

    LOG_INFO(
        "db cache gc end, time:<%s>, num:<%s>",
         (Skynet.now() - t_begin)/100, count
    )
end

function CacheMgr:gc(force)
    if (not force) and self.gc_cnt >= 1 then
        LOG_INFO("gc is already running, ignore")
        return
    end

    if not next(self.gc_map) then
        return
    end

    self.gc_cnt = self.gc_cnt + 1
    self.gc_lock:lock_func(
        function()
            pcall(self._gc, self)
        end
    )
    
    self.gc_cnt = self.gc_cnt - 1
end

function CacheMgr:update()
    LOG_INFO("db cache update begin")
    
    local t = Skynet.now()
    local min_access_time = Date.second() - self.cache_ttl
    local min_save_time = Date.second() - self.cache_save_cd

    local remove_map = {}
    for item_id, item in pairs(self.hot_map) do
        if item.last_access_time < min_access_time then
            remove_map[item_id] = item
            self:add_gc(item_id, item)
        elseif item.last_save_time < min_save_time then
            self:add_gc(item_id, item)
        end
    end
    
    for item_id, item in pairs(remove_map) do
        self:del_hot(item_id)
    end

    local remove_map = {}
    for item_id, item in pairs(self.cold_map) do
        if item.last_access_time < min_access_time then
            remove_map[item_id] = item
            self:add_gc(item_id, item)
        elseif item.last_save_time < min_save_time then
            self:add_gc(item_id, item)
        end
    end

    for item_id, item in pairs(remove_map) do
        self:del_cold(item_id)
    end

    self:gc()
    
    LOG_INFO("db cache update end, time:<%s>", (Skynet.now() - t)/100)
end

function CacheMgr:start()
    self.is_running = true
    local update_interval = math.min(self.cache_ttl, self.cache_save_cd) * 100
    Skynet.fork(
        function()
            Skynet.sleep(update_interval)
            while self.is_running do
                local ok, err = pcall(self.update, self)
                if not ok then
                    LOG_INFO("db cache update err<%s>", err)
                end
                Skynet.sleep(update_interval)
            end
        end
    )
    
    LOG_INFO(
        "db cache is start, max_cnt<%s>, ttl<%s>, save_cd<%s>  update interval<%s>",
        self.cache_max_cnt, self.cache_ttl, self.cache_save_cd, update_interval/100
    )
end

function CacheMgr:exit()
    LOG_INFO("db cache exit begin")
    
    self.is_running = false
    local t = Skynet.now()
 
    for item_id, item in pairs(self.hot_map) do
        self:add_gc(item_id, item)
    end

    for item_id, item in pairs(self.cold_map) do
        self:add_gc(item_id, item)
    end

    self.hot_map = {}
    self.hot_cnt = 0
    self.cold_map = {}
    self.cold_cnt = 0
    
    local num = 0
    for k, v in pairs(self.gc_map) do
        num = num + 1
    end
    
    self:gc(true)
    
    LOG_INFO(
        "db cache exit end, time:<%s>, num<%s>", 
        (Skynet.now() - t)/100, num
    )
end

return CacheMgr

