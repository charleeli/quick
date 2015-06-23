local Skynet = require 'skynet'
local Mongo = require 'mongo'
local Bson = require 'bson'

local MongoObj = class()

function MongoObj:ctor(db_cfg)
    local db = Mongo.client( db_cfg )
    local db_name = db_cfg.db
    db:getDB(db_name)
    self._db = db[db_name]
end

local ops = {'insert', 'batch_insert', 'delete'}
for _, v in ipairs(ops) do
    MongoObj[v] = function(self, tname, ...)
        local c = self._db[tname]
        c[v](c, ...)
        local r = self._db:runCommand('getLastError')
        local ok = r and r.ok == 1 and r.err == Bson.null
        if not ok then
            LOG_ERROR(v.." failed: ", r.err, tname, ...)
        end
        return ok, r.err
    end
end

function MongoObj:update(tname, ...)
    local c = self._db[tname]
    c:update(...)
    local r = self._db:runCommand('getLastError')
    if r.err ~= Bson.null then
        LOG_ERROR("update failed, tname:" .. tname .. "err:" .. r.err, ...)
        return false, r.err
    end

    local ok = r.n > 0
    if not ok then
        LOG_INFO("update failed, tname:" .. tname, ...)
    end
    return ok, r.err
end

function MongoObj:find(tname, selector_tbl, field_selector_tbl)
    local db = self._db

    local it = db[tname]:find(selector_tbl, field_selector_tbl)
    
    return it
end

function MongoObj:find_one(tname, selector_tbl, field_selector_tbl)
    local db = self._db
    local ret = db[tname]:findOne(selector_tbl, field_selector_tbl)
    if (ret ~= nil) then
        ret._id = nil
    end

    return ret
end

return MongoObj
