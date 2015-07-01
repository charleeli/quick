local skynet = require 'skynet'
local Orm = require 'orm'
local TypeDef = require 'typedef'

local type_list = TypeDef.parse(
    skynet.getenv("orm_main") or 'main.orm',
    skynet.getenv("orm_path") or './service/agent/orm'
)

Orm.init(type_list)

local M = {}
function M.create_obj(cls_type, data)
    return Orm.create(cls_type, data)
end

function M.to_mongo(data)
    local ret = {}
    for k, v in pairs(data) do
        if type(v) == 'table' then
            ret[k] = M.to_mongo(v)
        else
            ret[k] = v
        end
    end
    return ret
end

function M.from_mongo(data)
    return data
end

function M.dump_mongo(obj, cls_type)
    assert(obj.__cls.name == cls_type, "dump mongo, class type unmatch")
    return M.to_mongo(obj)
end

function M.load_mongo(data, cls_type)
    assert(data, "load mongo, no data")
    return M.create_obj(cls_type, M.from_mongo(data))
end

return M
