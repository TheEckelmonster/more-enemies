local data = data
local data_raw = data.raw

local math_floor = math.floor
local math_max = math.max
local math_sqrt =  math.sqrt
local pairs = pairs
local table_sort = table.sort

local setmetatable = setmetatable

local BASE = "base"
local ITEM_SUBGROUP = "item-subgroup"
local TABLE = "table"
local STRING = "string"

local prototype_overrides = {}

local subgroup_profile_data = {}

subgroup_profile_data.compiled_subgroup_statistics = {}
subgroup_profile_data.dynamic_subgroup_weights = {}
subgroup_profile_data.dynamic_subgroup_priorities = {}
subgroup_profile_data.prototype_overrides = prototype_overrides
subgroup_profile_data.raw_subgroup_profiles = {}

function subgroup_profile_data:new(o, subgroup_name)
    local obj = o or {}

    obj.weights = obj.weights or {}
    obj.depths = obj.depths or {}
    obj.count = obj.count or 0
    obj.parent_group = obj.parent_group or (data_raw[ITEM_SUBGROUP][subgroup_name] or {}).group or BASE

    self:update_profile(subgroup_name)

    self.__index = self
    return setmetatable(obj, self)
end

function subgroup_profile_data:update_profile(params)
    if (type(params) ~= TABLE) then return end

    local entry = type(params.entry) == TABLE and params.entry or {}
    local subgroup = type(params.subgroup) == STRING and params.subgroup or type(entry) == TABLE and type(entry.subroup) == STRING and entry.subroup or params.name or BASE
    local computed_recipe_compelxity = params.computed_recipe_compelxity
    local computed_tech_depth = params.computed_tech_depth

    self.raw_subgroup_profiles[subgroup] = self.raw_subgroup_profiles[subgroup] or self:new({ parent_group = data_raw[ITEM_SUBGROUP][subgroup].group or BASE, }, subgroup)
    local profile = self.raw_subgroup_profiles[subgroup]

    if (profile) then
        profile.weights[#profile.weights+1] = computed_recipe_compelxity
        profile.depths[#profile.depths+1] = computed_tech_depth

        if (computed_recipe_compelxity and computed_tech_depth) then profile.count = profile.count + 1 end
    end
end

function subgroup_profile_data:calculate_statistics(params)
    params = type(params) == TABLE and params or {}

    local subgroup_name = type(params.name) == "string" and params.name or nil
    local subgroups_to_update = subgroup_name and { [subgroup_name] = self.raw_subgroup_profiles[subgroup_name], } or self.raw_subgroup_profiles

    for sub_name, profile in pairs(subgroups_to_update or {}) do
        local count = type(profile.count) == "number" and profile.count or 0

        if (count > 0) then
            table_sort(profile.weights)
            table_sort(profile.depths)

            local mid = math_max(1, math_floor(count/2))
            local median_weight = profile.weights[mid] or 100
            local median_depth = profile.depths[mid] or 1

            local sum_weight = 0
            for _, weight in ipairs(profile.weights) do sum_weight = sum_weight + weight end
            local mean_weight = sum_weight / count

            local variance_sum = 0
            for _, weight in ipairs(profile.weights) do variance_sum = variance_sum + ((weight - mean_weight) ^ 2) end
            local std_deviation = math_sqrt(variance_sum / count)

            self.compiled_subgroup_statistics[sub_name] = {
                name = sub_name,
                median_weight = median_weight,
                median_depth = median_depth,
                std_dev = std_deviation,
                count = count,
                parent = profile.parent_group
            }
        end
    end
end

subgroup_profile_data.__index = subgroup_profile_data

return subgroup_profile_data