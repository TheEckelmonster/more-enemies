local data = data

local math_floor = math.floor
local math_log = math.log
local math_exp = math.exp
local math_max = math.max
local math_min = math.min
local pairs = pairs
local string_find = string.find
local type = type

local CRAFTING = "crafting"
local E = math_exp(1)

local Mod_Data = require("__TheEckelmonster-core-library__.libs.mod-data.mod-data")

local Constants = require("scripts.constants.constants")

local Macro_Compiler = require("prototypes.omni-mind.macro-compiler")

local dynamic_subgroup_weights = Macro_Compiler.dynamic_subgroup_weights or require("prototypes.omni-mind.subgroup-weights")
local dynamic_subgroup_priorities = Macro_Compiler.dynamic_subgroup_priorities or require("prototypes.omni-mind.subgroup-priority")

local science_pack_tiers = require("prototypes.omni-mind.technology-tiers")

local entity_priorities = {
    ["character"] = 9,
    ["character-corpse"] = 6,
}

local evalutated_tech_cache, technology_stack = {}, {}
local function calc_max_technology_depth(params)
    if (type(params) ~= "table") then return 0 end
    local technologies = params.technologies
    local single_tech = params.technology
    local raw_technologies = data.raw.technology

    local tech_list = technologies or { single_tech, }
    local global_max_depth = 0

    for _, tech in pairs(tech_list) do
        if (type(tech.prerequisites) == "table") then
            local t_name = tech.name

            if (technology_stack[t_name]) then goto continue end
            if (evalutated_tech_cache[t_name]) then
                if (evalutated_tech_cache[t_name] > global_max_depth) then
                    global_max_depth = evalutated_tech_cache[t_name]
                end
                goto continue
            end

            technology_stack[t_name] = 1
            local local_max_prereq_depth = 0

            if (type(tech.prerequisites) == "table") then
                for _, prereq_name in ipairs(tech.prerequisites) do
                    local prereq_tech = raw_technologies[prereq_name]
                    if (type(prereq_tech) == "table") then
                        local p_depth = calc_max_technology_depth({ technology = prereq_tech, })
                        if (p_depth > local_max_prereq_depth) then
                            local_max_prereq_depth = p_depth
                        end
                    end
                end
            end

            technology_stack[t_name] = nil

            local calculated_node_depth = 1 + local_max_prereq_depth
            evalutated_tech_cache[t_name] = calculated_node_depth
            if (calculated_node_depth > global_max_depth) then global_max_depth = calculated_node_depth end
        end

        ::continue::
    end

    return global_max_depth
end
local max_technology_depth = calc_max_technology_depth({ technologies = data.raw.technology, })

local function find_recipe_for(name)
    if (type(name) ~= "string") then return end
    if (name:find("%-rocket%-silo$")) then log(name) end

    local direct_recipe = data.raw.recipe[name]
    if (type(direct_recipe) == "table") then return direct_recipe end

    for _, recipe in pairs(data.raw.recipe) do
        if (recipe.name == name) then return recipe end
        if (recipe.main_product == name) then return recipe end

        local results = recipe.results
        if (type(results) == "table") then
            for _, result in ipairs(recipe.results) do
                if (type(result) == "table") then
                    if (result.name == name) then return recipe end
                elseif (type(result) == "string" and result == name) then
                    return recipe
                end
            end
        end
    end

    return nil
end

local function compute_recipe_complexity(recipe)
    if (type(recipe) ~= "table") then return 0.0 end

    local depth, max_depth_found = 1, 1
    local active_processing_stack = {}
    local evalutated_cache = {}

    local ingredients = recipe.ingredients
    if (type(ingredients) ~= "table" or not ingredients[1]) then return 0.0 end

    local function compute_recursively(current_recipe)
        if (type(current_recipe) ~= "table") then return 0.0 end
        local recipe_name = current_recipe.name

        if (active_processing_stack[recipe_name]) then return 2.0 end
        if (evalutated_cache[recipe_name]) then return evalutated_cache[recipe_name] end

        active_processing_stack[recipe_name] = true
        depth = depth + 1
        if (depth > max_depth_found) then max_depth_found = depth end

        local ingredients = current_recipe.ingredients
        if (type(ingredients) ~= "table" or not ingredients[1]) then
            depth = depth - 1
            active_processing_stack[recipe_name] = nil
            return 0.0
        end

        local total_ingredient_score = 0.0

        for _, ingredient in ipairs(ingredients) do
            local ing_name = ingredient.name
            local ing_type = ingredient.type or "item"
            local ing_amount = ingredient.amount or 1

            local subgroup = ""
            local item = data.raw.item[ing_name]
            if (not item) then
                item = data.raw.item[current_recipe.name]
                if (not item) then
                    item = data.raw.item[current_recipe.main_product]
                    if (not item) then
                        item = data.raw.item[current_recipe.results and current_recipe.results[1] and current_recipe.results[1].name or nil]
                    end
                end
            end
            if (item) then subgroup = item.subgroup end

            if (ing_type == "fluid") then
                ing_amount = math_max(1, math_floor(ing_amount / 10))
                ing_amount = math_max(1, math_floor(ing_amount ^ 0.5))
            end

            local component_score = 0.0

            if (string_find(ing_name, "%-ore$" or ing_name == "coal" or ing_name == "stone")) then
                component_score = 1.0
            else
                local sub_recipe = find_recipe_for(ing_name)
                if (type(sub_recipe) == "table") then
                    component_score = compute_recursively(sub_recipe) or 0.0
                else
                    component_score = 1.5
                end

                if (subgroup ~= "") then
                    if (subgroup == "raw-resource") then
                        component_score = component_score + 1.0
                    elseif (subgroup == "raw-material") then
                        component_score = component_score + 2.25
                    end
                end
            end

            total_ingredient_score = total_ingredient_score + math_floor((math_min(ing_amount, 5) * component_score * math_floor(depth ^ 0.8)) ^ 0.75)
        end

        local energy = current_recipe.energy_required or 0.5
        local local_recipe_score = total_ingredient_score + math_floor(depth * energy) + (2* #ingredients)

        depth = depth - 1
        active_processing_stack[recipe_name] = nil
        evalutated_cache[recipe_name] = local_recipe_score
        return local_recipe_score
    end

    local raw_score = compute_recursively(recipe)
    local calculated_metric = raw_score ^ 0.65
    calculated_metric = calculated_metric + math_floor((2 ^ math_min(max_depth_found, 8)) / max_depth_found)

    return math_max(12, math_min(256000, calculated_metric)), max_depth_found
end

local function compute_tehcnology_priority(recipe_name)
    if (type(recipe_name) ~= "string") then return 1, 0 end

    local target_technology = nil
    local potential_technologies = {}
    for _, tehcnology in pairs(data.raw.technology or {}) do
        for _, effect in pairs(tehcnology.effects or {}) do
            if (effect.type == "unlock-recipe" and effect.recipe == recipe_name) then
                potential_technologies[#potential_technologies+1] = tehcnology
                break
            end
        end
    end

    if (not potential_technologies[1]) then return 1, 0 end
    target_technology = potential_technologies[1]

    local evalutated_cache, circular_technology_stack = {}, {}

    local function traverse_tech_tree_recursively(technology)
        if (type(technology) ~= "table") then return 0, 0, 0, 0 end

        local tech_name = technology.name

        if (circular_technology_stack[tech_name]) then return 0, 0, 0, 0 end
        if (evalutated_cache[tech_name]) then
            local cached = evalutated_cache[tech_name]
            return  cached.tier or 1,
                    cached.packs or 1,
                    cached.depth or 1,
                    cached.cost or 100
        end

        circular_technology_stack[tech_name] = 1

        local max_science_pack_tier = 1
        local unique_science_pack_count = 0

        local max_depth_found = 0
        local accumulated_parent_cost = 0

        local unit = technology.unit

        local local_node_cost = 0
        if (unit and unit.count) then
            local ingredient_count = (unit.ingredients and #unit.ingredients) or 1
            local_node_cost = unit.count * ingredient_count
        else
            local_node_cost = 2000
        end

        if (unit and unit.ingredients) then
            unique_science_pack_count = #unit.ingredients
            for _, ingredient in ipairs(unit.ingredients or {}) do
                local pack_name = ingredient.name or "unknown"
                local pack_tier = science_pack_tiers[pack_name] or 1

                if (pack_tier > max_science_pack_tier) then max_science_pack_tier = pack_tier end
            end
        end

        local prerequisites = technology.prerequisites
        if (type(prerequisites) == "table") then
            for _, prereq in pairs(prerequisites) do
                local parent_technology = data.raw.technology[prereq or ""]
                if (type(parent_technology) == "table") then
                    local p_tier, p_packs, p_depth, p_cost = traverse_tech_tree_recursively(parent_technology)

                    if (p_tier > max_science_pack_tier) then max_science_pack_tier = p_tier end
                    if (p_packs > unique_science_pack_count) then unique_science_pack_count = p_packs end
                    if (p_depth > max_depth_found) then max_depth_found = (p_depth and p_depth > 0 and p_depth) or 1 end

                    accumulated_parent_cost = accumulated_parent_cost + p_cost
                end
            end
        end

        local total_depth = max_depth_found + 1
        local total_branch_cost = local_node_cost + accumulated_parent_cost

        circular_technology_stack[tech_name] = nil
        evalutated_cache[tech_name] = { tier = max_science_pack_tier, packs = unique_science_pack_count, depth = total_depth, cost = total_branch_cost }
        return max_science_pack_tier, unique_science_pack_count, total_depth, total_branch_cost
    end

    local highest_tier, pack_variety, historical_depth, total_investment_cost = traverse_tech_tree_recursively(potential_technologies[1])

    for i = 2, #potential_technologies, 1 do
        local l_highest_tier, l_pack_variety, l_historical_depth, l_total_investment_cost = traverse_tech_tree_recursively(potential_technologies[i])

        if (l_highest_tier < highest_tier) then highest_tier = l_highest_tier end
        if (l_pack_variety < pack_variety) then pack_variety = l_pack_variety end
        if (l_historical_depth < historical_depth) then historical_depth = l_historical_depth end
        if (l_total_investment_cost < total_investment_cost) then total_investment_cost = l_total_investment_cost end
    end

    local local_max_tier = 1
    local local_unit = target_technology.unit
    for _, ingredient in ipairs(local_unit and local_unit.ingredients or {}) do
        local p_name = ingredient.name or "unknown"
        local p_tier = science_pack_tiers[p_name] or 1
        if (p_tier > local_max_tier) then local_max_tier = p_tier end
    end

    local depth_bonus = 2 * (historical_depth / max_technology_depth)
    local final_priority = math_floor(local_max_tier + depth_bonus)

    local calculated_priority = math_max(highest_tier, pack_variety)

    calculated_priority = math_min(10, math_max(1, math_floor(math_max(calculated_priority, final_priority))))

    return calculated_priority, total_investment_cost or calculated_priority > 4 and 2000 or 100
end

data.raw["mod-data"] = data.raw["mod-data"] or {}
local target_priority_data = data.raw["mod-data"][Constants.mod_name .. "-target-priority-data"] or Mod_Data.create({
    name = Constants.mod_name .. "-target-priority-data",
})

local placeable_entities = {}
for name, item in pairs(data.raw.item or {}) do
    if (type(item.place_result) == "string") then placeable_entities[item.place_result] = name end
end

local flag_blacklist = {
    ["breathes-air"] = 1,
    ["not-selectable-in-game"] = 1,
}

local defines = defines
local types = {}
for entity_type, _ in pairs(defines.prototypes.entity) do
    if (data.raw[entity_type]) then
        for name, prototype in pairs(data.raw[entity_type]) do

            local explicit_priority = entity_priorities[name] or entity_priorities[prototype.type]
            local associated_item = placeable_entities[name]

            if ( not explicit_priority and not associated_item) then goto continue end
            if (prototype.hidden) then goto continue end

            for _, flag in ipairs(prototype.flags or {}) do
                if (flag_blacklist[flag]) then goto continue end
            end

            local recipe = find_recipe_for(name)
            if (type(recipe) ~= "table") then recipe = find_recipe_for(associated_item and associated_item.name or nil) end

            local weight_score = 100.0
            local base_priority = 1
            local total_research_investment = 100.0
            local max_depth_found = 1

            if (type(recipe) ~= "table") then goto continue end

            local complexity, detected_depth = compute_recipe_complexity(recipe)
            weight_score = complexity or weight_score
            detected_depth = detected_depth or max_depth_found

            local tech_priority, accumulated_cost = compute_tehcnology_priority(recipe.name)
            base_priority = tech_priority or base_priority
            total_research_investment = total_research_investment + accumulated_cost

            local investment_factor = 1 + math_log(total_research_investment, 10)

            local final_weight = math_floor(weight_score * investment_factor)

            if (prototype.type == "pipe" or prototype.type == "pipe-to-ground") then
                base_priority = 1
                final_weight = math_floor(E + math_log(final_weight, E))
            elseif (prototype.type == "electric-pole") then
                local max_wire_distance =  prototype.maximum_wire_distance or 0
                local supply_area_distance =  prototype.supply_area_distance or 0

                if (max_wire_distance <= 10 and supply_area_distance < 3.5) then
                    base_priority = 1
                    final_weight = math_floor(E + math_log(final_weight, E))
                elseif (max_wire_distance > 25) then
                    base_priority = 6
                end
            end

            if (    string_find(name, "%-silo")
                or  string_find(name, "landing%-pad")
                or  string_find(name, "icbm")
                or  string_find(name, "ipbm")
                or  string_find(name, "isbm")
                or  string_find(name, "idbm")
            ) then
                base_priority = 10
                final_weight = math_max(final_weight, 200)
            end

            if (prototype.type == "turret" or string_find(prototype.type, "%-turret")) then
                final_weight = math_floor(E + math_log(final_weight, E))
            end
            if (prototype.type == "land-mine" and string_find(prototype.name, "%-land%-mine")) then
                base_priority = math_floor(base_priority ^ 0.65)
            end

            local item = data.raw.item[name]
            item = item or data.raw.item[associated_item]

            local subgroup_name = "unknown"
            if (item and item.subgroup) then
                subgroup_name = item.subgroup
            else
                subgroup_name = recipe and recipe.subgroup or "unknown"
            end

            local weight_multiplier = dynamic_subgroup_weights[subgroup_name] or 1.0
            local priority_modifier = dynamic_subgroup_priorities[subgroup_name]

            if (priority_modifier) then base_priority = math_max(base_priority, priority_modifier) end
            if (explicit_priority) then base_priority = explicit_priority end

            base_priority = math_min(10, math_max(1, base_priority))
            final_weight = math_min(256000, math_max(12, math_floor(weight_multiplier * final_weight)))

            local numerator = (base_priority ^ 2) + (base_priority ^ (base_priority / 2))
            local denominator = 2 ^ base_priority
            local fx_factor = numerator / denominator

            target_priority_data.data[name] = target_priority_data.data[name] or {}
            target_priority_data.data[name].name = name
            target_priority_data.data[name].type = entity_type
            target_priority_data.data[name].subgroup = subgroup_name
            target_priority_data.data[name].recipe_name = recipe.name
            target_priority_data.data[name].recipe = { name = recipe.name, category = recipe.category, }
            target_priority_data.data[name].total_research_investment = total_research_investment
            target_priority_data.data[name].p = base_priority
            target_priority_data.data[name].w = math_floor(final_weight)
            target_priority_data.data[name].fx = math_floor(fx_factor * 10000) / 10000

            Macro_Compiler.recipe_category_profile_data:update_profile({
                entry = target_priority_data.data[name],
                category = recipe.category,
                computed_recipe_compelxity = final_weight,
            })

            Macro_Compiler.subgroup_profile_data:update_profile({
                entry = target_priority_data.data[name],
                subgroup = subgroup_name,
                computed_recipe_compelxity = final_weight,
                computed_tech_depth = detected_depth,
            })

            ::continue::
        end
    end
end

-- log(serpent.block(Macro_Compiler))
-- log(serpent.block(target_priority_data))
Macro_Compiler:execute_balancing({ mod_data = target_priority_data})
-- log(serpent.block(Macro_Compiler))