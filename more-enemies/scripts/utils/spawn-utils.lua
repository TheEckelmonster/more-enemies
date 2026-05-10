local storage

local math_floor = math.floor
local math_random = math.random

local Constants = Constants

local Utils = require("__core__.lualib.util")
local deepcopy = Utils.table.deepcopy

local Entity_Validations = require("scripts.validations.entity-validations")
local get_mod_name = Entity_Validations.get_mod_name
local Settings_Service = require("scripts.service.settings-service")
local get_difficulty = Settings_Service.get_difficulty
local get_do_evolution_factor = Settings_Service.get_do_evolution_factor
local Settings_Utils = require("scripts.utils.settings-utils")
local is_vanilla = Settings_Utils.is_vanilla

local spawn_utils = {}

local locals = {}

local difficulties = nil

function spawn_utils.clone_entity(entity, optionals)
    -- Log.debug("spawn_utils.clone_entity")
    -- Log.info(entity)
    -- Log.info(optionals)

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

    if (not clone_settings or not entity) then return end
    if (not entity.valid) then return end

    if (not difficulties) then
        storage.difficulties = storage.difficulties or {}
        difficulties = storage.difficulties

        difficulties[optionals.surface_name] = difficulties[optionals.surface_name] or deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_difficulty(optionals.surface_name)]])
    end

    local selected_difficulty = difficulties[optionals.surface_name]
    if (not selected_difficulty) then return end

    local surface = entity.surface
    if (not surface or not surface.valid) then return end
    if (is_vanilla(optionals.surface_name)) then return end

    local use_evolution_factor = get_do_evolution_factor(optionals.surface_name)
    if (optionals.mod_name and optionals.mod_name == "BREAM") then use_evolution_factor = Settings_Service.get_BREAM_use_evolution_factor() end

    local evolution_multiplier = 1
    local evolution_factor = 0
    if (use_evolution_factor) then
        evolution_factor = entity.force.get_evolution_factor(entity.surface)
    end
    evolution_multiplier = locals.calc_evolution_multiplier(selected_difficulty, evolution_factor)

    local loop_len = 0
    local clone_setting = 0

    local function loop_len_fun(clone_setting, evolution_multiplier)
        if (clone_setting >= 0 and clone_setting <= 1) then
            return (clone_setting * selected_difficulty.value) * evolution_multiplier + 1
        else
            return (clone_setting + selected_difficulty.value) * evolution_multiplier
        end
    end

    if (clone_settings.type == "unit") then
        clone_setting = clone_settings.unit
        loop_len = loop_len_fun(clone_setting, evolution_multiplier)
    elseif (clone_settings.type == "unit-group") then
        clone_setting = clone_settings.unit_group
        loop_len = loop_len_fun(clone_setting, evolution_multiplier)
    else
        loop_len = selected_difficulty.value * evolution_multiplier
    end

    local clones = {}

    local function cloner(entity, find_non_colliding_position, clone)
        if (not entity.valid) then return end
        local surface = entity.surface
        if (not surface or not surface.valid) then return end

        return {
            clone = clone({
                position = find_non_colliding_position(entity, entity.position, math_random(0.01, 1.1), 0.01) or entity.position,
                surface = entity.surface.name,
                force = entity.force
            }),
            mod_name = get_mod_name(optionals)
        }
    end

    local function fun(loop_len, clones, obj)
        if (obj and obj.valid and surface and surface.valid) then
            local cloner = cloner
            local find_non_colliding_position = surface.find_non_colliding_position
            local clone = obj.clone

            for i = 1, math_floor(loop_len) do
                clones[i] = cloner(obj, find_non_colliding_position, clone)
            end
        end
    end

    if (clone_setting ~= 1) then
        -- Settings are different from default
        -- -> use the user settings instead
        if (use_evolution_factor) then
            -- Log.debug("user settings with evolution_factor")
            fun(loop_len, clones, entity)
        else
            -- Log.debug("user settings without evolution_factor")
            fun(clone_setting + selected_difficulty.value, clones, entity)
        end
    else
        if (use_evolution_factor) then
            -- Log.debug("standard settings with evolution_factor")
            fun(loop_len, clones, entity)
        else
            -- Log.debug("standard settings without evolution_factor")
            -- -- No changes -> use selected difficulty
            fun(selected_difficulty.value, clones, entity)
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