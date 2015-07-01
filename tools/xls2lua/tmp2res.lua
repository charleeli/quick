local DumpApi = require 'datadump'
local EncodeC = {}
EncodeC.u82a = function(str) return str end

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
    local file_path = string.format("./tmp/%s.lua", EncodeC.u82a(file_name))
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
        local script_path = string.format("./script/%s.lua", name)
   
        local script_data = assert(readfile(script_path), script_path)
        local func, err = load(script_data, modname, 'bt', _ENV)
        if not func then
            error(string.format("[FAIL] to load script [%s]:%s", name, err))
        end

        ---- 加载输入数据
        local input = {}
        for _, i in ipairs(tbl_list) do
            if not ms[i] then
                local file_path = string.format("./tmp/%s.lua", EncodeC.u82a(i))
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

    local out_file_path = string.format("../../service/res_mgr/res/%s.lua", name)
 
    local out_file = io.open(out_file_path, 'wb')
    print(out_file_path)
    out_file:write(DumpApi(rlt))
    out_file:close()
end

local sheet_list = require "sheet_list"

for _, item in ipairs(sheet_list) do
    require_module(unpack(item))
end

-- (res_name, has_script)
-- script_name既是脚本名，也是最终存储的res_name
local script_list = require "script_list"

for _, item in ipairs(script_list) do
    run_script(unpack(item))
end
