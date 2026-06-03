local data = data
local data_raw = data.raw

local math_floor = math.floor
local math_max = math.max
local pairs = pairs
local table_sort = table.sort

local setmetatable = setmetatable

local CRAFTING = "crafting"
local MOD_DATA = "mod-data"
local RECIPE_CATEGORY = "recipe-category"
local TABLE = "table"
local STRING = "string"
local UNKNOWN = "unknown"

local Constants = require("scripts.constants.constants")

local prototype_overrides = {}

local recipe_category_profile_data = {}

recipe_category_profile_data.raw_recipe_category_profiles = {}
recipe_category_profile_data.compiled_recipe_category_statistics = {}
recipe_category_profile_data.prototype_overrides = prototype_overrides

function recipe_category_profile_data:new(o, recipe_category_name)
    local obj = o or {}

    obj.weights = obj.weights or {}
    obj.count = obj.count or 0
    obj.category = obj.category or (data_raw[RECIPE_CATEGORY][recipe_category_name] or {}).name or CRAFTING

    self:update_profile(recipe_category_name)

    self.__index = self
    return setmetatable(obj, self)
end

function recipe_category_profile_data:update_profile(params)
    if (type(params) ~= TABLE) then return end

    local entry = type(params.entry) == TABLE and params.entry or {}
    local category = type(params.category) == STRING and params.category or entry.recipe and entry.recipe.category or CRAFTING
    local computed_recipe_compelxity = params.computed_recipe_compelxity

    self.raw_recipe_category_profiles[category] = self.raw_recipe_category_profiles[category] or self:new({}, category)
    local profile = self.raw_recipe_category_profiles[category]

    if (profile) then
        profile.weights[#profile.weights+1] = computed_recipe_compelxity

        if (computed_recipe_compelxity) then profile.count = profile.count + 1 end
    end
end

function recipe_category_profile_data:analyze_recipe_categories(params)
    params = type(params) == TABLE and params or {}

    local mod_data = params.mod_data or data_raw[MOD_DATA][Constants.mod_name .. "-target-priority-data"]
    if (type(mod_data) ~= "table") then return end
    if (type(mod_data.data) ~= "table") then return end

    local db = mod_data.data
    if (db) then
        for _, entry in pairs(db or {}) do
            local recipe = entry.recipe
            local category = recipe.category or CRAFTING

            self.raw_recipe_category_profiles[category] = self.raw_recipe_category_profiles[category] or self:new({}, category)
            local profile = self.raw_recipe_category_profiles[category]

            profile.weights[#profile.weights+1] = entry.w or 100
            profile.count = profile.count + 1
        end

        for category, profile in pairs(self.raw_recipe_category_profiles or {}) do
            if ((profile.count or 0) > 0) then
                table_sort(profile.weights)

                local mid = math_max(1, math_floor(profile.count / 2))

                self.compiled_recipe_category_statistics[category] = {
                    median_weight = profile.weights[mid] or 100,
                    count = profile.count,
                }
            end
        end
    end
end

recipe_category_profile_data.__index = recipe_category_profile_data

return recipe_category_profile_data