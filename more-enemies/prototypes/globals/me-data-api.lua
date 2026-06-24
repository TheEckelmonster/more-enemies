if (type(_ENV.MORE_ENEMIES_API) == "table") then
    if ((getmetatable(_ENV.MORE_ENEMIES_API) or {}).initialized) then
        return _ENV.MORE_ENEMIES_API
    end
end

local data = data
local data_raw = data.raw

local math_exp = math.exp
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local pcall = pcall
local string_lower = string.lower

local rawget = rawget

local Util = require("__core__.lualib.util")
local deepcopy = Util.table.deepcopy

local E = math_exp(1)
local MORE_ENEMIES_API_STRING = "MORE_ENEMIES_API"
local NUMBER = "number"
local STRING = "string"
local TABLE = "table"

local prototype_overrides = {
    ["character"]        = { priority = 9, weight = 96000 },
    ["character-corpse"] = { priority = 5, weight = 48000 },
    ["nuclear-reactor"]  = { weight = (6 ^ E) * (E ^ E) + (E ^ 6), priority = 6, mode = "blend" },
    ["stone-wall"]  = { weight = 3, priority = 1, },
}
local keyword_blacklist = {}
local category_modifiers = {}

local REGISTER_PROTOTYPE_ERR_MSG = MORE_ENEMIES_API_STRING .. ".register_prototype_override: "
local function register_prototype_override(params)
    if (type(params) ~= TABLE) then return error(REGISTER_PROTOTYPE_ERR_MSG .. "parameters must be a table container") end
    if (type(params.entity_name) ~= STRING and type(params.name) ~= STRING) then return error(REGISTER_PROTOTYPE_ERR_MSG .. "no 'entity_name' or 'name' key provided") end

    local current = prototype_overrides[params.entity_name or params.name] or {}

    if (type(params.priority) == NUMBER) then current.priority = math_max(1, math_min(10, math_floor(params.priority))) end
    if (type(params.weight) == NUMBER) then current.weight = math_max(12, math_min(256000, math_floor(params.weight))) end

    prototype_overrides[params.entity_name or params.name] = current

    return true
end

local REGISTER_DAMPENING_KEYWORD_ERR_MSG = MORE_ENEMIES_API_STRING .. ".register_dampening_keyword: "
local function register_dampening_keyword(params)
    if (type(params) ~= TABLE) then return error(REGISTER_DAMPENING_KEYWORD_ERR_MSG .. "parameters must be a table container") end
    if (type(params.keyword) ~= STRING) then return error(REGISTER_DAMPENING_KEYWORD_ERR_MSG .. "'keyword' must be a string") end
    if (params.max_priority ~= nil and type(params.max_priority) ~= NUMBER) then return error(REGISTER_DAMPENING_KEYWORD_ERR_MSG .. "'max_priority', if provided, must be a number") end
    if (params.hard_weight ~= nil and type(params.hard_weight) ~= NUMBER) then return error(REGISTER_DAMPENING_KEYWORD_ERR_MSG .. "'hard_weight', if provided, must be a number") end

    keyword_blacklist[string_lower(params.keyword)] = {
        max_priority = math_max(1, math_min(10, math_floor(params.max_priority or 2))),
        weight = params.hard_weight
    }

    return true
end

local REGISTER_CATEGORY_MULTIPLIER_ERR_MSG = MORE_ENEMIES_API_STRING .. ".register_category_multiplier: "
local function register_category_multiplier(params)
    if (type(params) ~= TABLE) then return error(REGISTER_CATEGORY_MULTIPLIER_ERR_MSG .. "parameters must be a table container") end
    if (type(params.category_name) ~= STRING and type(params.name) ~= STRING) then return error(REGISTER_CATEGORY_MULTIPLIER_ERR_MSG .. "no 'category_name' or 'name' key provided") end
    if (type(params.modifier) ~= NUMBER) then return error(REGISTER_CATEGORY_MULTIPLIER_ERR_MSG .. "'modifier' must be a number") end

    category_modifiers[params.category_name or params.name] = math_max(0.001, math_min(10.0, params.modifier))

    return true
end

return (function ()
    local self = {
        prototype_overrides = prototype_overrides,
        keyword_blacklist = keyword_blacklist,
        category_modifiers = category_modifiers,
        interface = {},
        locked = false,
    }

    self.interface.register_prototype_override = function (...) if (not self.locked) then register_prototype_override(...) end end
    self.interface.register_dampening_keyword = function (...) if (not self.locked) then register_dampening_keyword(...) end end
    self.interface.register_category_multiplier = function (...) if (not self.locked) then register_category_multiplier(...) end end
    self.interface.get_prototype_overrides = function () return deepcopy(self.prototype_overrides) end
    self.interface.get_keyword_blacklist = function () return deepcopy(self.keyword_blacklist) end
    self.interface.get_category_modifiers = function () return deepcopy(self.category_modifiers) end

    local privates = {
        ["prototype_overrides"] = "prototype_overrides",
        ["keyword_blacklist"] = "keyword_blacklist",
        ["category_modifiers"] = "category_modifiers",
    }

    local mt = {
        __prototype_overrides = prototype_overrides,
        __keyword_blacklist = keyword_blacklist,
        __category_modifiers = category_modifiers,
        __call = function (t, params, method_name)
            if (self.locked) then return end

            if (method_name == nil) then return register_prototype_override(params)
            elseif (type(method_name) == STRING) then
                local target_func = self.interface[method_name]
                if (type(target_func) == "function") then
                    local ok, err = pcall(target_func, params)
                    if (not ok) then log("MORE_ENEMIES_API ERROR: " .. tostring(err)) end
                    return ok
                end
            end

            return false
        end,
        __toggle = function (v) self.locked = (v == true) end
    }
    mt.__index = function (t, k)
        if (k == nil) then return end
        return not privates[k] and rawget(mt, k) or nil
    end
    mt.initialized = true
    _ENV.MORE_ENEMIES_API = setmetatable(self.interface, mt)

    return _ENV.MORE_ENEMIES_API
end)()