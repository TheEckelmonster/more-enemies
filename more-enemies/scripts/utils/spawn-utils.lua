local storage
local difficulties
local evolution_factors
local vanilla

local game
local planetary_surfaces

local Set_Game_Funcs = Set_Game_Funcs

local function set_game(event, __game, __storage)
    storage = __storage or _ENV.storage

    storage.difficulties = storage.difficulties or {}
    difficulties = storage.difficulties

    storage.evolution_factors = storage.evolution_factors or {}
    evolution_factors = storage.evolution_factors

    storage.vanilla = storage.vanilla or {}
    vanilla = storage.vanilla

    game = __game or _ENV.game

    Set_Game_Funcs()
    -- forces = _ENV.Forces
    -- force_funcs = _ENV.Force_Funcs

    planetary_surfaces = _ENV.Surfaces
    -- surface_funcs = _ENV.Surface_Funcs

    return game
end

local script = script
local active_mods = script and script.active_mods or nil

local math_floor = math.floor
local math_sin = math.sin
local math_random = math.random
local type = type

local PI = math.pi
local TWO_PI  = 2 * PI

local Constants = Constants
local Startup_Settings_Constants = Startup_Settings_Constants

local Utils = require("__core__.lualib.util")
local deepcopy = Utils.table.deepcopy

local Settings_Service = require("scripts.service.settings-service")
local get_startup_setting = Settings_Service.get_startup_setting
local Settings_Utils = require("scripts.utils.settings-utils")
local is_vanilla = Settings_Utils.is_vanilla

local use_evolution_factor = {}
for _, surface_name in ipairs(Planets or {}) do
    local setting = Runtime_Global_Settings_Constants.settings[surface_name:gsub("%-", "_"):upper() .. "_DO_EVOLUTION_FACTOR"]
    if (setting and setting.name) then
        use_evolution_factor[surface_name] = Data_Utils.get_runtime_global_setting({ setting = setting.name, }) or false
    end
end

local ENEMY = ENEMY

local spawn_utils = {}
spawn_utils.name = "spawn_utils"
spawn_utils.set_game = set_game

local clone_settings = {
    unit = 1,
    unit_group = 1,
}
local evolution_multiplier = 1
local types = { ["unit"] = "unit", ["unit-group"] = "unit-group", }
function spawn_utils.clone_entity(entity, unit_type, surface_name, unit_clone_setting, unit_group_clone_setting, tick)
    -- Log.debug("spawn_utils.clone_entity")
    -- Log.info(entity)
    -- Log.info(optionals)

    if (not entity or not entity.valid) then return end

    surface_name = surface_name or entity.surface.valid and entity.surface.name

    tick = tick or (game or set_game()).tick

    clone_settings.unit = unit_clone_setting or 1
    clone_settings.unit_group = unit_group_clone_setting or 1

    difficulties = difficulties or set_game() and difficulties
    difficulties[surface_name] = (difficulties or set_game() and difficulties) and difficulties[surface_name] or deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_startup_setting({ setting = (Startup_Settings_Constants.settings[surface_name:gsub("%-", "_"):upper() .. "_DIFFICULTY"] or Startup_Settings_Constants.settings["FALLBACK_DIFFICULTY"]).name, reindex = true, }) or "Vanilla"]])

    local selected_difficulty = difficulties[surface_name]
    if (not selected_difficulty) then return end

    local surface = (planetary_surfaces or set_game() and planetary_surfaces) and planetary_surfaces[surface_name]
    if (not surface or not surface.valid) then
        surface = entity.surface
        if (not surface or not surface.valid) then return end
        planetary_surfaces.list = planetary_surfaces.list or {}
        planetary_surfaces[surface_name] = entity.surface
        planetary_surfaces.list[entity.surface.index] = surface_name
    end
    vanilla = vanilla or set_game() and vanilla
    vanilla[surface_name] = vanilla[surface_name] or { is_vanilla = is_vanilla(surface_name), surface_name = surface_name, tick = tick + 90, }
    if (vanilla[surface_name].tick < tick) then
        vanilla[surface_name].is_vanilla = is_vanilla(surface_name)
        vanilla[surface_name].surface_name = surface_name
        vanilla[surface_name].tick = tick + 90
    end

    local loop_len = 0

    evolution_factors = evolution_factors or set_game() or evolution_factors
    evolution_factors[surface_name] = evolution_factors[surface_name] or { evolution_multiplier = spawn_utils.calc_evolution_multiplier(selected_difficulty, entity.force.get_evolution_factor(surface_name)), tick = tick + 60, }
    if (use_evolution_factor[surface_name]) then
        if (evolution_factors[surface_name].tick > tick) then
            evolution_factors[surface_name].evolution_multiplier = spawn_utils.calc_evolution_multiplier(selected_difficulty, entity.force.get_evolution_factor(surface_name))
            evolution_factors[surface_name].surface_name = surface_name
            evolution_factors[surface_name].tick = tick + 1
        end
        evolution_multiplier = evolution_factors[surface_name].evolution_multiplier
    else
        evolution_multiplier = (selected_difficulty and selected_difficulty.fallback_evolution_multiplier or (function (arr)
            if (arr and arr[1] and arr[2]) then
                arr[1].fallback_evolution_multiplier = arr[2] and (arr[2] ^ 0.5) or 1
                return arr[1].fallback_evolution_multiplier
            end
            return 1
        end)({ selected_difficulty, selected_difficulty.value }))
    end

    if (types[unit_type]) then
        loop_len = math_floor(((clone_settings[unit_type] or 0) + selected_difficulty.value) * (use_evolution_factor[surface_name] and evolution_multiplier or selected_difficulty.fallback_evolution_multiplier or 1)
                 + (((clone_settings[unit_type] or 1) * selected_difficulty.value) * (use_evolution_factor[surface_name] and evolution_multiplier or selected_difficulty.fallback_evolution_multiplier or 1)) + 1)
    else
        loop_len = math_floor(1.5 * (selected_difficulty.value * selected_difficulty.value) * (use_evolution_factor[surface_name] and evolution_multiplier or selected_difficulty.fallback_evolution_multiplier or 1) + 1)
    end

    local clones = {}

    if (entity and entity.valid and surface and surface.valid) then
        local force_name = entity.force and entity.force.valid and entity.force.name or ENEMY
        local clone = entity.clone
        local name = entity.name
        local find_non_colliding_position = surface.find_non_colliding_position
        local source_position = entity.position
        local position = source_position
        local clone_tbl = {
            position = position,
            surface = surface_name,
            force = force_name,
        }

        local sine = 0
        local remainder = 0
        local dx, dy = 0, 0

        for i = 1, loop_len do
            sine = math_sin(TWO_PI * ((i - 1) / loop_len))
            remainder = i % 4
            if (remainder == 0) then
                dx , dy = sine, sine
            elseif (remainder == 1) then
                dx , dy = 0 - sine, sine
            elseif (remainder == 2) then
                dx , dy = sine, 0 - sine
            elseif (remainder == 3) then
                dx , dy = 0 - sine, 0 - sine
            else
                local rand = (math_random(110) + 1) / 100
                dx , dy = rand - sine, rand - sine
            end

            position.x = position.x + dx
            position.y = position.y + dy
            clone_tbl.position = find_non_colliding_position(name, position, 1.5 * loop_len, 0.2)

            if (not entity.valid) then break end
            clones[i] = clone(clone_tbl)
        end
    end

    return clones
end

function spawn_utils.calc_evolution_multiplier(selected_difficulty, evolution_factor)

    -- Validate inputs
    evolution_factor = evolution_factor or 0
    if (not selected_difficulty) then return evolution_factor end
    local value = selected_difficulty.value or 1

    -- Calculate the evolution factor
    -- [Old]
    -- https://www.wolframalpha.com/input?i=x%5E%28y%2F%28x%5E%28y%2Fx%29%29%29+*+%28y%5Ex%29

    -- [Current]
    -- https://www.wolframalpha.com/input?i=x%5E%28y%2F%28x%5E%28y%2Fx%29%29%29+*+y%2C+y%3D0+to+1
    --  -> Replace 'x' in the equation with the selected difficulty to graph the corresponding curve
    local value = ((value ^ (evolution_factor / (value ^ (evolution_factor / value)))) * evolution_factor)

    return value
end

local update_settings = {}

local NAUVIS = NAUVIS
local ESCAPED_DASH = ESCAPED_DASH
local UNDERSCORE = UNDERSCORE
for _, planet in ipairs(Planets or { NAUVIS, }) do
    local idx = planet:gsub(ESCAPED_DASH, UNDERSCORE):upper()
    local setting = Runtime_Global_Settings_Constants.settings[idx .. "_DO_EVOLUTION_FACTOR"]
    if (setting and setting.name) then
        update_settings[setting.name] = function (event, params) use_evolution_factor[planet] = params.setting_value end
    end
end

local STRING = Types.STRING
function spawn_utils.on_runtime_mod_setting_changed(event, params)
    if (not event.setting or type(event.setting) ~= STRING) then return end
    if (not event.setting_type or type(event.setting_type) ~= STRING) then return end

    if (not (event.setting:find(ME_PREFIX, 1, true) == 1)) then return end

    if (update_settings[event.setting]) then
        update_settings[event.setting](event, params)
    end
end
Settings_Registry:register_setting({
    func_name = "spawn_service_settings",
    func = spawn_utils.on_runtime_mod_setting_changed
})


function spawn_utils.init(__storage) storage = __storage or _ENV.storage end

return spawn_utils