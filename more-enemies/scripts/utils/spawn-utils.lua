local storage

local math_ceil = math.ceil
local math_random = math.random

local Constants = require("libs.constants.constants")
local Entity_Validations = require("scripts.validations.entity-validations")
local Initialization = require("scripts.initialization")
local Log = require("libs.log.log")
local Mod_Repository = require("scripts.repositories.mod-repository")
local More_Enemies_Repository = require("scripts.repositories.more-enemies-repository")
local Difficulty_Utils = require("scripts.utils.difficulty-utils")
local Settings_Service = require("scripts.service.settings-service")
local Settings_Utils = require("scripts.utils.settings-utils")

local BREAM_active = script and script.active_mods and script.active_mods["BREAM"]

local spawn_utils = {}

local locals = {}

function spawn_utils.duplicate_unit_group(group)
    -- Log.debug("spawn.duplicate_unit_group")
    -- Log.info(group)

    -- local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()
    storage.more_enemies = storage.more_enemies or More_Enemies_Repository.get_more_enemies_data()
    local more_enemies_data = storage.more_enemies
    -- if (not more_enemies_data.valid) then more_enemies_data = Initialization.reinit() end

    if (not more_enemies_data.do_nth_tick) then return end
    if (not group or not group.valid or not group.surface or not group.surface.valid) then return end
    if (Settings_Utils.is_vanilla(group.surface.name)) then return end

    -- Log.debug("duplicate_unit_group: Getting difficulty")
    local difficulty = Difficulty_Utils.get_difficulty(group.surface.name).difficulty
    if (not difficulty or not difficulty.valid) then
        Log.warn("difficulty was nil or invalid; reindexing")
        difficulty = Difficulty_Utils.get_difficulty(group.surface.name, true).difficulty
    end
    if (not difficulty or not difficulty.valid) then
        Log.error("Failed to find a valid difficulty for " .. serpent.block(group.surface.name))
        return
    end

    -- Log.info(difficulty)
    local selected_difficulty = difficulty.selected_difficulty
    -- Log.info("selected_difficulty: " .. serpent.block(selected_difficulty))

    local use_evolution_factor = Settings_Service.get_do_evolution_factor(group.surface.name)

    local evolution_factor = 1
    -- Log.info("use_evolution_factor = " .. serpent.block(use_evolution_factor))
    if (use_evolution_factor) then
        evolution_factor = group.force.get_evolution_factor(group.surface)
    end

    local modifier = evolution_factor ^ ((Constants.difficulty.INSANITY.value - selected_difficulty.value) / (evolution_factor * (Constants.difficulty.INSANITY.value - selected_difficulty.value + 1)))

    if (modifier < 0) then modifier = modifier * -1 end
    if (modifier > 1) then modifier = 1 end

    local len = math_ceil(#group.members * (modifier))

    if (not more_enemies_data.staged_clones[group.surface.name]) then
        more_enemies_data.staged_clones[group.surface.name] = {}
    end
    if (not more_enemies_data.staged_clones[group.surface.name].unit_group) then
        more_enemies_data.staged_clones[group.surface.name].unit_group = {}
    end

    -- Log.info("len: " .. serpent.block(len))
    for i = 1, len do
        local member = group.members[i]
        if (member and member.valid) then
            -- Log.debug("adding member to staged_clones")
            more_enemies_data.staged_clones[group.surface.name].unit_group[member.unit_number] = {
                obj = member,
                group = group
            }
        end
    end
end

function spawn_utils.clone_entity(default_value, difficulty, entity, optionals)
    -- Log.debug("spawn_utils.clone_entity")
    -- Log.info(default_value)
    -- Log.info(difficulty)
    -- Log.info(entity)
    -- Log.info(optionals)

    -- local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()
    storage.more_enemies = storage.more_enemies or More_Enemies_Repository.get_more_enemies_data()
    local more_enemies_data = storage.more_enemies
    -- if (not more_enemies_data.valid) then more_enemies_data = Initialization.reinit() end

    if (not more_enemies_data.do_nth_tick) then return end

    optionals = optionals or {
        clone_settings = {
            unit = 1,
            unit_group = 1
        },
        type = "unit",
        tick = 0,
        mod_name = nil,
        surface = nil,
    }

    local clone_settings = optionals.clone_settings

    -- Validate inputs
    if (clone_settings == nil or not default_value or not difficulty or not entity) then return end
    -- Log.info("past 1")
    if (not difficulty.valid or not entity.valid) then return end
    -- Log.info("past 2")
    if (not difficulty.selected_difficulty and optionals.surface) then
        Log.debug("clone_entity: Getting difficulty")
        difficulty = Difficulty_Utils.get_difficulty(optionals.surface.name).difficulty
        if (not difficulty or not difficulty.valid) then
            Log.warn("difficulty was nil or invalid; reindexing")
            difficulty = Difficulty_Utils.get_difficulty(optionals.surface.name, true).difficulty
        end
        if (not difficulty or not difficulty.valid) then
            Log.error("Failed to find a valid difficulty for " .. serpent.block(optionals.surface.name))
            return
        end

        if (not difficulty.selected_difficulty) then return end
    end
    -- Log.info("past 3")
    local surface = entity.surface
    if (not surface or not surface.valid) then return end
    if (Settings_Utils.is_vanilla(surface.name)) then return end
    -- Log.info("past validations")

    local use_evolution_factor = Settings_Service.get_do_evolution_factor(surface.name)

    if (optionals.mod_name and optionals.mod_name == "BREAM") then
        use_evolution_factor = Settings_Service.get_BREAM_use_evolution_factor(surface.name)
    end

    local evolution_multiplier = 1
    local evolution_factor = 0
    if (use_evolution_factor) then
        evolution_factor = entity.force.get_evolution_factor(entity.surface)
    end
    evolution_multiplier = locals.calc_evolution_multiplier(difficulty.selected_difficulty, evolution_factor)
    -- Log.debug(evolution_multiplier)

    local loop_len = 0
    local clone_setting = 0

    -- Log.info(difficulty.selected_difficulty.value)
    -- Log.info(evolution_multiplier)
    local loop_len_fun = function(clone_setting, difficulty, evolution_multiplier)
        if (clone_setting >= 0 and clone_setting <= 1) then
            return (clone_setting * difficulty.selected_difficulty.value) * evolution_multiplier + 1
        else
            return (clone_setting + difficulty.selected_difficulty.value) * evolution_multiplier
        end
    end

    if (clone_settings.type == "unit") then
        clone_setting = clone_settings.unit
        loop_len = loop_len_fun(clone_setting, difficulty, evolution_multiplier)
    elseif (clone_settings.type == "unit-group") then
        clone_setting = clone_settings.unit_group
        loop_len = loop_len_fun(clone_setting, difficulty, evolution_multiplier)
    else
        loop_len = difficulty.selected_difficulty.value * evolution_multiplier
    end
    -- Log.info("loop_len after calcs")
    -- Log.info(loop_len)

    local clones = {}

    -- Log.info("at cloner definition")
    local cloner = function(entity, clone_limit, type)
        -- Log.info("Cloning")
        if (not entity.valid) then return end
        local surface = entity.surface
        if (not surface or not surface.valid) then return end

        storage.more_enemies = storage.more_enemies or More_Enemies_Repository.get_more_enemies_data()
        local more_enemies_data = storage.more_enemies
        -- if (not more_enemies_data.valid) then more_enemies_data = Initialization.reinit() end

        local clone = nil

        if (not more_enemies_data.do_nth_tick) then return clone end

        if ((type == "unit-group"
                    and more_enemies_data.clone[surface.name].unit_group > clone_limit)
                or (type == "unit"
                    and more_enemies_data.clone[surface.name].unit > clone_limit))
        then
            if (not Entity_Validations.get_mod_name(optionals) or optionals.mod_name ~= "BREAM") then
                -- Log.warn("Tried to clone more than the " .. type .. " limit: " .. serpent.block(clone_limit))
                -- Log.warn("Currently " .. serpent.block(clone_limit) .. " clones")
                return
            end
        end

        if (BREAM_active) then
            local mod_data = Mod_Repository.get_mod_data()
            if (not mod_data) then return end
            if (not mod_data.clone) then return end
            if (not mod_data.clone[surface.name]) then return end
            if (not mod_data.clone[surface.name].count) then return end

            local max_num_modded_clones = Settings_Service.get_maximum_number_of_modded_clones()

            if (mod_data.clone[surface.name].count > max_num_modded_clones
                    and Entity_Validations.get_mod_name(optionals))
            then
                -- Log.warn("Tried to clone more than the mod unit limit: " .. serpent.block(max_num_modded_clones))
                -- Log.warn("Currently " .. serpent.block(mod_data.clone[surface.name].count) .. " clones")
                return
            end
        end

        local position = entity.surface.find_non_colliding_position(entity, entity.position, math_random(0.01, 1.1), 0.01)

        clone = entity.clone({
            -- position = entity.position,
            position = position or entity.position,
            -- position = {
            --   -- TODO: Make configurable
            --   x = entity.position.x + math_random(-0.0025, 0.0025),
            --   y = entity.position.y + math_random(-0.0025, 0.0025)
            -- },
            surface = entity.surface.name,
            force = entity.force
        })

        -- Log.debug("Cloned")
        -- Log.info(clone)

        if (Entity_Validations.get_mod_name(optionals)) then
            more_enemies_data.mod.clone[surface.name].count = more_enemies_data.mod.clone[surface.name].count + 1
        else
            if (type == "unit-group") then
                more_enemies_data.clone[surface.name].unit_group = more_enemies_data.clone[surface.name].unit_group + 1
            else
                more_enemies_data.clone[surface.name].unit = more_enemies_data.clone[surface.name].unit + 1
            end
        end

        -- Log.info(clone)
        return {
            clone = clone,
            mod_name = Entity_Validations.get_mod_name(optionals)
        }
    end -- End cloner = function (entity)

    -- Log.debug("at fun definition")
    local fun = function(loop_len, clones, obj, cloner, type, mod_name)
        -- local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()
        storage.more_enemies = storage.more_enemies or More_Enemies_Repository.get_more_enemies_data()
        local more_enemies_data = storage.more_enemies
        -- if (not more_enemies_data.valid) then more_enemies_data = Initialization.reinit() end

        local surface = obj.surface
        if (not surface or not surface.valid) then return end

        local clone_limit = 0

        if (mod_name) then
            clone_limit = Settings_Service.get_maximum_number_of_modded_clones()
        else
            if (type == "unit-group") then
                clone_limit = Settings_Service.get_maximum_number_of_unit_group_clones(surface.name)
            else
                clone_limit = Settings_Service.get_maximum_number_of_spawned_clones(surface.name)
            end
        end

        if (not clone_limit or clone_limit < 1) then return end

        local max_num_modded_clones = Settings_Service.get_maximum_number_of_modded_clones()

        for i = 1, math.floor(loop_len) do
            -- Log.info("i = " .. serpent.block(i))
            if (not more_enemies_data.do_nth_tick) then return end

            if (mod_name) then
                if (BREAM_active) then
                    local mod_data = Mod_Repository.get_mod_data()
                    if (not mod_data) then return end
                    if (not mod_data.clone) then return end
                    if (not mod_data.clone[surface.name]) then return end
                    if (not mod_data.clone[surface.name].count) then return end
                    if (mod_data.clone[surface.name].count > max_num_modded_clones) then return end
                else
                    return
                end
            elseif (more_enemies_data.clone) then
                if (type == "unit-group") then
                    if (not more_enemies_data.clone[surface.name].unit_group or more_enemies_data.clone[surface.name].unit_group > Settings_Service.get_maximum_number_of_unit_group_clones(surface.name)) then return end
                else
                    if (not more_enemies_data.clone[surface.name].unit or more_enemies_data.clone[surface.name].unit > Settings_Service.get_maximum_number_of_spawned_clones(surface.name)) then return end
                end
            end

            if (mod_name) then
                if (BREAM_active) then
                    local mod_data = Mod_Repository.get_mod_data()
                    if (not mod_data) then return end
                    if (not mod_data.clone) then return end
                    if (not mod_data.clone[surface.name]) then return end
                    if (not mod_data.clone[surface.name].count) then return end

                    if (mod_data.clone[surface.name].count > max_num_modded_clones
                            and Entity_Validations.get_mod_name(optionals) ~= nil)
                    then
                        -- Log.warn("Tried to clone more than the mod unit limit: " .. serpent.block(max_num_modded_clones))
                        -- Log.warn("Currently " .. serpent.block(mod_data.clone[surface.name].count) .. " clones")
                        return
                    end
                end
            end

            clones[i] = cloner(obj, clone_limit, type)
        end
    end -- End fun = function (loop_len, limit, clones, obj, cloner)

    if (clone_setting ~= default_value.value) then
        -- Settings are different from default
        -- -> use the user settings instead
        if (use_evolution_factor) then
            -- Log.debug("user settings with evolution_factor")
            -- Log.debug(loop_len)
            fun(loop_len, clones, entity, cloner, clone_settings.type, optionals.mod_name)
        else
            -- Log.debug("user settings without evolution_factor")
            -- Log.debug(clone_setting + difficulty.selected_difficulty.value)
            fun(clone_setting + difficulty.selected_difficulty.value, clones, entity, cloner, clone_settings.type, optionals.mod_name)
        end
    else
        if (use_evolution_factor) then
            -- Log.debug("standard settings with evolution_factor")
            -- Log.debug(loop_len)
            fun(loop_len, clones, entity, cloner, clone_settings.type, optionals.mod_name)
        else
            -- Log.debug("standard settings without evolution_factor")
            -- -- No changes -> use selected difficulty
            -- Log.debug(difficulty.selected_difficulty.value)
            fun(difficulty.selected_difficulty.value, clones, entity, cloner, clone_settings.type, optionals.mod_name)
        end
    end

    return clones
end

function locals.calc_evolution_multiplier(selected_difficulty, evolution_factor)
    --   Log.debug("locals.calc_evolution_multiplier")
    --   Log.info(selected_difficulty)
    --   Log.info(evolution_factor)

    -- Validate inputs
    evolution_factor = evolution_factor or 0
    if (not selected_difficulty or not selected_difficulty.valid) then return evolution_factor end

    -- Calculate the evolution factor
    -- [Old]
    -- https://www.wolframalpha.com/input?i=x%5E%28y%2F%28x%5E%28y%2Fx%29%29%29+*+%28y%5Ex%29

    -- [Current]
    -- https://www.wolframalpha.com/input?i=x%5E%28y%2F%28x%5E%28y%2Fx%29%29%29+*+y%2C+y%3D0+to+1
    --  -> Replace 'x' in the equation with the selected difficulty to graph the corresponding curve
    local value = ((selected_difficulty.value ^ (evolution_factor / (selected_difficulty.value ^ (evolution_factor / selected_difficulty.value)))) * evolution_factor)
    --   Log.debug("evolution multiplier: " .. value)
    return value
end

function spawn_utils.init(__storage)
    storage = __storage
end

return spawn_utils