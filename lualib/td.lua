local skynet = require 'skynet'
local json = require "cjson"
local typedef = require 'typedef'
local orm = require 'orm'

orm.init(typedef.parse(
    skynet.getenv("sproto_main") or 'main.sproto',
    skynet.getenv("sproto_path") or './service/agent/sproto/common'
))

local M = {}

function M.CreateObject(cls_type, raw_lua_value)
    return orm.create(cls_type, raw_lua_value)
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
    return json.encode(M.dump(td_object))
end

function M.LoadFromJSON(cls_type , raw_json_text)
    assert(raw_json_text, "load from json, no raw_json_text")
    return M.CreateObject(cls_type, json.decode(raw_json_text))
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
