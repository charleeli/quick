M = {}

local res_dir_path = "./service/res_mgr/res/"

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

M.ErrCode = require_file "errcode"

--sign system start
M.SignAwardBase = require_file 'sign_award_base'
M.SignAwardRate = require_file 'sign_award_rate'
M.ResignCount   = require_file 'resign_count'
M.ResignCost    = require_file 'resign_cost'
M.FullDutyAward = require_file 'full_duty_award'
--sign system end

return M

