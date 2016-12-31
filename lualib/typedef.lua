local lpeg = require "lpeg"
--tprint = require('utils').print_table
local P = lpeg.P
local R = lpeg.R
local S = lpeg.S
local C = lpeg.C
local Ct = lpeg.Ct
local V = lpeg.V
local Cc = lpeg.Cc
local Cg = lpeg.Cg
local Carg = lpeg.Carg
local Cs = lpeg.Cs

local locale = lpeg.locale()
local alpha = locale.alpha
local alnum = locale.alnum
local digit = locale.digit
local space = locale.space

local line_infos = {}
local function count_lines(_,pos, parser_state)
    if parser_state.pos < pos then
        parser_state.line = parser_state.line + 1
        parser_state.pos = pos
    end
    return pos
end

local exception = lpeg.Cmt(
    lpeg.Carg(1),
    function(text, pos, parser_state)
        local line_info = line_infos[parser_state.line]
        local s = string.format(
            "syntax error, file[%s],line[%s],pos[%s]",
            line_info.file,
            line_info.line,
            pos
        )
        error(s)
        return pos
    end
)

local eof = P(-1)
local newline = lpeg.Cmt((P"\n" + "\r\n") * lpeg.Carg(1) ,count_lines)
local line_comment = "#" * (1 - newline) ^0 * (newline + eof)
local blank = S" \t" + newline + line_comment
local blank0 = blank ^ 0
local blanks = blank ^ 1
local alpha = R"az" + R"AZ" + "_"
local alnum = alpha + R"09"
local word = alpha * alnum ^ 0
local name = C(word)
local typename = C(word * ("." * word) ^ 0)
local tag = R"09" ^ 1 / tonumber
local mainkey = "(" * blank0 * name * blank0 * ")"
local decimal = "(" * blank0 * C(tag) * blank0 * ")"

local function multipat(pat)
    return Ct(blank0 * (pat * blanks) ^ 0 * pat^0 * blank0)
end

local function namedpat(name, pat)
    return Ct(Cg(Cc(name), "type") * Cg(pat))
end

local typedef = P {
    "ALL",

    FIELD = namedpat(
        "field",
        (name * blanks * tag * blank0 * ":" * blank0 *
             (
                 namedpat(
                     "ref",
                     typename * decimal^0
                 ) + 
                     
                 namedpat(
                     "list",
                     '*' * blank0 * typename * (decimal + mainkey)^0
                 ) +

                 namedpat(
                     "map",
                     "*" * blank0 * typename * mainkey
                 )
             )
        )
        +
        (P"."^0 * name * blanks * R"09"^0 * blank0 *
            namedpat(
                "struct",
                P"{" * multipat(V"FIELD") * P"}"
            )
        )
    ),

    STRUCT = namedpat(
        "struct", 
        blank0 * P"."^0 * name * blank0 * R"09"^0 * blank0 * P"{" * multipat(V"FIELD") * P"}"
    ),

    LIST = namedpat(
        "list",
        blank0 * name * blank0 * tag * blank0 * ":" * blank0 * "*" * blank0 * typename * (decimal + mainkey)^0
    ),

    MAP = namedpat(
        "map",
        blank0 * name * blank0 * tag * blank0 * ":" * blank0 * "*" * blank0 * typename * mainkey
    ),

    ALL = multipat(V"STRUCT" + V"LIST" + V"MAP"),
}

local schema = blank0 * typedef * blank0

local function preprocess(filename, dir)
    local text = {}
    local path = dir .. "/" .. filename
    line_infos = {}
    local idx = 0
    for line in io.lines(path) do
        idx = idx + 1
        local include = string.match(line, "^%s*#include%s+([^%s]+)%s*")
        if not include then
            local _idx = #text + 1
            text[_idx] = line
            line_infos[_idx] = {line = idx, file=path}
        else
            local _idx = 0
            include = dir .. "/" .. include
            for _line in io.lines(include) do
                _idx = _idx + 1
                local idx = #text+1
                text[idx] = _line
                line_infos[idx] = {line = _idx, file=include}
            end
        end
    end
    return table.concat(text, "\n")
end

local keyword_field_type = {
    boolean = true,
    integer = true,
    string = true,
}

local keyword_map = {
    boolean = true,
    integer = true,
    string = true,
    struct = true,
    list = true,
    map = true
}

local convert = {}
function convert.struct(obj)
    local type_name = obj[1]
    if keyword_map[type_name] then
        error(string.format("type_name<%s> is keyword", type_name))
    end

    local field_map = {}
    for _, f in ipairs(obj[2]) do
        local field_name = f[1]
        local field_data = f[2]
        if(type(field_data) ~= 'table') then
            field_data = f[3]
        end

        if field_data == '*' then
            field_data = f[4]
        end
        local field_data_type = field_data.type

        if keyword_map[field_name] then
            error(string.format("struct %s field %s is keyword", type_name, field_name))
        end

        if field_map[field_name] then
            error(string.format("struct %s field %s is redefined", type_name, field_name))
        end

        local field = {}
        if field_data_type == 'ref' then
            field.type = field_data[1]
            
        elseif field_data_type == 'map' then
            field.type = 'map'
            field.key = {type = field_data[2]}
            field.value = {type = field_data[1]}

        elseif field_data_type == 'list' then
            field.type = 'list'
            field.item = {type = field_data[1]}

        elseif field_data_type == 'struct' then
            local sub_struct_obj = {field_name, field_data[1], type = 'struct' }
            for k, v in pairs(convert.struct(sub_struct_obj)) do
                field[k] = v
            end
            field.name = nil
        else
            error(string.format("struct %s field %s unknown type", type_name, field_name))
        end

        field_map[field_name] = field
    end

    return {
        type = 'struct',
        name = type_name,
        attrs = field_map,
    }
end


function convert.list(obj)
    -- print('-- convert.list', obj[1])
    local result = {}
    local type_name = obj[1]
    if keyword_map[type_name] then
        error(string.format("type_name<%s> is keyword", type_name))
    end

    return {
        type = 'list',
        name = type_name,
        item = {type = obj[4]},
    }
end

function convert.map(obj)
    -- print('-- convert.map', obj[1])
    local result = {}
    local type_name = obj[1]
    if keyword_map[type_name] then
        error(string.format("type_name<%s> is keyword", type_name))
    end

    return {
        type = 'map',
        name = type_name,
        key = {type = obj[5]},
        value = {type = obj[4]},
    }
end

local function parse(pattern, filename, dir)
    assert(type(filename) == "string")
    local file_path = dir .. "/".. filename
    local text = preprocess(filename, dir)
    local state = {file = filename, pos = 0, line = 1}
    -- print('text:', text)
    local r = lpeg.match(pattern * -1 + exception, text, 1, state)

    local ret = {}
    for _, item in ipairs(r) do
        table.insert(ret, convert[item.type](item))
    end

    return ret
end


local M = {}
function M.parse(...)
    return parse(schema, ...)
end

return M
