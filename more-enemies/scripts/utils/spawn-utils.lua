local storage
local difficulties
local stats

local game

local function set_game(__game, __storage)
    storage = __storage or _ENV.storage

    storage.stats = storage.stats or {}
    stats = storage.stats

    storage.difficulties = storage.difficulties or {}
    difficulties = storage.difficulties

    --[[ game ]]
    game = __game or _ENV.game

    Set_Num_Clones()

    return game
end

local script = script
local active_mods = script and script.active_mods or nil

local math_floor = math.floor
local math_random = math.random

local Constants = Constants

local Utils = require("__core__.lualib.util")
local deepcopy = Utils.table.deepcopy

local Settings_Service = require("scripts.service.settings-service")
local get_BREAM_use_evolution_factor = Settings_Service.get_BREAM_use_evolution_factor
local get_difficulty = Settings_Service.get_difficulty
local Settings_Utils = require("scripts.utils.settings-utils")
local is_vanilla = Settings_Utils.is_vanilla

local spawn_utils = {}
spawn_utils.name = "spawn_utils"
spawn_utils.set_game = set_game

local function loop_len_fun(selected_difficulty, clone_setting, evolution_multiplier)
    if (not selected_difficulty) then return 0 end
    clone_setting = clone_setting or 0
    evolution_multiplier = evolution_multiplier or 0

    if (clone_setting >= 0 and clone_setting <= 1) then
        return (clone_setting * selected_difficulty.value) * evolution_multiplier + 1
    else
        return (clone_setting + selected_difficulty.value) * evolution_multiplier
    end
end

function spawn_utils.clone_entity(entity, params)
    -- Log.debug("spawn_utils.clone_entity")
    -- Log.info(entity)
    -- Log.info(optionals)

    params = params or {
        clone_settings = {
            unit = 1,
            unit_group = 1
        },
        type = "unit",
        tick = 0,
        surface_name = nil,
        evolution_factor = 0.01,
        evolution_multiplier = 1,
        use_evolution_factor = true
    }

    local clone_settings = params.clone_settings

    if (not clone_settings or not entity) then return end
    if (not entity.valid) then return end

    local surface_name = params.surface_name or entity.surface.valid and entity.surface.name

    difficulties = difficulties or set_game() and difficulties
    difficulties[surface_name] = difficulties[surface_name] or deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_difficulty(surface_name)]])

    local selected_difficulty = difficulties[surface_name]
    if (not selected_difficulty) then return end

    local surface = entity.surface
    if (not surface or not surface.valid) then return end
    if (is_vanilla(surface_name)) then return end

    if (active_mods and active_mods["BREAM"]) then params.use_evolution_factor = get_BREAM_use_evolution_factor() end

    local loop_len = 0
    local clone_setting = 0

    if (clone_settings.type == "unit") then
        clone_setting = clone_settings.unit
        loop_len = loop_len_fun(selected_difficulty, clone_setting, params.evolution_multiplier)
    elseif (clone_settings.type == "unit-group") then
        clone_setting = clone_settings.unit_group
        loop_len = loop_len_fun(selected_difficulty, clone_setting, params.evolution_multiplier)
    else
        loop_len = selected_difficulty.value * params.evolution_multiplier
    end

    local clones = {}
    local rand = math_random(0.01, 1.1)

    local function cloner(entity, find_non_colliding_position, clone, rand)
        if (not entity.valid) then return end
        local surface = entity.surface
        if (not surface or not surface.valid) then return end

        return {
            clone = clone({
                position = find_non_colliding_position(entity, entity.position, rand, 0.03) or entity.position,
                surface = entity.surface.name,
                force = entity.force
            }),
        }
    end

    local function fun(loop_len, clones, obj, rand)
        if (obj and obj.valid and surface and surface.valid) then
            local cloner = cloner
            local find_non_colliding_position = surface.find_non_colliding_position
            local clone = obj.clone

            for i = 1, math_floor(loop_len) do
                clones[i] = cloner(obj, find_non_colliding_position, clone, rand)
            end
        end
    end

    if (clone_setting ~= 1) then
        -- Settings are different from default
        -- -> use the user settings instead
        if (params.use_evolution_factor) then
            -- Log.debug("user settings with evolution_factor")
            fun(loop_len, clones, entity, rand)
        else
            -- Log.debug("user settings without evolution_factor")
            fun(clone_setting + selected_difficulty.value, clones, entity, rand)
        end
    else
        if (params.use_evolution_factor) then
            -- Log.debug("standard settings with evolution_factor")
            fun(loop_len, clones, entity, rand)
        else
            -- Log.debug("standard settings without evolution_factor")
            -- -- No changes -> use selected difficulty
            fun(selected_difficulty.value, clones, entity, rand)
        end
    end

    return clones
end

function spawn_utils.calc_evolution_multiplier(selected_difficulty, evolution_factor)
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