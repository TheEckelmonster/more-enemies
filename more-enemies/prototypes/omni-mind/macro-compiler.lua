local data = data
local data_raw = data.raw

local math_exp = math.exp
local math_floor = math.floor
local math_log = math.log
local math_max = math.max
local math_min = math.min
local math_sqrt = math.sqrt
local pairs = pairs

local CRAFTING = "crafting"
local E = math_exp(1)
local MOD_DATA = "mod-data"
local TABLE = "table"
local UINT64 = 2^64-1
local UNKNOWN = "unknown"

local Recipe_Category_Profile_Data = require("prototypes.data.recipe-category-profile-data")
local Subgroup_Profile_Data = require("prototypes.data.subgroup-profile-data")

local macro_compiler_mt = {
    recipe_category_profile_data = Recipe_Category_Profile_Data,
    subgroup_profile_data = Subgroup_Profile_Data,
}
macro_compiler_mt.__index = macro_compiler_mt

local macro_compiler = {
    raw_recipe_category_profiles = Recipe_Category_Profile_Data.raw_recipe_category_profiles,
    compiled_recipe_category_statistics = Recipe_Category_Profile_Data.compiled_recipe_category_statistics,
    raw_subgroup_profiles = Subgroup_Profile_Data.raw_subgroup_profiles,
    compiled_subgroup_statistics = Subgroup_Profile_Data.compiled_subgroup_statistics,
    dynamic_subgroup_weights = Subgroup_Profile_Data.dynamic_subgroup_weights,
    dynamic_subgroup_priorities = Subgroup_Profile_Data.dynamic_subgroup_priorities,
}

function macro_compiler:execute_balancing(params)
    params = type(params) == TABLE and params or {}

    local calculate_subgroup_statistics_params = params.calculate_subgroup_statistics_params or params
    local analyze_recipe_categories_params = params.analyze_recipe_categories_params or params

    self.subgroup_profile_data:calculate_statistics(calculate_subgroup_statistics_params)
    self.recipe_category_profile_data:analyze_recipe_categories(analyze_recipe_categories_params)

    local parent_group_aggregates = {}

    for _, stats in pairs(self.compiled_subgroup_statistics or {}) do
        local p_group = stats.parent or "base"
        parent_group_aggregates[p_group] = parent_group_aggregates[p_group] or {
            min_weight = UINT64,
            max_weight = 1,
            total_median_weight = 0,
            max_depth_witnessed = 1,
            subgroup_count = 0,
        }

        local agg = parent_group_aggregates[p_group]
        if (agg) then
            agg.total_median_weight = agg.total_median_weight + stats.median_weight
            agg.subgroup_count = agg.subgroup_count + 1

            if (stats.median_weight > agg.max_weight) then agg.max_weight = stats.median_weight end
            if (stats.median_weight < agg.min_weight) then agg.min_weight = stats.median_weight end
            if (stats.median_depth > agg.max_depth_witnessed) then agg.max_depth_witnessed = stats.median_depth end
        end
    end

    for sub_name, stats in pairs(self.compiled_subgroup_statistics or {}) do
        local agg = parent_group_aggregates[stats.parent or "base"]
        if (agg) then
            local weight_multiplier = 1.0
            local weight_range = agg.max_weight - agg.min_weight

            if (weight_range > 0) then
                local percentage = (stats.median_weight - agg.min_weight) / weight_range
                weight_multiplier = 0.5 + (percentage * 4.5)
            else
                weight_multiplier = E
            end

            local priority_tier = 1
            if (agg.max_depth_witnessed > 0) then
                local depth_ratio = stats.median_depth / agg.max_depth_witnessed
                priority_tier = math_max(1, math_min(10, math_floor(depth_ratio * 10)))
            end

            self.dynamic_subgroup_weights[sub_name] = math_max(0.5, math_min(5.0, weight_multiplier))
            self.dynamic_subgroup_priorities[sub_name] = priority_tier
        end
    end

    if (    params.mod_data
        and params.mod_data.data
        and next(params.mod_data.data)
    ) then
        data:extend({ params.mod_data, })
    end

    self:apply_metrics({ mod_data = params.mod_data, })
end

function macro_compiler:apply_metrics(params)
    params = type(params) == TABLE and params or {}

    local mod_data = params.mod_data or data_raw[MOD_DATA][Constants.mod_name .. "-target-priority-data"]
    if (type(mod_data) ~= "table") then return end
    if (type(mod_data.data) ~= "table") then return end

    local db = mod_data.data
    if (db) then
        local me_api = _ENV.MORE_ENEMIES_API
        local mt = getmetatable(_ENV.MORE_ENEMIES_API)
        mt.__toggle(true)

        local prototype_overrides = me_api.get_prototype_overrides()

        local global_weights = {}
        for _, stats in pairs(self.compiled_recipe_category_statistics or {}) do global_weights[#global_weights+1] = stats.median_weight end
        local global_median_weight = global_weights[math_max(1, math_floor((#global_weights) / 2))] or 100

        local db_bak = {}
        for entity_name, entry in pairs(db or {}) do
            local prototype = type(entry.entity_type) == "string" and data_raw[entry.entity_type] and data_raw[entry.entity_type][entity_name]

            local category_multiplier = 1.0
            local category_priority_bump = 0

            if (prototype) then
                local categories = {}
                if (entry.recipe and entry.recipe.category) then categories[entry.recipe.category] = 1 end

                for _, category in ipairs(prototype.additional_categories or {}) do categories[category] = 1 end

                local total_category_weight = 0.0
                local valid_category_count = 0

                for category, _ in pairs(categories or {}) do
                    local category_stats = self.compiled_recipe_category_statistics[category]
                    if (type(category_stats) == "table") then
                        total_category_weight = total_category_weight + category_stats.median_weight
                        valid_category_count = valid_category_count + 1
                    end
                end

                if (valid_category_count > 0) then
                    local avg_category_weight = total_category_weight / valid_category_count
                    category_multiplier = 1.0 + (avg_category_weight / global_median_weight)

                    if (avg_category_weight > (2 * global_median_weight)) then
                        category_priority_bump = 1
                    end
                end
            end

            local sub_name = entry.subgroup or "unknown"
            local weight_multiplier = self.dynamic_subgroup_weights[sub_name] or 1.0
            local priority = self.dynamic_subgroup_priorities[sub_name] or 1

            local final_priority = (entry.p or priority) + category_priority_bump

            local weight = entry.w or 100
            local structural_weight = weight * weight_multiplier

            local tech_investment_cost = entry.total_investment_cost or 100
            local investment_factor = 1.0 + math_log(tech_investment_cost, 10)
            local final_weight = math_floor(structural_weight * investment_factor * category_multiplier)

            local override = prototype_overrides[entity_name]
            if (override) then
                if (override.mode and override.mode == "blend") then
                    final_priority = math_floor(final_priority + override.priority) / 2
                    final_weight = math_floor(math_sqrt(final_weight * override.weight))
                else
                    final_weight = override.weight or final_weight
                    final_priority = override.priority or final_priority
                end
            end

            final_weight = math_min(256000, math_max(12, math_floor(final_weight)))
            final_priority = math_min(10, math_max(1, math_floor(final_priority)))

            local numerator, denominator = ((final_priority ^ 2) + (final_priority ^ (final_priority / 2))), (2 ^ final_priority)
            local fx_factor = numerator / denominator

            db_bak[entity_name] = entry
            db[entity_name] = {
                name = entity_name,
                type = entry.type,
                w = final_weight,
                p = final_priority,
                fx = fx_factor
            }
        end
        db.bak = db_bak
    end
end

return setmetatable(macro_compiler, macro_compiler_mt)