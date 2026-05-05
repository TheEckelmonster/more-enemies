local tab = "    "
local source_pattern = "@__([%a%-]+)__"
local no_source = "__no-src__/"
local indentation = { tab, }
for i = 2, 11, 1 do
    indentation[i] = tab .. indentation[i - 1]
end

local function pre(self, __self, print_params, ...)
    local info = debug.getinfo(3, "S")
    local source = no_source
    source = info.source
    ---@diagnostic disable-next-line: cast-local-type
    info = nil
    info = debug.getinfo(3, "l")
    local current_line = info and info.currentline or 0

    local i = 1
    local token = ""
    while debug.getinfo(i) ~= nil do
        token = debug.getinfo(i, "S").source:match(source_pattern)
        if (token ~= nil and token ~= "configurable-nukes") then break end
        i = i + 1
    end

    local log_string = "\n"
                    .. indentation[4]
                    .. source
                    .. ":" .. current_line .. ": "
    log_string = log_string
                .. "\n"
                .. indentation[5]
                .. "function __" .. tostring(__self.__func_name) .. "__"

    if (print_params) then log_string = log_string .. ":\n" .. serpent.block({ ... }) end

    if (DEBUG) then log(log_string) end
    -- log(log_string)
end

local data_utils = {}

data_utils.table = {}

local function new_packed_mt(n)
    local mt = { n = n }
    mt.__index = mt
    return mt
end

function data_utils.pack(...)
    if (not ...) then return end
    local packed = {...}
    return setmetatable(packed, new_packed_mt(#packed))
end

function data_utils.unpack(tbl, ...)
    if (not tbl) then return end
    if (type(tbl) ~= "table") then return end
    if (not tbl[1]) then return data_utils.table.unpack_tbl(tbl) end

    local _params = {...}
    local _size = #_params

    local size = #tbl
    local function recurse(tbl, i)
        if (i <= size) then
            return tbl[i], recurse(tbl, i + 1)
        elseif (_size > 0) then
            i = 1
            size = _size
            _size = -1
            return _params[i], recurse(_params, i + 1)
        end
    end

    return tbl[1], recurse(tbl, 2)
end

function data_utils.foreach(func, ...)
    local tbls = {...}

    if (type(func) == "function") then
        for _, tbl in ipairs(tbls) do
            func(tbl)
        end
    end

    return data_utils.unpack(tbls)
end

function data_utils.find_by(tbl, by, to_find)
    if (type(tbl) ~= "table") then return end
    -- if (type(by) ~= "string" or by:gsub("%s", "") == "") then return end
    local by_type = type(by)
    if (by_type ~= "string") then
        if (by_type ~= "table" or not next(by)) then return end
    end
    local to_find_type = type(to_find)
    if (to_find_type ~= "table" and to_find_type ~= "function") then return end

    local found = {}

    local ret = {}
    local function recurse(_tbl, _p_tbl)
        if (not _tbl or type(_tbl) ~= "table") then return end

        local _p_tbl = _p_tbl or _tbl
        if (not found[_tbl]) then found[_tbl] = 1 end

        for k, v in pairs(_tbl) do
            if (type(v) == "table") then
                if (not found[v]) then
                    found[v] = 1
                    recurse(v, _tbl)
                end
            end
        end

        if (by_type == "table") then
            for _by, _ in pairs(by) do
                if (to_find_type == "table") then
                    if (_tbl[_by] and (to_find[_tbl[_by]] or to_find[_by])) then
                        ret[#ret+1] = _tbl
                    end
                else
                    if (_tbl[_by] and to_find(_tbl, _by, _tbl[_by], _p_tbl)) then
                        ret[#ret+1] = _tbl
                    end
                end
            end
        else
            if (to_find_type == "table") then
                if (_tbl[by] and (to_find[_tbl[by]] or table_size(to_find) == 0)) then
                    ret[#ret+1] = _tbl
                end
            else
                if (_tbl[by] and to_find(_tbl, by, _tbl[by], _p_tbl)) then
                    ret[#ret+1] = _tbl
                end
            end
        end

        return ret
    end

    recurse(tbl)

    return ret
end

function data_utils.table.unpack_tbl(tbl)
    if (not tbl) then return end

    local function recurse(tbl, k)
        if (next(tbl, k)) then
            local k, v = next(tbl, k)
            return v, recurse(tbl, k)
        end
    end
    local _, v = next(tbl)
    return v, recurse(tbl)
end

function data_utils.table.deepcopy(tbl)
    local lookup_tbl = {}
    local function __copy(tbl)
        if type(tbl) ~= "table" then
            return tbl
        elseif lookup_tbl[tbl] then
            return lookup_tbl[tbl]
        end
        local new_tbl = {}
        lookup_tbl[tbl] = new_tbl
        for k, v in pairs(tbl) do
            new_tbl[__copy(k)] = __copy(v)
        end
        return setmetatable(new_tbl, getmetatable(tbl))
    end
    return __copy(tbl)
end

function data_utils.table.deepcopy_exclude_functions(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            if (type(object) ~= "function") then
                return object
            else
                return
            end
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

function data_utils.table.merge(...)
    local tbls = {...}

    local m_found = {}
    local merged_tbl = {}
    local depth = 0

    local function r(tbl1, tbl2, depth)
        depth = depth or 0

        local ret_tbl = {}

        for k, v in pairs(tbl1 or {}) do
            if (type(v) == "table") then
                if (not m_found[v]) then
                    m_found[v] = { v = v, depth = depth, }
                    ret_tbl[k] = r(ret_tbl[k], v, depth + 1)
                end
            else
                ret_tbl[k] = ret_tbl[k] or v
            end
        end

        for k, v in pairs(tbl2 or {}) do
            if (type(v) == "table") then
                if (not m_found[v]) then
                    m_found[v] = { v = v, depth = depth, }
                    if (ret_tbl[k]) then
                        if (type(ret_tbl[k]) == "table") then
                            ret_tbl[k] = data_utils.table.merge(v, data_utils.table.deepcopy_exclude_functions(ret_tbl[k]))
                        end
                    else
                        ret_tbl[k] = r(ret_tbl[k], v, depth + 1)
                    end
                end
            else
                ret_tbl[k] = ret_tbl[k] or v
            end
        end

        return ret_tbl
    end

    for _, tbl in pairs(tbls) do
        if (type(tbl) == "table") then
            merged_tbl = r(merged_tbl, tbl)

            if (script) then
                local mts = {
                    [1] = getmetatable(merged_tbl),
                    [2] = getmetatable(tbl)
                }
                setmetatable(merged_tbl, mts[1] and mts[2] and data_utils.table.merge(mts[1], mts[2]) or mts[2])
            end
        -- else
        --     merged_tbl[#merged_tbl+1] = tbl
        end
    end

    return merged_tbl
end

function data_utils.table.to_list(tbl)
    if (not tbl) then return end
    if (tbl[1] == nil) then return {} end

    local ret = {}
    local i = 1
    while tbl[i] do
        ret[i] = tbl[i]
        i = i + 1
    end

    return ret
end

function data_utils.table.unbox(tbl, recurse_limit, depth)
    if (type(tbl) ~= "table") then return end

    recurse_limit = type(recurse_limit) == "number" and recurse_limit or 2 ^ 3

    local found = {}

    local function r(_tbl, depth)
        depth = depth or 1

        if (type(_tbl) ~= "table") then return end
        if (depth > recurse_limit) then return _tbl end

        if (found[_tbl]) then return _tbl end
        found[_tbl] = { depth = depth, }

        local ret = nil
        local k, v = next(_tbl)
        if (k and v) then
            if (not next(_tbl, k)) then
                if (type(v) == "table") then
                    ret = r(v, depth + 1)
                end
            end
        end

        return ret or _tbl
    end

    return r(tbl, depth)
end

function data_utils.table.unbox_recursive(tbl, recurse_limit, depth)
    if (type(tbl) ~= "table") then return end

    recurse_limit = type(recurse_limit) == "number" and recurse_limit or 2 ^ 3

    local found = {}

    local function r(_tbl, depth)
        depth = depth or 1

        if (type(_tbl) ~= "table") then return end
        if (depth > recurse_limit) then return _tbl end

        if (found[_tbl]) then return _tbl end
        found[_tbl] = { depth = depth, }

        local ret = nil
        local k, v = next(_tbl)
        if (k and v) then
            if (not next(_tbl, k)) then
                if (type(v) == "table") then
                    ret = r(v, depth + 1)
                end
            else
                ret = {}
                for k, v in pairs(_tbl) do
                    if (type(v) == "table") then
                        ret[k] = data_utils.table.merge(ret[k], data_utils.table.unbox_recursive(v, recurse_limit, depth + 1))
                    else
                        ret[k] = v
                    end
                end
            end
        end

        return ret or _tbl
    end

    return r(tbl, depth)
end

return data_utils