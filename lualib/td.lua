local skynet = require 'skynet'
local JSON = require "JSON"
local TypeDef = require 'typedef'
local Orm = require 'orm'

Orm.init(TypeDef.parse(
    skynet.getenv("td_main") or 'main.td',
    skynet.getenv("td_path") or './service/agent/td'
))

local M = {}

function M.CreateObject(cls_type, raw_lua_value)
    return Orm.create(cls_type, raw_lua_value)
end

function M.dump(td_object)
    local ret = {}
    for k, v in pairs(td_object) do
        if type(v) == 'table' then
            ret[k] = M.dump(v)
        else
            ret[k] = v
        end
    end
    return ret
end

function M.DumpToJSON(cls_type, td_object)
    assert(td_object.__cls.name == cls_type, "dump to json, class type unmatch")
    return JSON:encode(M.dump(td_object))
end

function M.LoadFromJSON(cls_type , raw_json_text)
    assert(raw_json_text, "load from json, no raw_json_text")
    return M.CreateObject(cls_type, JSON:decode(raw_json_text))
end

function M.DumpToLUA(cls_type, td_object)
    assert(td_object.__cls.name == cls_type, "dump to lua, class type unmatch")
    return M.dump(td_object)
end

function M.LoadFromLUA(cls_type , raw_lua_value)
    assert(raw_lua_value, "load from raw_lua_value, no raw_lua_value")
    return M.CreateObject(cls_type, raw_lua_value)
end

return M
