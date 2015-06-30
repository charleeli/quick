is_windows, is_client = ...

local DumpApi = require 'datadump'
local EncodeC = {}
EncodeC.u82a = function(str) return str end

if is_windows and is_windows == "true" then
    EncodeC = require('encode_c')
end

local ms = {} --- 缓存

unpack = table.unpack

local function readfile(file)
    local fh = io.open(file , "rb")
    if not fh then return end
    local data = fh:read("*a")
    fh:close()
    return data
end


local function require_module(file_name, mod_name)
    local mod_name = mod_name or file_name
    local file_path = string.format("./temp/%s.lua", EncodeC.u82a(file_name))
    local file_data = assert(readfile(file_path), file_path)
    local func, err = load(file_data)
    if not func then
        error(err)
    end
    ms[mod_name] = func()
end


local function run_script(tbl_list, name, is_convertor, save)
    if save == nil then
        save = true
    end

	print('--> try to generate:', name)

    local rlt = nil
    if is_convertor then

        ------ 加载导表脚本
        local script_path
        if is_client then
            script_path = string.format("./game_script_client/%s.lua", name)
        else
            script_path = string.format("./script/%s.lua", name)
        end
        local script_data = assert(readfile(script_path), script_path)
        local func, err = load(script_data, modname, 'bt', _ENV)
        if not func then
            error(string.format("[FAIL] to load script [%s]:%s", name, err))
        end

        ---- 加载输入数据
        local input = {}
        for _, i in ipairs(tbl_list) do
            if not ms[i] then
                local file_path = string.format("./temp/%s.lua", EncodeC.u82a(i))
                local file_data = assert(readfile(file_path), file_path)
                local func, err = load(file_data)
                if not func then
                    error('Failed to load data name: '.. i .. '\n\terror msg: '.. err)
                end
                local d = assert(func())
                ms[i] = d
            end
            input[i] = ms[i]
        end

        --- 执行导表 脚本 
        local ok, _table_data = pcall(func(), input)
        if not ok then
            error(string.format("[FAIL] in run script [%s]\n \terror msg:%s", name, _table_data))
        end
        rlt = _table_data
    else
        rlt = ms[name]
    end

    assert(rlt)

    ms[name] = rlt
    if not save then
        return
    end

    local out_file_path
    if is_client then
        out_file_path = string.format("./game_data_client/%s.lua.bytes", name)
    else
        out_file_path = string.format("../../service/agent/res/%s.lua", name)
    end
    local out_file = io.open(out_file_path, 'wb')
    print(out_file_path)
    out_file:write(DumpApi(rlt))
    out_file:close()
end

local mod_list
--客户端跟服务器应该用一个mod_list
if is_client then
    mod_list = require "mod_list"
else
    mod_list = require "mod_list"
end

for _, item in ipairs(mod_list) do
    require_module(unpack(item))
end

-- (res_name, has_script)
-- script_name既是脚本名，也是最终存储的res_name
local script_list
if is_client then
    script_list = require "client_script_list"
else
    script_list = require "script_list"
end

for _, item in ipairs(script_list) do
    run_script(unpack(item))
end
