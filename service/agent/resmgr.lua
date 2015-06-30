local res_dir_path = "./service/agent/res/"

local function readfile(file)
    local fh = io.open(file , "rb")
    if not fh then return end
    local data = fh:read("*a")
    fh:close()
    return data
end

local function require_file(modname)
    local path = modname:gsub("%.", "/")
    local file_path = string.format('%s%s.lua', res_dir_path, path)
    local file = assert(readfile(file_path), file_path)
    local moudle = load(file)()
    return moudle
end

M = {}
M.ErrCode = require_file "errcode"

return M

