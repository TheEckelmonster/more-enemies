
local Attack_Group_Service = require("scripts.service.attack-group-service")
-- local Attack_Group_Utils = require("scripts.utils.attack-group-utils")
local Cache_Data = require("scripts.data.cache-data")
local Constants = require("libs.constants.constants")
local Data = require("scripts.data.data")
local Event_Data = require("scripts.data.event-data")
local Insanity_Difficulty_Data = require("scripts.data.difficulties.insanity-difficulty-data")
local Log = require("libs.log.log")
local More_Enemies_Repository = require("scripts.repositories.more-enemies-repository")
local Overmind_Service = require("scripts.service.overmind-service")
local Overmind_Repository = require("scripts.repositories.overmind-repository")
local Overmind_Utils = require("scripts.utils.overmind-utils")
local Settings_Service = require("scripts.service.settings-service")
-- local Version_Validations = require("scripts.validations.version-validations")

local cache = {}

local steps = {
    { name = "process_staged_chunk", },
    { name = "process_ordered_chunk", },
    { name = "process_random_chunk", },
    { name = "process_expansion", },
    { name = "process_random_expansion", },
    { name = "process_highest_attack", },
    { name = "process_random_attack", },
    { name = "process_chunks_priority_high", },
    { name = "process_chunks_priority_medium", },
    { name = "process_chunks_priority_low", },
}

for k, _ in pairs(Constants.chunk_sizes) do if (k < Constants.CHUNK_LEVELS) then table.insert(steps, { name = "process_chunks_" .. k, }) end end

local function chunk_level(data)
    local self = {}

    local function increment(planet)

        if (not storage.overmind_controller[planet.string_val]) then storage.overmind_controller[planet.string_val] = {} end
        storage.overmind_controller[planet.string_val].process_chunks_level = next(Constants.chunk_sizes, storage.overmind_controller[planet.string_val].process_chunks_level)
        if (not storage.overmind_controller[planet.string_val].process_chunks_level) then storage.overmind_controller[planet.string_val].process_chunks_level = next(Constants.chunk_sizes) end
        local process_chunks_level = storage.overmind_controller[planet.string_val].process_chunks_level
        if (not Constants.chunk_sizes[process_chunks_level]) then
            log(serpent.block(process_chunks_level))
            log(serpent.block(storage.overmind_controller))
            error("process_chunks_level is not a valid value")
        end

        if (self ~= storage.overmind_controller) then self = storage.overmind_controller end

        -- log(serpent.block(self))
        -- log(planet.string_val)
        self[planet.string_val].process_chunks_level = process_chunks_level
        return self[planet.string_val].process_chunks_level
    end
    local function get(planet)
        -- if (type(self[planet.string_val]) ~= "table") then
        --     self[planet.string_val].process_chunks_level = increment(planet)
        -- end
        if (self ~= storage.overmind_controller) then increment(planet) end
        if (not self[planet.string_val]) then increment(planet) end
        if (not self[planet.string_val].process_chunks_level) then increment(planet) end

        -- log(serpent.block(self))
        -- log(serpent.block(planet.string_val))
        -- log(serpent.block(self[planet.string_val]))
        return self[planet.string_val].process_chunks_level
    end

    return {
        get = get,
        increment = increment,
    }
end
local chunk_levels = chunk_level()

local chunk_itrs = {}

local locals = {
    overmind_actions = nil,
    vars = {
        chunks = {
            tick_chunk_processed = {},
            tick_random_chunk_processed = {},
            tick_random_expansion_processed = {},
            tick_expansion_processed = {},
        },
        steps = steps,
        steps_table = {},
        current_step = {
            -- for each [planet.string_val]
            -- step_index = nil,
            -- step = nil,
            -- weight = 0,
            -- tick_last_ran = 0,
            -- tick_last_ran_prev = 0,
        },
        -- current_planet = nil,
        -- planets = {},
        -- planet_index = nil,
        next_planet = true,
        initialized = false,
    },
    initialize = function (data)
        data.locals.vars = {
            chunks = {
                tick_chunk_processed = {},
                tick_random_chunk_processed = {},
                tick_random_expansion_processed = {},
                tick_expansion_processed = {},
            },
            steps = steps,
            steps_table = {},
            current_step = {
                -- for each [planet.string_val]
                -- step_index = nil,
                -- step = nil,
                -- weight = 0,
                -- tick_last_ran = 0,
                -- tick_last_ran_prev = 0,
            },
            -- current_planet = nil,
            -- planets = {},
            -- planet_index = nil,
            next_planet = true,
        }

        if (storage and storage.overmind_controller and storage.overmind_controller.current_step) then
            for k, v in pairs(storage.overmind_controller.current_step) do
                data.locals.vars.current_step[k] = v
            end
        end

        for k, v in pairs(data.locals.vars.steps) do
            v.index = k
            data.locals.vars.steps_table[v.name] = k
        end

        if (not storage.ovemind_controller) then
            storage.overmind_controller = {}
            for k, v in pairs(data.locals.vars) do
                if (type(v) ~= "function") then
                    storage.overmind_controller[k] = v
                end
            end

            -- local x = 1
            storage.overmind_controller.planets = {}
            for k, v in pairs(Constants.DEFAULTS.planets) do
                -- locals.planets[v.string_val] = v
                storage.overmind_controller.planets[k] = v
                -- locals.planets[x] = v
                -- x = x + 1
            end
        end

        data.locals.vars.initialized = true

        -- data.locals.chunk_levels = locals.chunk_level()

        locals = data.locals
    end,
}

local default_weight = Constants.BIG_NUM
-- local default_weight = 2 ^ 16

local initialized = false

local overmind_controller = {}
overmind_controller.name = "overmind_controller"

-- function overmind_controller.do_tick(event)
function overmind_controller.on_tick(event)
    Log.debug("overmind_controller.on_tick")
    Log.info(event)

    if (type(event) ~= "table") then return end
    if (type(event.tick) ~= "number") then return end
    if (type(event.name) ~= "number" or event.name ~= defines.events.on_tick) then return end

    local tick = event.tick
    -- local nth_tick = Settings_Service.get_nth_tick()
    local nth_tick = 2 --[[ TODO: Make configurable ]]
    -- local offset = 1 + nth_tick -- Constants.time.TICKS_PER_SECOND / 2
    -- local offset = 0 + Constants.time.TICKS_PER_SECOND / (Constants.time.TICKS_PER_SECOND / 4)
    local offset = 0 + Constants.time.TICKS_PER_SECOND / (Constants.time.TICKS_PER_SECOND / (2 * nth_tick))
    local tick_modulo = tick % offset

    if (storage) then
        if (not storage.overmind_controller or not initialized) then
            -- Log.error("initializing 1.1")
            locals.initialize({ locals = {} })
            initialized = true
        end
    end

    local off_cycle = false
    -- if (tick_modulo >= nth_tick) then return end
    -- if (tick_modulo >= nth_tick) then off_cycle = true end
    if (tick_modulo ~= 0) then
        if (tick_modulo == nth_tick) then
            -- log("off_cycle = true");
            off_cycle = true
        -- else return
        end
    end

    -- Check/validate the storage version
    -- if (not Version_Validations.validate_version()) then return end

    local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()

    if (not more_enemies_data.valid) then more_enemies_data = Initialization.reinit() end

    -- if (storage and storage.overmind_controller and storage.overmind_controller.next_planet) then
    if (not off_cycle and storage and storage.overmind_controller and storage.overmind_controller.next_planet) then
        storage.overmind_controller.planet_index, storage.overmind_controller.current_planet = next(storage.overmind_controller.planets, storage.overmind_controller.planet_index)
    end

    if (type(storage.overmind_controller) ~= "table") then
        locals.initialize({ locals = {} })
    end

    local planet = storage and storage.overmind_controller and storage.overmind_controller.current_planet

    if (storage and storage.overmind_controller and planet) then
        -- Log.error(planet)
        -- log(serpent.block(planet))
        local _chunk = nil

        -- local _cache_data = Cache_Data:get()
        -- if (game.tick % 8 == 0) then log(serpent.block(Cache_Data:get())) end

        local overmind = Overmind_Repository.get_overmind_data(planet.string_val)

        local selected_difficulty = Constants.difficulty[Constants.difficulty.difficulties[Settings_Service.get_difficulty(planet.string_val)]]
        -- log(serpent.block(selected_difficulty))
        -- log(serpent.block(selected_difficulty.name))

        local root = 1 / selected_difficulty.value
        -- log(serpent.block(root))
        -- if (game.tick % 16 == 0) then Cache_Data:add({ key = planet.string_val .. ".root", value = (1 / selected_difficulty.value) }) end
        local evolution_factor = 0.5
        local evolution_factor_diff = 1

        if (game and game.surfaces and game.surfaces[planet.string_val] and game.surfaces[planet.string_val].valid) then
            evolution_factor = game.forces["enemy"].get_evolution_factor(game.surfaces[planet.string_val]) ^ root
            evolution_factor_diff = 1 - game.forces["enemy"].get_evolution_factor(game.surfaces[planet.string_val])
        end

        if (game and game.surfaces and game.surfaces[planet.string_val] and game.surfaces[planet.string_val].valid) then
            local surface = game.surfaces[planet.string_val]
            -- Log.error(surface.name)
            if (chunk_itrs[surface.name] == nil) then
                chunk_itrs[surface.name] = surface.get_chunks()
            end

            if (storage.overmind_controller.current_step == nil) then storage.overmind_controller.current_step = {} end

            if (storage.overmind_controller.current_step[planet.string_val] == nil) then
                storage.overmind_controller.current_step[planet.string_val] = Data:new({
                    step_index_current = nil,
                    step_current = nil,
                    step_index = nil,
                    step = nil,
                    step_data = nil
                })
            end

            local current_step = storage.overmind_controller.current_step[planet.string_val]

            current_step.step_index, current_step.step = next(storage.overmind_controller.steps, storage.overmind_controller.current_step[planet.string_val].step_index)

            -- log(planet.string_val .. " - got current_step")

            if (type(current_step.step) ~= "table") then goto continue end
            if (current_step.step == nil) then goto continue end

            -- log(planet.string_val .. " - current_step is valid")

            storage.overmind_controller.current_step[planet.string_val].step_index_current = current_step.step_index
            storage.overmind_controller.current_step[planet.string_val].step_current = current_step.step

            if (type(storage.overmind_controller.current_step[planet.string_val].step_data) ~= "table") then
                -- Log.error("storage.overmind_controller.current_step[planet.string_val].step_data ~= table")
                storage.overmind_controller.current_step[planet.string_val].step_data = {}
                for _, v in pairs(storage.overmind_controller.steps) do
                    if (not storage.overmind_controller.current_step[planet.string_val].step_data[v.index]) then
                        -- Log.error("creating step_data 1")
                        -- log(serpent.block(storage.overmind_controller.current_step[planet.string_val].step_data))
                        storage.overmind_controller.current_step[planet.string_val].step_data[v.index] = Data:new({
                            count = 0,
                            weight = default_weight,
                            tick = game.tick,
                            tick_prev = game.tick,
                            planet = planet,
                            index = v.index,
                            name = v.name,
                            type = "step_data",
                            last_call_source = nil,
                            last_call_return_code = nil,
                            cache = Data:new({}),
                        -- }, { include_meta_data = true, })
                        })
                    end
                end
            end

            -- if (type(storage.overmind_controller.current_step[planet.string_val].step_data[current_step.step_index]) ~= "table") then
            --     -- Log.error("storage.overmind_controller.current_step[planet.string_val].step_data[current_step.step_index] ~= table")
            --     storage.overmind_controller.current_step[planet.string_val].step_data[current_step.step_index] = Data:new({
            --         count = 0,
            --         weight = default_weight,
            --         tick = game.tick,
            --         tick_prev = game.tick,
            --         planet = planet,
            --         index = current_step.index,
            --         name = current_step.name,
            --         type = "step_data",
            --         last_call_source = nil,
            --         last_call_return_code = nil,
            --         cache = Data:new({}),
            --     -- }, { include_meta_data = true, })
            --     })

            --     for _, v in pairs(storage.overmind_controller.steps) do
            --         if (not storage.overmind_controller.current_step[planet.string_val].step_data[v.step_index]) then
            --             Log.error("creating step_data 2")
            --             log(serpent.block(storage.overmind_controller.current_step[planet.string_val].step_data))
            --             storage.overmind_controller.current_step[planet.string_val].step_data[v.step_index] = Data:new({
            --                 count = 0,
            --                 weight = default_weight,
            --                 tick = game.tick,
            --                 tick_prev = game.tick,
            --                 planet = planet,
            --                 index = v.index,
            --                 name = v.name,
            --                 type = "step_data",
            --                 last_call_source = nil,
            --                 last_call_return_code = nil,
            --                 cache = Data:new({}),
            --             -- }, { include_meta_data = true, })
            --             })
            --         end
            --     end
            -- end

            local step_data = storage.overmind_controller.current_step[planet.string_val].step_data[current_step.step_index]
            if (not step_data) then goto continue end

            -- step_data.tick_prev = step_data.tick
            -- step_data.tick = game.tick
            if (not off_cycle) then
                step_data.tick_prev = step_data.tick
                step_data.tick = game.tick
            end

            -- if (not step_data.tick) then step_data.tick = game.tick end
            -- local tick_diff = step_data.tick - step_data.tick_prev

            -- if (step_data.weight > 100) then step_data.weight = step_data.weight ^ 0.25 end
            if (step_data.weight >= math.huge) then
                Log.error("resetting step_data.weight to default")
                step_data.weight = default_weight
            end
            -- while step_data.weight > 100 do
            --     step_data.weight = step_data.weight ^ 0.25
            -- end
            if (not off_cycle) then
                while step_data.weight > 100 do
                    step_data.weight = step_data.weight ^ 0.25
                end
            end

            if (current_step.step == nil) then goto continue end

            local _event_data = Event_Data:get()

            local function get_overmind_actions()
                if (locals.overmind_actions ~= nil) then return locals.overmind_actions end

                locals.overmind_actions = {
                    ["process_random_attack"] = {
                        name = "process_random_attack",
                        -- index = locals.vars.steps_table["process_random_attack"],
                        index = storage.overmind_controller.steps_table["process_random_attack"],
                        func = function (data)
                            -- Log.error("process_random_attack")
                            -- log("process_random_attack")
                            if (Settings_Service.get_do_attack_group(planet.string_val)) then
                                return Attack_Group_Service.do_random_attack_group({ planet = data.planet })
                            end
                        end,
                    },
                    ["process_highest_attack"] = {
                        name = "process_highest_attack",
                        -- index = locals.vars.steps_table["process_highest_attack"],
                        index = storage.overmind_controller.steps_table["process_highest_attack"],
                        func = function (data)
                            -- Log.error("process_highest_attack")
                            -- log("process_highest_attack")
                            if (data.overmind and data.overmind.weighted_chunks and data.overmind.weighted_chunks.highest) then
                                local chunk = data.overmind.weighted_chunks.highest

                                -- log(serpent.block(chunk))
                                for k, v in pairs(data.overmind.weighted_chunks.chunks_weighted) do
                                    if (v ~= data.overmind.weighted_chunks.highest and k > math.floor(data.overmind.weighted_chunks.highest.weight)) then
                                        Constants.table.traverse_print(data.overmind.weighted_chunks, "overmind.".. data.overmind.surface_name .. ".weighted_chunks_" .. game.tick)
                                        error("highest chunk isn't highest")
                                    end
                                end

                                local i = 0
                                for k, v in pairs(data.overmind.weighted_chunks.highest) do
                                    i = i + 1
                                end

                                local _, v = next(data.overmind.weighted_chunks.highest)
                                if (i == 0 or not v) then
                                    log(serpent.block(data.overmind.weighted_chunks))
                                    error("highest chunk is empty")
                                end

                                if (table_size(data.overmind.weighted_chunks.chunks_weighted) >= 0 and table_size(data.overmind.weighted_chunks.chunks_weighted) ~= data.overmind.weighted_chunks.size) then
                                    log(table_size(data.overmind.weighted_chunks.chunks_weighted))
                                    log(data.overmind.weighted_chunks.size)
                                    log(serpent.block(data.overmind.weighted_chunks))
                                    error("counts don't match")
                                end

                                if (type(chunk.tick_attack_next) ~= "number") then chunk.tick_attack_next = game.tick end
                                if (chunk.tick_attack_next <= game.tick) then

                                    return Overmind_Service.do_highest_attack({
                                        overmind = data.overmind,
                                        chunk = chunk,
                                        selected_difficulty = data.selected_difficulty,
                                        evolution_factor = data.evolution_factor,
                                        planet = data.planet,
                                    })
                                end
                            end
                        end,
                    },
                    ["process_random_chunk"] = {
                        name = "process_random_chunk",
                        -- index = locals.vars.steps_table["process_random_chunk"],
                        index = storage.overmind_controller.steps_table["process_random_chunk"],
                        func = function (data)
                            -- Log.error("process_random_chunk")
                            -- log("process_random_chunk")
                            if (locals.vars.chunks.tick_random_chunk_processed[planet.string_val] == nil) then locals.vars.chunks.tick_random_chunk_processed[planet.string_val] = game.tick end
                            if (locals.vars.chunks.tick_random_chunk_processed[planet.string_val] and locals.vars.chunks.tick_random_chunk_processed[planet.string_val] > game.tick) then return end

                            locals.vars.chunks.tick_random_chunk_processed[planet.string_val] = game.tick + math.random(60 + (90 / selected_difficulty.radius_modifier ^ 2) * data.evolution_factor_diff, 60 + (1740 / selected_difficulty.radius_modifier ^ 2)) * data.evolution_factor_diff

                            local random_chunk = Overmind_Utils.get_new_chunk({
                                overmind = data.overmind,
                                planet = data.planet,
                                chunk = data.surface.get_random_chunk(),
                            })

                            if (type(random_chunk) ~= "table" or not random_chunk.valid) then return end

                            if (type(random_chunk.tick_next) ~= "number") then random_chunk.tick_next = game.tick end
                            if (random_chunk.tick_next < game.tick) then
                                return Overmind_Service.process_random_chunk({
                                    overmind = data.overmind,
                                    chunk = random_chunk,
                                    selected_difficulty = data.selected_difficulty,
                                    surface = data.surface,
                                    evolution_factor = data.evolution_factor
                                })
                            else
                                random_chunk.tick_next = game.tick + ((random_chunk.tick_next - game.tick) / 2) * data.evolution_factor_diff
                            end
                        end
                    },
                    ["process_expansion"] = {
                        name = "process_expansion",
                        index = storage.overmind_controller.steps_table["process_expansion"],
                        func = function (data)
                            -- Log.error("process_expansion")
                            -- log("process_expansion 1")
                            if (locals.vars.chunks.tick_expansion_processed[planet.string_val] == nil) then locals.vars.chunks.tick_expansion_processed[planet.string_val] = game.tick end
                            if (locals.vars.chunks.tick_expansion_processed[planet.string_val] and locals.vars.chunks.tick_expansion_processed[planet.string_val] > game.tick) then return end
                            -- log("process_expansion 2")

                            local evolution_factor_diff = 1 - data.evolution_factor
                            -- locals.vars.chunks.tick_expansion_processed[planet.string_val] = game.tick + math.random(60 + (90 / selected_difficulty.radius_modifier ^ 2) * data.evolution_factor_diff, 60 + (1740 / selected_difficulty.radius_modifier ^ 2)) * data.evolution_factor_diff
                            locals.vars.chunks.tick_expansion_processed[planet.string_val] = game.tick + math.random(60 + (840 / selected_difficulty.value ^ 0.5) * ((0.5 + evolution_factor_diff) / 2), 901 + (35100 / selected_difficulty.value ^ 1.25) * ((0.5 + evolution_factor_diff) / 2))

                            local random_chunk = Overmind_Utils.get_new_chunk({
                                overmind = data.overmind,
                                planet = data.planet,
                                chunk = data.surface.get_random_chunk(),
                            })
                            -- log(serpent.block(random_chunk))

                            if (type(random_chunk) ~= "table" or not random_chunk.valid) then return end

                            if (type(random_chunk.tick_next) ~= "number") then random_chunk.tick_next = game.tick end
                            if (random_chunk.tick_next <= game.tick) then
                                return Overmind_Service.do_expansion({
                                    overmind = data.overmind,
                                    chunk = random_chunk,
                                    selected_difficulty = data.selected_difficulty,
                                    surface = data.surface,
                                    evolution_factor = data.evolution_factor
                                })
                            else
                                random_chunk.tick_next = game.tick + ((random_chunk.tick_next - game.tick) / 2) * evolution_factor_diff
                            end
                        end
                    },
                    ["process_random_expansion"] = {
                        name = "process_random_expansion",
                        index = storage.overmind_controller.steps_table["process_random_expansion"],
                        func = function (data)
                            -- Log.error("process_random_chunk")
                            -- log("process_random_expansion 1")
                            if (locals.vars.chunks.tick_random_expansion_processed[planet.string_val] == nil) then locals.vars.chunks.tick_random_expansion_processed[planet.string_val] = game.tick end
                            if (locals.vars.chunks.tick_random_expansion_processed[planet.string_val] and locals.vars.chunks.tick_random_expansion_processed[planet.string_val] > game.tick) then return end
                            -- log("process_random_expansion 2")

                            -- locals.vars.chunks.tick_random_expansion_processed[planet.string_val] = game.tick + math.random(60 + (90 / selected_difficulty.radius_modifier ^ 2) * data.evolution_factor_diff, 60 + (1740 / selected_difficulty.radius_modifier ^ 2)) * data.evolution_factor_diff
                            locals.vars.chunks.tick_random_expansion_processed[planet.string_val] = game.tick + math.random(60 + (90 / selected_difficulty.value ^ 0.5) * data.evolution_factor_diff, 90 + (1710 / selected_difficulty.value ^ 1.5)) * data.evolution_factor_diff

                            local random_chunk = Overmind_Utils.get_new_chunk({
                                overmind = data.overmind,
                                planet = data.planet,
                                chunk = data.surface.get_random_chunk(),
                            })
                            -- log(serpent.block(random_chunk))

                            if (type(random_chunk) ~= "table" or not random_chunk.valid) then return end

                            if (type(random_chunk.tick_next) ~= "number") then random_chunk.tick_next = game.tick end
                            if (random_chunk.tick_next <= game.tick) then
                                return Overmind_Service.do_random_expansion({
                                    overmind = data.overmind,
                                    chunk = random_chunk,
                                    selected_difficulty = data.selected_difficulty,
                                    surface = data.surface,
                                    evolution_factor = data.evolution_factor
                                })
                            else
                                random_chunk.tick_next = game.tick + ((random_chunk.tick_next - game.tick) / 2) * data.evolution_factor_diff
                            end
                        end
                    },
                    ["process_ordered_chunk"] = {
                        name = "process_ordered_chunk",
                        -- index = locals.vars.steps_table["process_ordered_chunk"],
                        index = storage.overmind_controller.steps_table["process_ordered_chunk"],
                        func = function (data)
                            -- Log.error("process_ordered_chunk")
                            -- log("process_ordered_chunk")
                            if (locals.vars.chunks.tick_chunk_processed[planet.string_val] == nil) then locals.vars.chunks.tick_chunk_processed[planet.string_val] = game.tick end
                            if (locals.vars.chunks.tick_chunk_processed[planet.string_val] and locals.vars.chunks.tick_chunk_processed[planet.string_val] <= game.tick) then

                                locals.vars.chunks.tick_chunk_processed[planet.string_val] = game.tick + math.random(60 + 90 / ((selected_difficulty.radius_modifier ^ 0.5) * evolution_factor_diff), 90 + 810 / ((selected_difficulty.radius_modifier ^ 1.5) * evolution_factor_diff))

                                if (type(locals.vars.chunks[planet.string_val]) ~= "table") then
                                    locals.vars.chunks[planet.string_val] = {
                                        x = nil,
                                        y = nil,
                                    }
                                end

                                local chunks = locals.vars.chunks[planet.string_val]

                                return Overmind_Service.process_ordered_chunk({
                                    chunks = chunks,
                                    overmind = data.overmind,
                                    selected_difficulty = data.selected_difficulty,
                                    evolution_factor = data.evolution_factor,
                                    root = data.root,
                                })
                            end
                        end
                    },
                    ["process_staged_chunk"] = {
                        name = "process_staged_chunk",
                        -- index = locals.vars.steps_table["process_staged_chunk"],
                        index = storage.overmind_controller.steps_table["process_staged_chunk"],
                        func = function (data)
                            -- Log.error("process_staged_chunk")
                            -- log("process_staged_chunk")
                            -- log(tostring(data.overmind.surface_name))
                            return Overmind_Service.process_staged_chunk({
                                overmind = data.overmind,
                                queue = data.overmind.staged_chunks,
                                selected_difficulty = data.selected_difficulty,
                                evolution_factor = data.evolution_factor,
                            })
                        end,
                    },
                    ["process_chunks_priority_high"] = {
                        name = "process_chunks_priority_high",
                        index = storage.overmind_controller.steps_table["process_chunks_priority_high"],
                        func = function (data)
                            -- log("process_chunks_priority_high")
                            -- log(tostring(data.overmind.surface_name))
                            return Overmind_Service.process_chunk({
                                overmind = data.overmind,
                                queue = data.overmind.chunks_priority_high,
                                selected_difficulty = data.selected_difficulty,
                                evolution_factor = data.evolution_factor,
                            })
                        end
                    },
                    ["process_chunks_priority_medium"] = {
                        name = "process_chunks_priority_medium",
                        index = storage.overmind_controller.steps_table["process_chunks_priority_medium"],
                        func = function (data)
                            -- log("process_chunks_priority_medium")
                            -- log(tostring(data.overmind.surface_name))
                            return Overmind_Service.process_chunk({
                                overmind = data.overmind,
                                queue = data.overmind.chunks_priority_medium,
                                selected_difficulty = data.selected_difficulty,
                                evolution_factor = data.evolution_factor,
                            })
                        end
                    },
                    ["process_chunks_priority_low"] = {
                        name = "process_chunks_priority_low",
                        index = storage.overmind_controller.steps_table["process_chunks_priority_low"],
                        func = function (data)
                            -- log("process_chunks_priority_low")
                            -- log(tostring(data.overmind.surface_name))
                            return Overmind_Service.process_chunk({
                                overmind = data.overmind,
                                queue = data.overmind.chunks_priority_low,
                                selected_difficulty = data.selected_difficulty,
                                evolution_factor = data.evolution_factor,
                            })
                        end
                    },
                }

                for k, v in pairs(Constants.chunk_sizes) do
                    if (k < Constants.CHUNK_LEVELS) then
                        -- table.insert(locals.overmind_actions, { name = "process_chunks_" .. k, })
                        locals.overmind_actions["process_chunks_" .. k] = {
                            name = "process_chunks_" .. k,
                            index = storage.overmind_controller.steps_table["process_chunks_" .. k],
                            func = function (data)
                                -- log("process_chunks_" .. k)
                                -- log(tostring(data.overmind.surface_name))
                                local return_val = Overmind_Service.process_chunk({
                                    overmind = data.overmind,
                                    -- queue = overmind.chunks and overmind.chunks.queue,
                                    queue = data.overmind.chunks["chunks_" .. k] and data.overmind.chunks["chunks_" .. k].queue,
                                    selected_difficulty = data.selected_difficulty,
                                    evolution_factor = data.evolution_factor,
                                })
                                -- log("process_chunks_" .. k)
                                return return_val
                            end
                        }
                    end
                end

                return locals.overmind_actions
            end
            local overmind_actions = get_overmind_actions()
            if (type(overmind_actions) ~= "table") then return end

            local weight = 2
            -- local default_weight = 24

            local function do_action(data)
                -- Log.error(data)

                if (type(data) ~= "table") then return -1, nil end
                if (type(data.weight) ~= "number") then data.weight = default_weight end
                if (type(data.action) ~= "table") then return -1, data.weight end
                if (type(data.action.func) ~= "function") then return -1, data.weight end
                if (type(data.action.index) ~= "number") then return -1, data.weight end
                if (type(data.threshold) ~= "number") then return -1, data.weight end
                if (type(data.planet) ~= "table") then return -1, data.weight end
                if (type(data.evolution_factor) ~= "number") then data.evolution_factor = 0.5 end
                -- if (type(data.evolution_factor_diff) ~= "number") then data.evolution_factor_diff = 1 end
                if (type(data.overmind) ~= "table") then return -1, data.weight end
                if (type(data.selected_difficulty) ~= "table") then return -1, data.weight end
                if (type(data.surface) ~= "userdata") then return -1, data.weight end
                -- if (type(data.weight) ~= "number") then return return_code, nil end
                -- if (type(data.num_actions_performed) ~= "number") then return return_code, nil end

                local return_code = -1

                -- (((atan((x-2^(11 -(1 + 1/(1 +2.75*4))))/2^(11 - (1 + 1/(1 +2.75*4))))) + pi/2)/pi)^(1/(x/2^(11  - (1 + 1/(1+2.75*4))))), x=0 to 2^12
                -- log(serpent.block(data.step_data[data.action.index]))

                local action_threshold = 0

                if (data.step_data and (not data.step_data[data.action.index] or not data.step_data[data.action.index].action_threshold)) then
                    Log.error("action_threshold didn't exist")
                    -- action_threshold = (evolution_factor ^ (1 / (1 + selected_difficulty.value))) * (((math.atan((data.step_data[data.action.index].count - 2 ^ (Insanity_Difficulty_Data.value - (1 + 1 / (1 + selected_difficulty.value)))) / 2 ^ (Insanity_Difficulty_Data.value - (1 + 1 / (1 + selected_difficulty.value))))) + math.pi / 2) / math.pi) ^ (1 / (data.step_data[data.action.index].count / 2 ^ (11 - (1 + 1 / (1 + selected_difficulty.value)))))
                    action_threshold = 1
                    if (not data.step_data[data.action.index]) then data.step_data[data.action.index] = {} end
                    data.step_data[data.action.index].action_threshold = action_threshold

                    -- data.step_data[data.action.index].count = 2 ^ 16
                else
                    local _step_data = data.step_data[data.action.index]
                    if (    _step_data ~= nil
                        and type(_step_data) == "table"
                        and _step_data.tick
                        and game.tick
                        and (
                               _step_data.tick_prev and _step_data.tick - _step_data.tick_prev >= 60
                            or _step_data.tick and game.tick - _step_data.tick >= 60
                            or _step_data.updated and game.tick - _step_data.updated >= 60
                            -- or _step_data.cache.updated and game.tick - _step_data.cache.updated >= 60
                        )
                    ) then
                        -- log("recalculating action_threshold")
                        -- log("(cached) action_threshold = " .. _step_data.action_threshold)
                        -- action_threshold = (evolution_factor ^ (1 / (1 + selected_difficulty.value))) * (((math.atan((data.step_data[data.action.index].count - 2 ^ (Insanity_Difficulty_Data.value - (1 + 1 / (1 + selected_difficulty.value)))) / 2 ^ (Insanity_Difficulty_Data.value - (1 + 1 / (1 + selected_difficulty.value))))) + math.pi / 2) / math.pi) ^ (1 / (data.step_data[data.action.index].count / 2 ^ (11 - (1 + 1 / (1 + selected_difficulty.value)))))
                        action_threshold = 1
                        -- log("(calc'd) action_threshold = " .. action_threshold)
                        _step_data.action_threshold = action_threshold
                        -- _step_data.cache.updated = game.tick
                    else
                        -- log("using cached action_threshold")
                        action_threshold = type(_step_data) == "table" and _step_data.action_threshold or evolution_factor or 0.5
                    end

                    if (_step_data ~= nil) then
                        _step_data.updated = game.tick
                        _step_data.tick = game.tick
                    else
                        return return_code, data.weight
                    end
                end

                -- log("action_threshold = " .. action_threshold)
                local rand = math.random()
                -- log("rand = " .. rand)
                -- log(serpent.line(data.weight))

                if (not data.step_data[data.action.index].count) then data.step_data[data.action.index].count = 0 end
                data.step_data[data.action.index].count = data.step_data[data.action.index].count + 1

                if (rand <= action_threshold) then
                    -- log("action_threshold = " .. action_threshold)
                    -- log("rand = " .. rand)
                    if (data.tick and data.mod and data.modulo) then
                        if (data.tick % data.mod == data.modulo) then
                            -- Log.error(game.tick)
                            if (data.action) then
                                -- if (game.tick % 512 == 0) then log("step random: " .. data.action.name .. " - " .. data.weight) end
                                --[[ 64 + 32 + rand(2, 256) ]]
                                -- if (data.weight < 100) then
                                if (data.weight < 2 ^ 6 + 2 ^ 5 + math.random(2 ^ math.random(5), 2 ^ math.random(5, 8))) then
                                    -- data.step_data[data.action.index].count = data.step_data[data.action.index].count + 1
                                    -- local step_weight = Event_Data:get().deviation_average_1 + 1 + selected_difficulty.radius_modifier + data.step_data[data.action.index].weight ^ (1.05 + math.random() / 5)
                                    -- local step_weight = (Event_Data:get().deviation_average_1 + Event_Data:get().deviation_average) / 2 + 1 + selected_difficulty.radius_modifier + data.step_data[data.action.index].weight * (1.05 + math.random() / 2)
                                    -- local step_weight = ((_event_data.deviation_average_1 + _event_data.deviation_average) / 2) + 1 + selected_difficulty.radius_modifier + data.step_data[data.action.index].weight * (1.05 + math.random() / 2)
                                    local step_weight = ((_event_data.deviation_average_1 + _event_data.deviation_average) / 2) + 1 + selected_difficulty.radius_modifier / 1.5 + data.step_data[data.action.index].weight * (1.05 + math.random() / 4)
                                    step_weight = step_weight / data.step_data[data.action.index].count
                                    -- log("step_weight = " .. step_weight)
                                    -- log("just before data.action.func()")
                                    if (    step_weight < data.threshold
                                        and data.action.func({
                                            overmind = data.overmind,
                                            selected_difficulty = data.selected_difficulty,
                                            planet = data.planet,
                                            surface = data.surface,
                                            evolution_factor = data.evolution_factor,
                                            root = 1 / selected_difficulty.value,
                                            evolution_factor_diff = 1 - data.evolution_factor,
                                        })
                                    ) then
                                        -- log("data.action.func() called")
                                        -- data.step_data[data.action.index].weight = Event_Data:get().deviation_average_1 + 1 + selected_difficulty.radius_modifier + data.step_data[data.action.index].weight ^ (1.05 + math.random() / 5)
                                        data.step_data[data.action.index].weight = step_weight

                                        return_code = 1
                                    else
                                        -- data.weight = data.weight ^ (1.05 + math.random() / 5)
                                        -- data.step_data[data.action.index].weight = Event_Data:get().deviation_average_1 + 1 + selected_difficulty.value + data.step_data[data.action.index].weight ^ (1.05 + math.random() / 3)
                                        data.step_data[data.action.index].weight = _event_data.deviation_average_1 + 1 + selected_difficulty.value / 1.5 + data.step_data[data.action.index].weight ^ (1.1 - math.random() / 3)

                                        return_code = 0
                                    end
                                end
                            end
                        end
                    else
                        if (data.action and data.source) then
                            if (data.source == "specific") then
                                -- if (game.tick % 512 == 0) then log("step specific: " .. data.action.name .. " - " .. data.weight) end

                                if (data.weight < 100) then
                                    -- data.step_data[data.action.index].count = data.step_data[data.action.index].count + 1
                                    -- local step_weight = (Event_Data:get().deviation_average_1 + Event_Data:get().deviation_average) / 2 + 1 + selected_difficulty.radius_modifier + data.step_data[data.action.index].weight ^ (1.05 + math.random() / 5)
                                    -- local step_weight = (Event_Data:get().deviation_average_1 + Event_Data:get().deviation_average) / 2 + 1 + selected_difficulty.radius_modifier + data.step_data[data.action.index].weight * (1.05 + math.random() / 2)
                                    local step_weight = ((_event_data.deviation_average_1 + _event_data.deviation_average) / 2) + 1 + selected_difficulty.radius_modifier / 1.5 + data.step_data[data.action.index].weight * (1.05 + math.random() / 4)
                                    -- log("step_weight = " .. step_weight)
                                    -- log("just before data.action.func()")
                                    if (    step_weight < data.threshold
                                        and data.action.func({
                                            overmind = data.overmind,
                                            selected_difficulty = data.selected_difficulty,
                                            planet = data.planet,
                                            surface = data.surface,
                                            evolution_factor = data.evolution_factor,
                                            root = 1 / selected_difficulty.value,
                                            evolution_factor_diff = 1 - data.evolution_factor,
                                        })
                                    ) then
                                        -- local step_weight = data.step_data[data.action.index] and data.step_data[data.action.index].weight or default_weight
                                        -- data.weight = data.weight + step_weight
                                        -- data.step_data[data.action.index].weight = Event_Data:get().deviation_average_1 + 1 + selected_difficulty.radius_modifier + data.step_data[data.action.index].weight ^ (1.05 + math.random() / 5)
                                        data.step_data[data.action.index].weight = step_weight

                                        return_code = 1
                                    else
                                        -- data.step_data[data.action.index].weight = Event_Data:get().deviation_average_1 + 1 + selected_difficulty.value + data.step_data[data.action.index].weight ^ (1.05 + math.random() / 3)
                                        -- data.step_data[data.action.index].weight = _event_data.deviation_average_1 + 1 + selected_difficulty.value + data.step_data[data.action.index].weight ^ (1.05 + math.random() / 3)
                                        data.step_data[data.action.index].weight = _event_data.deviation_average_1 + 1 + selected_difficulty.value / 1.5 + data.step_data[data.action.index].weight ^ (1.1 - math.random() / 3)

                                        return_code = 0
                                    end
                                else
                                    -- log("data.weight: " .. data.weight .. " > 100")
                                end
                            elseif (data.source == "indexed") then
                                -- if (game.tick % 512 == 0) then log("step indexed: " .. data.action.name .. " - " .. data.weight) end

                                -- if (data.weight < 100) then
                                if (data.weight < 100 or off_cycle and data.weight < Constants.e * 100) then
                                    -- data.step_data[data.action.index].count = data.step_data[data.action.index].count + 1
                                    -- local step_weight = (Event_Data:get().deviation_average_1 + Event_Data:get().deviation_average) / 2 + 1 + selected_difficulty.radius_modifier + data.step_data[data.action.index].weight ^ (1.05 + math.random() / 5)
                                    -- local step_weight = (Event_Data:get().deviation_average_1 + Event_Data:get().deviation_average) / 2 + 1 + selected_difficulty.radius_modifier + data.step_data[data.action.index].weight * (1.05 + math.random() / 2)
                                    -- local step_weight = (_event_data.deviation_average_1 + _event_data.deviation_average) / 2 + 1 + selected_difficulty.radius_modifier + data.step_data[data.action.index].weight * (1.05 + math.random() / 2)
                                    local step_weight = ((_event_data.deviation_average_1 + _event_data.deviation_average) / 2) + 1 + selected_difficulty.radius_modifier / 1.5 + data.step_data[data.action.index].weight * (1.05 + math.random() / 4)
                                    -- log("step_weight = " .. step_weight)
                                    -- log("just before data.action.func()")
                                    -- if (    step_weight < data.threshold
                                    if ((       step_weight < data.threshold
                                             or off_cycle
                                            and step_weight < Constants.e * data.threshold)
                                        and data.action.func({
                                            overmind = data.overmind,
                                            selected_difficulty = data.selected_difficulty,
                                            planet = data.planet,
                                            surface = data.surface,
                                            evolution_factor = data.evolution_factor,
                                            root = 1 / selected_difficulty.value,
                                            evolution_factor_diff = 1 - data.evolution_factor,
                                        })
                                    ) then
                                        -- local step_weight = data.step_data[data.action.index] and data.step_data[data.action.index].weight or default_weight
                                        -- data.weight = data.weight + step_weight
                                        -- data.step_data[data.action.index].weight = Event_Data:get().deviation_average_1 + 1 + selected_difficulty.radius_modifier + data.step_data[data.action.index].weight ^ (1.05 + math.random() / 5)
                                        data.step_data[data.action.index].weight = step_weight

                                        return_code = 1
                                    else
                                        -- data.weight = data.weight ^ (1.05 + math.random() / 2)
                                        -- data.step_data[data.action.index].weight = Event_Data:get().deviation_average_1 + 1 + selected_difficulty.value + data.step_data[data.action.index].weight ^ (1.05 + math.random() / 3)
                                        -- data.step_data[data.action.index].weight = _event_data.deviation_average_1 + 1 + selected_difficulty.value + data.step_data[data.action.index].weight ^ (1.05 + math.random() / 3)
                                        data.step_data[data.action.index].weight = _event_data.deviation_average_1 + 1 + selected_difficulty.value / 1.5 + data.step_data[data.action.index].weight ^ (1.1 - math.random() / 3)

                                        return_code = 0
                                    end
                                end

                                -- current_step.step_index, current_step.step = next(storage.overmind_controller.steps, storage.overmind_controller.current_step[planet.string_val].step_index)

                                -- if (type(current_step.step) ~= "table" or current_step.step == nil) then
                                --     -- Log.error("getting next step")
                                --     current_step.step_index, current_step.step = next(storage.overmind_controller.steps, storage.overmind_controller.current_step[planet.string_val].step_index)
                                -- end

                                if (data.action.name:find("process_chunks_", 1, true)) then
                                    -- locals.chunk_levels.increment(planet)
                                    chunk_levels.increment(planet)
                                    -- local asdf = chunk_levels.increment(planet)
                                    -- log(planet.string_val .. " - incrementing chunk level: " .. asdf)
                                else
                                    -- log("incrementing step")
                                    current_step.step_index, current_step.step = next(storage.overmind_controller.steps, storage.overmind_controller.current_step[planet.string_val].step_index)

                                    if (type(current_step.step) ~= "table" or current_step.step == nil) then
                                        -- Log.error("getting next step")
                                        -- current_step.step_index, current_step.step = next(storage.overmind_controller.steps, storage.overmind_controller.current_step[planet.string_val].step_index)
                                        current_step.step_index, current_step.step = next(storage.overmind_controller.steps, nil)
                                    end
                                end
                            end
                        end
                    end
                else
                    return_code = 0
                end

                -- if (game.tick % 6 == 0) then log(data.weight) end

                if (return_code >= 0) then
                    -- if (game.tick % 512 == 0) then log(data.weight) end
                    -- data.weight = data.weight + data.step_data[data.action.index].weight * (1 + (1 / (1 + (data.step_data[data.action.index].count ^ (1 / (1 + selected_difficulty.value))))))
                    -- data.weight = data.weight + data.step_data[data.action.index].weight * ((2 - (evolution_factor + math.random()) / 2) + (1 / (1 + (data.step_data[data.action.index].count ^ (1 / (1 + selected_difficulty.value))))))
                    -- TODO: Incorporate step action count into the calculation again                    
                    -- log(data.weight)
                    -- log(data.step_data[data.action.index].weight)
                    -- data.weight = data.weight + data.step_data[data.action.index].weight * (((((Insanity_Difficulty_Data.value / (selected_difficulty.value + 1)) ^ (2 - selected_difficulty.radius_modifier)) - ((evolution_factor ^ 0.5 + math.random() ^ 0.5) ^ 2) / 2) ^ 2) ^ 0.5) * (1 + (1 / (1 + (data.step_data[data.action.index].count ^ (1 / (1 + selected_difficulty.value))))))
                    data.weight = data.weight + data.step_data[data.action.index].weight * (((1 - (1.0/(math.pi/2)) * (math.atan((1/0.1) * (evolution_factor ^ 2)))) + (math.random() ^ (1 / (1 + selected_difficulty.value / 6)))) / 2)
                    data.step_data[data.action.index].tick_prev = data.step_data[data.action.index].tick
                    data.step_data[data.action.index].tick = game.tick

                    -- if (game.tick % 512 == 0) then log(data.weight) end
                    -- log(data.weight)
                    data.weight = data.weight ^ 0.99
                    -- log(data.weight)
                end
                data.step_data[data.action.index].updated = game.tick
                data.step_data[data.action.index].last_call_source = data.source
                data.step_data[data.action.index].last_call_return_code = return_code

                -- if (game.tick % 512 == 0) then log(data.source) end
                -- log(data.source)
                -- log("return_code " .. return_code)
                -- log("data.weight " .. data.weight)


                -- log(serpent.block(data.step_data[data.action.index].weight))
                local modifier = (100 - (selected_difficulty.value / 5)) / 100
                -- log(modifier)

                if (not data.step_data[data.action.index].weight) then data.step_data[data.action.index].weight = 100 end
                data.step_data[data.action.index].weight = data.step_data[data.action.index].weight ^ modifier
                -- log(serpent.block(data.step_data[data.action.index].weight))

                if (return_code < 0) then
                    -- log(serpent.block(data))
                    -- log(serpent.block(data.source))
                    -- log(serpent.block(data.weight))
                    -- log(serpent.block(data.action))
                    -- log(serpent.block(data.threshold))
                    -- log(serpent.block(storage.overmind_controller.current_step[planet.string_val]))
                    -- log(serpent.block(storage.overmind_controller.current_step[planet.string_val].step_data[data.action.index]))
                    -- log(serpent.block(data.step_data[data.action.index]))

                    data.step_data[data.action.index].weight = data.step_data[data.action.index].weight ^ ((1 + modifier ^ 3) / 2)
                    -- log(serpent.block(data.step_data[data.action.index].weight))
                end
                -- data.step_data[data.action.index].weight = data.step_data[data.action.index].weight ^ 0.99

                return return_code, data.weight
            end

            -- local _event_data = Event_Data:get()
            -- log(serpent.block(_event_data))
            -- log(serpent.line(_event_data))
            local event_modifier = 1
            if (_event_data.deviation_average_1 > _event_data.deviation_average_2 and _event_data.deviation_average_2 > _event_data.deviation_average_3) then
                -- Num events going up
                -- -> Reduce threshold
                -- if (game.tick % 2 == 0) then
                --     log("going up")
                -- end
                event_modifier = Cache_Data:get_by_key({
                -- event_modifier = cache_data:get_by_key({
                    key = "overmind_controller..on_tick.." .. planet.string_val .. "..event_modifier",
                    fallback = function ()
                        -- local value = 1 / (1 + selected_difficulty.value)
                        local value = (1 / ((Constants.e + (selected_difficulty.value ^ 0.75)) ^ 1.5))
                        return {
                            key = "overmind_controller..on_tick.." .. planet.string_val .. "..event_modifier",
                            value = value,
                            -- value = 2 / 3,
                            tick_valid_until = game.tick + 4 * (2 ^ ((math.random(3) + math.random(3))/2)),
                        }
                    end
                }) or event_modifier
            -- elseif (_event_data.deviation_average_1 < _event_data.deviation_average_2 and _event_data.deviation_average_2 <= _event_data.deviation_average_3) then
            elseif (_event_data.deviation_average_1 <= _event_data.deviation_average_2 and _event_data.deviation_average_2 <= _event_data.deviation_average_3) then
                -- Num events going down
                -- -> Increase theshold
                -- if (game.tick % 2 == 0) then
                --     log("going down")
                -- end
                event_modifier = Cache_Data:get_by_key({
                -- event_modifier = cache_data:get_by_key({
                    key = "overmind_controller..on_tick.." .. planet.string_val .. "..event_modifier",
                    fallback = function ()
                        return {
                            key = "overmind_controller..on_tick.." .. planet.string_val .. "..event_modifier",
                            -- value = 1.00025,
                            value = 1.00125,
                            tick_valid_until = game.tick + 4 * (2 ^ math.random(2)),
                        }
                    end
                }) or event_modifier
            end

            -- TODO: Make these configurable settings
            -- local threshold_max = 100 * selected_difficulty.value
            -- local threshold = 100 * selected_difficulty.value
            -- local threshold_max = 10 * (2 ^ math.floor(selected_difficulty.value))
            -- local threshold_max = 10 * (selected_difficulty.value ^ 2.5)
            local threshold_max = (2 ^ 6) + (2 ^ 6) * selected_difficulty.value

            if (more_enemies_data.overmind[planet.string_val].threshold == nil
                or type(more_enemies_data.overmind[planet.string_val].threshold) ~= "number"
                or more_enemies_data.overmind[planet.string_val].threshold < 1)
            then
                -- more_enemies_data.overmind[planet.string_val].threshold = 10 * selected_difficulty.value
                more_enemies_data.overmind[planet.string_val].threshold = 32 + selected_difficulty.value * 1.5
            end

            -- log("threshold = " .. more_enemies_data.overmind[planet.string_val].threshold)

            -- local threshold = 10 * selected_difficulty.value
            -- threshold = Cache_Data:get_by_key({
            more_enemies_data.overmind[planet.string_val].threshold, Asdf = Cache_Data:get_by_key({
            -- more_enemies_data.overmind[planet.string_val].threshold = cache_data:get_by_key({
                key = "overmind_controller..on_tick.." .. planet.string_val .. "..threshold",
                fallback = function ()
                    event_modifier = event_modifier or 1

                    -- log("threshold = " .. more_enemies_data.overmind[planet.string_val].threshold)

                    -- local value = 1 + more_enemies_data.overmind[planet.string_val].threshold * event_modifier + selected_difficulty.value
                    local value = 16 + 2 * selected_difficulty.value + more_enemies_data.overmind[planet.string_val].threshold * event_modifier

                    return {
                        key = "overmind_controller..on_tick.." .. planet.string_val .. "..threshold",
                        value = value,
                        tick_valid_until = game.tick + 4 * (2 ^ math.random(3)),
                        -- tick_valid_until = game.tick + 4 * (2 ^ math.random(2 + Insanity_Difficulty_Data.value - selected_difficulty.value)),
                    }
                end
            }) or 0

            -- log(serpent.block(Asdf))
            -- log("threshold = " .. more_enemies_data.overmind[planet.string_val].threshold)

            more_enemies_data.overmind[planet.string_val].threshold = selected_difficulty.radius_modifier / 2 + more_enemies_data.overmind[planet.string_val].threshold
            if (more_enemies_data.overmind[planet.string_val].threshold > threshold_max) then more_enemies_data.overmind[planet.string_val].threshold = threshold_max end
            -- local threshold = more_enemies_data.overmind[planet.string_val].threshold
            -- local threshold = 32 + more_enemies_data.overmind[planet.string_val].threshold
            local threshold = more_enemies_data.overmind[planet.string_val].threshold

            -- log("_event_data.deviation_average = " .. _event_data.deviation_average)
            -- log("event_modifier = " .. event_modifier)
            -- log("planet " .. planet.string_val .. " threshold = " .. threshold)

            -- local max_cycles = Settings_Service.get_max_overmind_cycles_per_tick(planet.string_val)
            local max_cycles = 8 --[[TODO: Make configurable]]
            local num_cycles = 0

            -- if (storage.num_actions_performed == nil) then storage.num_actions_performed = 0 end
            local return_code = 0

            --[[TODO: Make configurable]]
            -- local aggression = selected_difficulty.value * (math.log(math.exp(1), evolution_factor + 1))
            -- local aggression = selected_difficulty.value * (math.log(Constants.e, evolution_factor + 1))
            local aggression = selected_difficulty.value * math.log((10 - 10 * Constants.e ^ (-(evolution_factor ^ 2)) + 1), math.exp(1))

            local function should_break(data)
                -- Log.debug("should_break")
                -- Log.info(data)
                local should_break = true

                -- log("weight = " .. data.weight .. " | threshold = " .. data.threshold)

                if (type(data) ~= "table") then return should_break end
                if (type(data.return_code) ~= "number") then return should_break end
                if (type(data.weight) ~= "number") then return should_break end
                if (type(data.threshold) ~= "number") then return should_break end

                -- if (data.return_code > 0) then storage.num_actions_performed = storage.num_actions_performed + data.return_code end
                if (data.return_code >= 0) then storage.num_actions_performed = storage.num_actions_performed + 1 end
                if (data.weight > data.threshold) then return should_break end

                -- TODO: Implement this
                -- if (storage.num_actions_performed > Settings_Service.get_action_threshold(overmind.surface_name)) then
                if (storage.num_actions_performed > 2 ^ 6) then
                    log("too many actions")
                    log(storage.num_actions_performed)
                    return should_break
                end

                should_break = false
                return should_break
            end

            local function do_rand_actions(data)

                if (type(data) ~= "table") then return -1, 0 end
                -- if (type(data.weight) ~= "number") then return -1, 0 end
                if (type(data.weight) ~= "number") then data.weight = default_weight end
                if (off_cycle) then return -1, data.weight end
                if (type(data.threshold) ~= "number") then return -1, data.weight end
                if (type(data.tick) ~= "number") then return -1, data.weight end
                if (type(data.rand_threshold) ~= "number") then return -1, data.weight end
                if (type(data.step_data) ~= "table") then return -1, data.weight end
                if (type(data.evolution_factor) ~= "number") then data.evolution_factor = 0.5 end
                -- if (type(data.evolution_factor_diff) ~= "number") then data.evolution_factor_diff = 1 end
                if (type(data.overmind) ~= "table") then return -1, data.weight end
                if (type(data.selected_difficulty) ~= "table") then return -1, data.weight end
                if (type(data.surface) ~= "userdata") then return -1, data.weight end

                -- local _return_code = 0
                local return_code = 0
                local weight = data.weight

                if (math.random() < (data.rand_threshold ^ (1 / aggression))) then
                    -- if (math.random() < math.random()) then
                    if (math.random() < (Constants.SMALL_NUM + math.random() ^ ( 1 - (data.selected_difficulty.value) / (Insanity_Difficulty_Data.value + data.selected_difficulty.value)))) then
                        local mod = 2 + math.floor(Constants.difficulty.INSANITY.value - data.selected_difficulty.value)
                        -- local mod = 2 + math.floor((Constants.difficulty.INSANITY.value - selected_difficulty.value) / 2)
                        mod = mod ^ math.random(math.ceil(1 + Constants.difficulty.INSANITY.value - data.selected_difficulty.value))
                        mod = math.ceil(mod)
                        if (mod % 2 == 1) then mod = mod - 1 end
                        -- local modulo = math.random(mod - 1)
                        local modulo = math.random(mod)

                        if (game.tick % 4 == 0) then
                            return_code, weight = do_action({ tick = data.tick, mod = mod, modulo = modulo, threshold = data.threshold, action = overmind_actions.process_highest_attack, weight = data.weight, step_data = data.step_data, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                        elseif (game.tick % 4 == 2) then
                            return_code, weight = do_action({ tick = data.tick, mod = mod, modulo = modulo, threshold = data.threshold, action = overmind_actions.process_random_expansion, weight = data.weight, step_data = data.step_data, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                        end
                        if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then return -1, data.weight end

                        mod = 2 + math.floor(Constants.difficulty.INSANITY.value - data.selected_difficulty.value)
                        -- mod = 2 + math.floor((Constants.difficulty.INSANITY.value - selected_difficulty.value) / 2)
                        mod = mod ^ math.random(math.ceil(1 + Constants.difficulty.INSANITY.value - data.selected_difficulty.value))
                        mod = math.ceil(mod)
                        if (mod % 2 == 1) then mod = mod - 1 end
                        -- modulo = math.random(mod - 1)
                        modulo = math.random(mod)

                        return_code, weight = do_action({ tick = data.tick, mod = mod, modulo = modulo, threshold = data.threshold, action = overmind_actions.process_random_attack, weight = data.weight, step_data = data.step_data, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                        if (should_break({ return_code = return_code, weight = weight, threshold = data.threshold })) then return -1, data.weight end

                        mod = 2 + math.floor(Constants.difficulty.INSANITY.value - selected_difficulty.value)
                        -- mod = 2 + math.floor((Constants.difficulty.INSANITY.value - data.selected_difficulty.value) / 2)
                        mod = mod ^ math.random(math.ceil(1 + Constants.difficulty.INSANITY.value - data.selected_difficulty.value))
                        mod = math.ceil(mod)
                        if (mod % 2 == 1) then mod = mod - 1 end
                        -- modulo = math.random(mod - 1)
                        modulo = math.random(mod)

                        return_code, weight = do_action({ tick = data.tick, mod = mod, modulo = modulo, threshold = data.threshold, action = overmind_actions.process_random_chunk, weight = data.weight, step_data = data.step_data, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                        if (should_break({ return_code = return_code, weight = weight, threshold = data.threshold })) then return -1, data.weight end
                    end
                end

                -- _return_code = 1
                -- log("_return_code " .. _return_code)
                -- log("data.weight " .. data.weight)

                -- return _return_code, data.weight
                return return_code, data.weight
            end

            local count = 0

            -- local chunk_level = locals.chunk_levels
            local chunk_level = chunk_levels
            -- local process_chunks_level = locals.chunk_levels.get(planet)
            local process_chunks_level = chunk_levels.get(planet)


            if (cache and cache[defines.events.on_biter_base_built] and next(cache[defines.events.on_biter_base_built])) then
                -- for k, v in pairs(cache[defines.events.on_biter_base_built]) do
                --     log("tick " .. tostring(k))
                --     for x, y_t in pairs(v) do
                --         for y, t in pairs(y_t) do
                --             -- Overmind_Service.on_biter_base_built(event)
                --             Overmind_Service.on_biter_base_built({
                --                 tick = k,
                --                 name = defines.events.on_biter_base_built,

                --             })

                --         end
                --     end
                -- end
            end



            -- while weight < threshold - deviation_average_1 and num_cycles < max_cycles do
            -- while weight < threshold - Event_Data:get():get_deviation_average() and num_cycles < max_cycles do
            -- while weight < threshold - Event_Data:get_deviation_average() and num_cycles < max_cycles do
            -- log(serpent.block(weight))
            while weight < (threshold - Event_Data:get_deviation_average()) * (1 - num_cycles / max_cycles) and num_cycles < max_cycles do
            -- while weight < threshold - Event_Data.get(Event_Data).get_deviation_average(Event_Data) and num_cycles < max_cycles do
                -- log(serpent.block(current_step))
                local step_data = current_step.step_data
                local function get_clamped_actions_count()
                    if (storage.num_actions_performed == nil or storage.num_actions_performed == 0) then return 0 end
                    -- return math.floor(storage.num_actions_performed and 1 or storage.num_actions_performed < 0 and 1 or storage.num_actions_performed > 15 and 15 or storage.num_actions_performed / (num_cycles + 1))
                    return math.floor(type(storage.num_actions_performed) ~= "number" and 1 or storage.num_actions_performed < 0 and 1 or storage.num_actions_performed > 16 and 16 or storage.num_actions_performed / (num_cycles))
                end

                count = get_clamped_actions_count()
                -- log(storage.num_actions_performed .. " : " .. tostring(Event_Data:get()[count + 1 ].name) .. " : " .. Event_Data:get_deviation({ count = count}))
                Event_Data:get_deviation({ count = count })
                -- threshold = threshold_max - Event_Data:get().deviation_average_1
                -- threshold = threshold - Event_Data:get().deviation_average_1
                threshold = threshold - _event_data.deviation_average_1

                if (off_cycle and (tick + num_cycles) % 2 == 0) then
                    -- log("(off_cycle and (tick + num_cycles) % 2 == 0)")
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_1"], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (off_cycle and (tick + num_cycles) % 2 == 1) then
                    -- log("(off_cycle and (tick + num_cycles) % 2 == 1)")
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_1"], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                end

                if (off_cycle and (tick + num_cycles) % 3 == 0) then
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_1"], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (off_cycle and (tick + num_cycles) % 3 == 1) then
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_1"], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (off_cycle and (tick + num_cycles) % 3 == 2) then
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_1"], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                end

                -- Log.error(tick)
                -- Log.error(num_cycles)
                if (not off_cycle and (tick + num_cycles) % 2 == 0) then
                    -- return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_expansion, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    -- if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_1"], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions[current_step.step.name], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    if (math.random() + 0.25 < math.random()) then
                        return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_medium, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                        if (weight > threshold) then break end
                    end
                elseif (not off_cycle and (tick + num_cycles) % 2 == 1) then
                    -- return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_2, weight = weight, step_data = step_data })
                    -- if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    -- return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. process_chunks_level], weight = weight, step_data = step_data, planet = planet })
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_1"], weight = weight, step_data = step_data, planet = planet })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions[current_step.step.name], weight = weight, step_data = step_data, planet = planet })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    if (math.random() + 0.25 < math.random()) then
                        return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_medium, weight = weight, step_data = step_data, planet = planet })
                        if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    end
                    -- return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks, weight = weight, step_data = step_data })
                    -- if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                end

                count = get_clamped_actions_count()
                -- log(storage.num_actions_performed .. " : " .. tostring(Event_Data:get()[count + 1 ].name) .. " : " .. Event_Data:get_deviation({ count = count}))
                Event_Data:get_deviation({ count = count})
                -- threshold = threshold - Event_Data:get().deviation_average_1
                threshold = threshold - _event_data.deviation_average_1

                if (not off_cycle and (tick + num_cycles) % 3 == 0) then
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_2"], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions[current_step.step.name], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 3 == 1) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_expansion, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_medium, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 3 == 2) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_expansion, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_low, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions[current_step.step.name], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                end

                local probability_modifier = Settings_Service.get_spawn_attack_group_probability_modifier(overmind.surface_name)
                -- Maximum probability of an attack group spawning at 100% (1) evolution factor
                local max_probability = 1 - (1 / (selected_difficulty.value ^ root))

                if (max_probability < 0) then max_probability = 0 end
                max_probability = max_probability * probability_modifier
                local rand_threshold = max_probability * evolution_factor

                return_code, weight = do_rand_actions({ tick = tick + num_cycles, rand_threshold = rand_threshold, threshold = threshold, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                if (return_code < 0) then break end

                count = get_clamped_actions_count()
                -- log(storage.num_actions_performed .. " : " .. tostring(Event_Data:get()[count + 1 ].name) .. " : " .. Event_Data:get_deviation({ count = count}))
                Event_Data:get_deviation({ count = count})
                -- threshold = threshold - Event_Data:get().deviation_average_1
                threshold = threshold - _event_data.deviation_average_1

                if (not off_cycle and (tick + num_cycles) % 4 == 0) then
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_3"], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions[current_step.step.name], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 4 == 1) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_medium, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 4 == 2) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_medium, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 4 == 3) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_staged_chunk, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                end

                count = get_clamped_actions_count()
                Event_Data:get_deviation({ count = count})
                -- threshold = threshold - Event_Data:get().deviation_average_1
                threshold = threshold - _event_data.deviation_average_1

                if (not off_cycle and (tick + num_cycles) % 5 == 0) then
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_4"], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions[current_step.step.name], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 5 == 1) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_medium, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 5 == 2) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_staged_chunk, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions[current_step.step.name], weight = weight, step_data = step_data, planet = planet })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 5 == 3) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions[current_step.step.name], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 5 == 4) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_low, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                end

                return_code, weight = do_rand_actions({ tick = tick + num_cycles, rand_threshold = rand_threshold, threshold = threshold, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                if (return_code < 0) then break end

                count = get_clamped_actions_count()
                -- log(storage.num_actions_performed .. " : " .. tostring(Event_Data:get()[count + 1 ].name) .. " : " .. Event_Data:get_deviation({ count = count}))
                Event_Data:get_deviation({ count = count})
                -- threshold = threshold - Event_Data:get().deviation_average_1
                threshold = threshold - _event_data.deviation_average_1

                if (not off_cycle and (tick + num_cycles) % 6 == 0) then
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_5"], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_low, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions[current_step.step.name], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 6 == 1) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_medium, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 6 == 2) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_low, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_staged_chunk, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 6 == 3) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions[current_step.step.name], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 6 == 4) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions[current_step.step.name], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 6 == 5) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_low, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                end

                count = get_clamped_actions_count()
                -- log(storage.num_actions_performed .. " : " .. tostring(Event_Data:get()[count + 1 ].name) .. " : " .. Event_Data:get_deviation({ count = count}))
                Event_Data:get_deviation({ count = count})
                -- threshold = threshold - Event_Data:get().deviation_average_1
                threshold = threshold - _event_data.deviation_average_1

                if (not off_cycle and (tick + num_cycles) % 7 == 0) then
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_6"], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_staged_chunk, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions[current_step.step.name], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 7 == 1) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_medium, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 7 == 2) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions[current_step.step.name], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_staged_chunk, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 7 == 3) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 7 == 4) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_staged_chunk, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 7 == 5) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions[current_step.step.name], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 7 == 6) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_low, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                end

                count = get_clamped_actions_count()
                -- log(storage.num_actions_performed .. " : " .. tostring(Event_Data:get()[count + 1 ].name) .. " : " .. Event_Data:get_deviation({ count = count}))
                Event_Data:get_deviation({ count = count})
                -- threshold = threshold - Event_Data:get().deviation_average_1
                threshold = threshold - _event_data.deviation_average_1

                if (not off_cycle and (tick + num_cycles) % 8 == 0) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_staged_chunk, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions[current_step.step.name], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 8 == 1) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_medium, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 8 == 2) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks, weight = weight, step_data = step_data, planet = planet })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions[current_step.step.name], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 8 == 3) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_staged_chunk, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 8 == 4) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions[current_step.step.name], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 8 == 5) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 8 == 6) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_staged_chunk, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions[current_step.step.name], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                elseif (not off_cycle and (tick + num_cycles) % 8 == 7) then
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_low, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "specific", threshold = threshold, action = overmind_actions.process_chunks_priority_high, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                    return_code, weight = do_action({ source = "indexed", threshold = threshold, action = overmind_actions["process_chunks_" .. chunk_level.get(planet)], weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                    if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end
                end

                return_code, weight = do_rand_actions({ tick = tick + num_cycles, rand_threshold = rand_threshold, threshold = threshold, weight = weight, step_data = step_data, planet = planet, overmind = overmind, selected_difficulty = selected_difficulty, surface = surface, evolution_factor = evolution_factor })
                -- if (return_code < 0) then break end
                if (should_break({ return_code = return_code, weight = weight, threshold = threshold })) then break end

                count = get_clamped_actions_count()
                -- log(storage.num_actions_performed .. " : " .. tostring(Event_Data:get()[count + 1 ].name) .. " : " .. Event_Data:get_deviation({ count = count}))
                Event_Data:get_deviation({ count = count})
                -- threshold = threshold - Event_Data:get().deviation_average_1
                threshold = threshold - _event_data.deviation_average_1

                num_cycles = num_cycles + 1
            end

            -- if (game.tick % 12 == 0) then log(threshold) end

            -- log("max_cycles = " .. max_cycles)
            -- log("num_cycles = " .. num_cycles)

            -- local deviation_average = Event_Data:get():get_deviation_average()
            -- local event_data = Event_Data:get()
            local cycle_proportion = num_cycles / max_cycles
            -- local meta_modifier = ((event_data.deviation_average * cycle_proportion * storage.num_actions_performed) * (1.5 + evolution_factor)) / 2
            local meta_modifier = ((_event_data.deviation_average * cycle_proportion * storage.num_actions_performed) * (1.5 + evolution_factor)) / 2
            -- if (game.tick % 128 == 0) then log(meta_modifier) end
            -- local meta_aggregate = ((event_data.deviation_average + num_cycles * storage.num_actions_performed) * (1.5 + evolution_factor)) / 2
            local meta_aggregate = ((_event_data.deviation_average + num_cycles * storage.num_actions_performed) * (1.5 + evolution_factor)) / 2
            -- if (game.tick % 128 == 0) then log(meta_aggregate) end
            if (meta_aggregate < selected_difficulty.value) then meta_aggregate = ((selected_difficulty.value / selected_difficulty.radius_modifier) ^ selected_difficulty.radius_modifier) * (meta_aggregate ^ (1 / selected_difficulty.radius_modifier) + selected_difficulty.value) end
            for _, data in pairs (current_step.step_data) do
                -- data.weight = data.weight * (0.7 + math.random() / 4)
                -- if (game.tick % 12 == 0) then log(data.weight) end
                -- data.weight = data.weight * (0.7 + math.random() / 4)
                -- if (game.tick % 12 == 0) then log(data.weight) end
                -- data.weight = data.weight ^ radius_root

                -- if (game.tick % 32 == 0) then log(data.weight) end
                if (data.weight > Constants.BIG_NUM / selected_difficulty.value) then
                    if (data.weight >= math.huge) then
                        Log.error("weight >= math.huge; resetting to default weight")
                        data.weight = default_weight
                    else
                        -- Log.error("weight >= Constants.BIG_NUM; resetting to default weight")
                        Log.error("weight > Constants.BIG_NUM / selected_difficulty.value")
                        -- data.weight = default_weight
                        local rand_val = 0
                        for i = 1, selected_difficulty.value / 2 + 1 do rand_val = rand_val + math.random() end
                        rand_val = rand_val / selected_difficulty.value + 1
                        -- data.weight = data.weight ^ (((rand_val / (selected_difficulty.value / (selected_difficulty.radius_modifier ^ 2) + 1)) + 0.2) / 10)
                        data.weight = Constants.BIG_NUM / (1 + data.count) - selected_difficulty.radius_modifier * rand_val * meta_aggregate * (((selected_difficulty.value ^ (selected_difficulty.radius_modifier ^ 2))/(2 + selected_difficulty.value - selected_difficulty.value * evolution_factor)) + (1 + meta_modifier ^ (selected_difficulty.radius_modifier ^ 2)) * ((data.weight ^ selected_difficulty.value) / (selected_difficulty.value + data.weight ^ selected_difficulty.value) + data.weight ^ (((rand_val / (selected_difficulty.value / (selected_difficulty.radius_modifier ^ 2))) + 0.2) / 10)))
                        data.weight = data.weight / ((1 + selected_difficulty.radius_modifier) ^ 2)
                        -- if (game.tick % 32 == 0) then log(data.weight) end
                        -- if (game.tick % 6 == 0) then log(data.weight) end
                    end
                else
                    -- log(meta_aggregate)
                    -- log(meta_modifier)
                    -- log(meta_aggregate + meta_modifier)

                    if (data.weight > threshold) then
                        local rand_val = 0
                        for i = 1, selected_difficulty.value + 1 do rand_val = rand_val + math.random() end
                        rand_val = rand_val / selected_difficulty.value + 1
                        -- data.weight = data.weight ^ (((rand_val / (selected_difficulty.value / (selected_difficulty.radius_modifier ^ 2) + 1)) + 0.2) / 10)
                        data.weight = (selected_difficulty.value / (1 + data.count)) * (rand_val * meta_aggregate * (2/(2 - evolution_factor))) + meta_modifier * ((data.weight ^ selected_difficulty.value) / (selected_difficulty.value + data.weight ^ selected_difficulty.value) + data.weight ^ ((((rand_val * 2) / (selected_difficulty.value / (selected_difficulty.radius_modifier ^ 2))) + 0.2) / 10))
                        data.weight = data.weight / ((1 + selected_difficulty.radius_modifier) ^ 2)
                    end

                    data.weight = data.weight + meta_aggregate +  meta_modifier

                end
                -- if (game.tick % 32 == 0) then log(data.weight) end
            end


        end

        ::continue::

        if (off_cycle and chunk_itrs[planet.string_val]) then
            local chunk = chunk_itrs[planet.string_val]()

            if (chunk ~= nil) then
                -- log("iterating chunks: x = " .. chunk.x .. ", y = " .. chunk.y)

                Overmind_Utils.stage_new_chunk({
                    chunk_size = Constants.CHUNK_SIZE,
                    event = -1,
                    queue = overmind.chunks_priority_high,
                    chunk_pos = {
                        x = chunk.x,
                        y = chunk.y,
                    },
                    surface = game.surfaces[planet.string_val],
                    area = chunk.area,
                })
            end
        end

        -- if (    type(_chunk) == "table"
        --     and _chunk.valid
        --     and _chunk.deaths <= 0
        --     and _chunk.deaths <= 0
        --     and _chunk.pollution_data.pollution <= 0
        --     and _chunk.spawner_count <= 0
        --     and _chunk.rocket_launches <= 0
        --     and _chunk.weight <= 1.0025)
        -- then
        --     Log.error("removing chunk, but why (how did this happen?)")
        --     Log.error(_chunk)
        --     error("removing chunk, but why (how did this happen?)")
        --     -- overmind.chunks[_chunk.x][_chunk.y] = nil
        --     overmind.chunks.chunks_1[_chunk.x][_chunk.y] = nil
        --     if (type(_chunk.above) == "table" and type(_chunk.below) == "table") then _chunk.above.below = _chunk.below.above end
        --     _chunk.above = nil
        --     _chunk.below = nil
        --     if (type(_chunk.next) == "table" and type(_chunk.prev) == "table") then _chunk.next.prev = _chunk.prev.next end
        --     _chunk.next = nil
        --     _chunk.prev = nil
        -- end
    end
end
Event_Handler:register_event({
    event_name = "on_tick",
    source_name = "overmind_controller.on_tick",
    func_name = "overmind_controller.on_tick",
    func = overmind_controller.on_tick,
})

function overmind_controller.on_biter_base_built(event)
    Log.debug("overmind_controller.on_biter_base_built")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end
    if (not event.name or event.name ~= defines.events.on_biter_base_built) then return end
    if (not event.entity or not event.entity.valid) then return end
    if (not event.entity.surface or not event.entity.surface.valid ) then return end

    if (not locals.validate_planet({ surface = event.entity.surface })) then return end

    local pos = event.entity.position

    if (cache[defines.events.on_biter_base_built] == nil) then cache[defines.events.on_biter_base_built] = {} end
    if (not cache[defines.events.on_biter_base_built][event.entity.surface.name]) then cache[defines.events.on_biter_base_built][event.entity.surface.name] = {} end
    if (not cache[defines.events.on_biter_base_built][event.entity.surface.name][game.tick]) then cache[defines.events.on_biter_base_built][event.entity.surface.name][game.tick] = {} end
    if (not cache[defines.events.on_biter_base_built][event.entity.surface.name][game.tick][pos.x / 32]) then cache[defines.events.on_biter_base_built][event.entity.surface.name][game.tick][pos.x / 32] = {} end
    if (not cache[defines.events.on_biter_base_built][event.entity.surface.name][game.tick][pos.x / 32][pos.y / 32]) then cache[defines.events.on_biter_base_built][event.entity.surface.name][game.tick][pos.x / 32][pos.y / 32] = 0 end

    local entry = cache[defines.events.on_biter_base_built][event.entity.surface.name][game.tick][pos.x / 32][pos.y / 32]
    entry = entry + 1

    -- Overmind_Service.on_biter_base_built(event)
end
Event_Handler:register_event({
    event_name = "on_biter_base_built",
    source_name = "overmind_controller.on_biter_base_built",
    func_name = "overmind_controller.on_biter_base_built",
    func = overmind_controller.on_biter_base_built,
})

function overmind_controller.on_build_base_arrived(event)
    Log.debug("overmind_controller.on_build_base_arrived")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end

    if (event.unit and not event.unit.valid) then return end
    if (event.group and not event.group.valid) then return end

    if (event.unit and event.unit.valid) then
        if (not locals.validate_planet({ surface = event.unit.surface })) then return end
    elseif (event.commandable and event.commandable.valid) then
        if (not locals.validate_planet({ surface = event.commandable.surface })) then return end
    else
        return
    end

    Overmind_Service.on_build_base_arrived(event)
end
Event_Handler:register_event({
    event_name = "on_build_base_arrived",
    source_name = "overmind_controller.on_build_base_arrived",
    func_name = "overmind_controller.on_build_base_arrived",
    func = overmind_controller.on_build_base_arrived,
})

function overmind_controller.on_built_entity(event)
    Log.debug("overmind_controller.on_built_entity")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end

    if (not locals.validate_planet({ surface = event.entity.surface })) then return end

    Overmind_Service.on_built_entity(event)
end
Event_Handler:register_event({
    event_name = "on_built_entity",
    source_name = "overmind_controller.on_built_entity",
    func_name = "overmind_controller.on_built_entity",
    func = overmind_controller.on_built_entity,
})

function overmind_controller.on_cargo_pod_finished_descending(event)
    Log.debug("overmind_controller.on_cargo_pod_finished_descending")
    Log.info(event)

    if (not event) then return end
    if (not event.tick or not event.cargo_pod or event.launched_by_rocket) then return end

    Overmind_Service.on_cargo_pod_finished_descending(event)
end
Event_Handler:register_event({
    event_name = "on_cargo_pod_finished_descending",
    source_name = "overmind_controller.on_cargo_pod_finished_descending",
    func_name = "overmind_controller.on_cargo_pod_finished_descending",
    func = overmind_controller.on_cargo_pod_finished_descending,
})

function overmind_controller.on_chunk_generated(event)
    Log.debug("overmind_controller.on_chunk_generated")
    Log.info(event)

    if (not event) then return end
    if (not event.tick ) then return end
    if (not event.name or event.name ~= defines.events.on_chunk_generated) then return end
    if (not event.surface or not event.surface.valid ) then return end
    if (not event.area or not event.area.left_top or not event.area.right_bottom) then return end
    if (not event.area or not event.area.left_top.x or not event.area.left_top.y) then return end
    if (not event.area or not event.area.right_bottom.x or not event.area.right_bottom.y) then return end
    if (not event.position or not event.position.x or not event.position.y) then return end

    if (not locals.validate_planet({ surface = event.surface })) then return end

    Overmind_Service.on_chunk_generated(event)
end
Event_Handler:register_event({
    event_name = "on_chunk_generated",
    source_name = "overmind_controller.on_chunk_generated",
    func_name = "overmind_controller.on_chunk_generated",
    func = overmind_controller.on_chunk_generated,
})

function overmind_controller.on_player_mined_entity(event)
    Log.debug("overmind_controller.on_player_mined_entity")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end
    if (not event.entity or not event.entity.valid) then return end
    local player = game.players[event.player_index]
    if (not player or not player.valid) then return end
    if (not event.tick) then return end

    if (not locals.validate_planet({ surface = player.surface })) then return end

    Overmind_Service.on_player_mined_entity(event)
end
Event_Handler:register_event({
    event_name = "on_player_mined_entity",
    source_name = "overmind_controller.on_player_mined_entity",
    func_name = "overmind_controller.on_player_mined_entity",
    func = overmind_controller.on_player_mined_entity,
})

function overmind_controller.on_player_mined_item(event)
    Log.debug("overmind_controller.on_player_mined_item")
    Log.info(event)

    if (not event) then return end
    if (not event.player_index or event.player_index < 1) then return end
    if (not game) then return end
    local player = game.players[event.player_index]
    if (not player or not player.valid) then return end
    if (not event.tick) then return end

    if (not locals.validate_planet({ surface = player.surface })) then return end

    Overmind_Service.on_player_mined_item(event)
end
Event_Handler:register_event({
    event_name = "on_player_mined_item",
    source_name = "overmind_controller.on_player_mined_item",
    func_name = "overmind_controller.on_player_mined_item",
    func = overmind_controller.on_player_mined_item,
})

function overmind_controller.on_entity_damaged(event)
    Log.debug("overmind_controller.on_entity_damaged")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end
    if (not event.name or event.name ~= defines.events.on_entity_damaged) then return end
    if (not event.entity or not event.entity.valid) then return end
    if (not event.entity.force or not event.entity.force.valid) then return end
    if (type(event.entity.force.name) ~= "string" or event.entity.force.name ~= "enemy") then return end
    if (not event.entity.surface or not event.entity.surface.valid) then return end

    if (not locals.validate_planet({ surface = event.entity.surface })) then return end

    Overmind_Service.on_entity_damaged(event)
end
Event_Handler:register_event({
    event_name = "on_entity_damaged",
    filter = Filters.on_entity_damaged,
    source_name = "overmind_controller.on_entity_damaged",
    func_name = "overmind_controller.on_entity_damaged",
    func = overmind_controller.on_entity_damaged,
})

function overmind_controller.on_entity_died(event)
    Log.debug("overmind_controller.on_entity_died")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end
    if (not event.name or event.name ~= defines.events.on_entity_died) then return end
    if (not event.entity or not event.entity.valid) then return end
    if (not event.entity.surface or not event.entity.surface.valid) then return end
    if (not event.entity.force or not event.entity.force.valid) then return end
    if (event.cause and not event.cause.valid) then return end

    if (not locals.validate_planet({ surface = event.entity.surface })) then return end

    local position = { x = math.floor(event.entity.position.x / 32), y = math.floor(event.entity.position.y / 32), }
    -- local position_key = position.x .. "-" .. position.y

    local force = event.entity.force
    if (not force or not force.valid) then return end

    local entities_died_event_cache = {}
    if (not Cache[defines.events.on_entity_died]) then Cache[defines.events.on_entity_died] = entities_died_event_cache end
    entities_died_event_cache = Cache[defines.events.on_entity_died]
    if (not entities_died_event_cache[force.name]) then entities_died_event_cache[force.name] = {} end
    if (not entities_died_event_cache[force.name][position.x]) then entities_died_event_cache[force.name][position.x] = {} end
    if (not entities_died_event_cache[force.name][position.x][position.y]) then entities_died_event_cache[force.name][position.x][position.y] = {} end
    -- if (not Cache[defines.events.on_entity_died][force.name][position.x][position.y]) then Cache[defines.events.on_entity_died][force.name][position.x][position.y][entity.name] = {} end

    local aggregate_event_data = entities_died_event_cache[force.name][position.x][position.y][event.entity.name]

    if (not aggregate_event_data) then
        local entity = event.entity
        local surface = entity.surface
        local cause = event.cause

        local event_data =
        {
            event = defines.events.on_entity_died,
            count = 1,
            witnessed = true,
            entity = {
                type = entity.type,
                name = entity.name,
                force = {
                    index = entity.force.index,
                    name = entity.force.name,
                    force = force,
                },
                surface_data = {
                    name = surface.name,
                    index = surface.name.index,
                    surface = surface,
                },
                position = entity.position,
            },
            surface = surface,
            cause = cause and {
                type = cause.type,
                name = cause.name,
                force = {
                    index = cause.force.index,
                    name = cause.force.name,
                    force = force,
                },
                surface_data = {
                    name = surface.name,
                    index = surface.name.index,
                    surface = surface,
                },
                position = cause.position,
            },
        }

        -- log(serpent.line(defines.events.on_entity_died))
        -- log(serpent.line(force.name))
        -- log(serpent.line(position.x))
        -- log(serpent.line(position.y))
        -- log(serpent.line(entity.name))
        -- log(serpent.block(entities_died_event_cache))
        -- log(serpent.block(entities_died_event_cache[force.name]))
        -- log(serpent.block(entities_died_event_cache[force.name][position.x]))
        -- log(serpent.block(entities_died_event_cache[force.name][position.x][position.y]))
        -- log(serpent.block(entities_died_event_cache[force.name][position.x][position.y][entity.name]))
        entities_died_event_cache[force.name][position.x][position.y][entity.name] = event_data
    else
        aggregate_event_data.count = aggregate_event_data.count + 1
        if (not aggregate_event_data.cause) then
            local entity = event.entity
            local surface = entity.surface
            local cause = event.cause

            aggregate_event_data = cause and {
                type = cause.type,
                name = cause.name,
                force = {
                    index = cause.force.index,
                    name = cause.force.name,
                    force = force,
                },
                surface_data = {
                    name = surface.name,
                    index = surface.name.index,
                    surface = surface,
                },
                position = cause.position,
            }
        end
    end

    -- Overmind_Service.on_entity_died(event)
end
Event_Handler:register_event({
    event_name = "on_entity_died",
    filter = Filters.on_entity_died,
    source_name = "overmind_controller.on_entity_died",
    func_name = "overmind_controller.on_entity_died",
    func = overmind_controller.on_entity_died,
})

function overmind_controller.process_on_entity_died_events(event)
    Log.debug("overmind_controller.process_on_entity_died_events")
    Log.info(event)

    if (not Cache[defines.events.on_entity_died]) then Cache[defines.events.on_entity_died] = {} end
    for force_name, force_data in pairs(Cache[defines.events.on_entity_died]) do
        -- if (not next(force_data, nil)) then goto continue end

        for x, pos in pairs(force_data) do
            for y, entities in pairs(pos) do
                for entity_name, event_data in pairs(entities) do
                    Overmind_Service.process_aggregate_entity_died(event_data)
                    entities[entity_name] = nil
                end
                pos[y] = nil
            end
            force_data[x] = nil
        end
        Cache[defines.events.on_entity_died][force_name] = nil
        -- ::continue::
    end
end
Event_Handler:register_event({
    event_name = "on_nth_tick",
    nth_tick = 150,
    source_name = "overmind_controller.process_on_entity_died_events",
    func_name = "overmind_controller.process_on_entity_died_events",
    func = overmind_controller.process_on_entity_died_events,
})

function overmind_controller.on_robot_built_entity(event)
    Log.debug("overmind_controller.on_robot_built_entity")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end

    if (not locals.validate_planet({ surface = event.entity.surface })) then return end

    Overmind_Service.on_robot_built_entity(event)
end
Event_Handler:register_event({
    event_name = "on_robot_built_entity",
    source_name = "overmind_controller.on_robot_built_entity",
    func_name = "overmind_controller.on_robot_built_entity",
    func = overmind_controller.on_robot_built_entity,
})

function overmind_controller.on_robot_exploded_cliff(event)
    Log.debug("overmind_controller.on_robot_exploded_cliff")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end

    if (not locals.validate_planet({ surface = event.entity.surface })) then return end

    Overmind_Service.on_robot_exploded_cliff(event)
end
Event_Handler:register_event({
    event_name = "on_robot_exploded_cliff",
    source_name = "overmind_controller.on_robot_exploded_cliff",
    func_name = "overmind_controller.on_robot_exploded_cliff",
    func = overmind_controller.on_robot_exploded_cliff,
})

function overmind_controller.on_robot_mined_entity(event)
    Log.debug("overmind_controller.on_robot_mined_entity")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end

    if (not locals.validate_planet({ surface = event.entity.surface })) then return end

    Overmind_Service.on_robot_mined_entity(event)
end
Event_Handler:register_event({
    event_name = "on_robot_mined_entity",
    source_name = "overmind_controller.on_robot_mined_entity",
    func_name = "overmind_controller.on_robot_mined_entity",
    func = overmind_controller.on_robot_mined_entity,
})

function overmind_controller.on_rocket_launch_ordered(event)
    Log.debug("overmind_controller.on_rocket_launch_ordered")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end
    if (not event.name or not event.name == defines.events.on_rocket_launch_ordered) then return end
    if (not event.rocket_silo or not event.rocket_silo.valid) then return end
    if (not event.rocket_silo.surface or not event.rocket_silo.surface.valid) then return end

    if (not locals.validate_planet({surface = event.rocket_silo.surface})) then return end

    -- Cache_Data:get():add({
    --     key =  event.rocket_silo.surface.name ..  "." .. defines.events.on_rocket_launch_ordered .. "." .. game.tick,
    --     value = event
    -- })
    local val = Cache_Data:get_by_key({
        key =  event.rocket_silo.surface.name ..  "." .. defines.events.on_rocket_launch_ordered .. "." .. game.tick,
        fallback = function () return {
                key =  event.rocket_silo.surface.name ..  "." .. defines.events.on_rocket_launch_ordered .. "." .. game.tick,
                value = event,
                tick_valid_until = game.tick + math.random(666),
            }
        end,
    })

    -- log(serpent.block(val))

    Overmind_Service.on_rocket_launch_ordered(event)
end
Event_Handler:register_event({
    event_name = "on_rocket_launch_ordered",
    source_name = "overmind_controller.on_rocket_launch_ordered",
    func_name = "overmind_controller.on_rocket_launch_ordered",
    func = overmind_controller.on_rocket_launch_ordered,
})

function overmind_controller.on_script_path_request_finished(event)
    Log.debug("overmind_controller.on_script_path_request_finished")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end
    if (not event.id) then return end
    if (type(event.try_again_later) ~= "boolean") then return end
    if (not event.name or not event.name == defines.events.on_script_path_request_finished) then return end

    Overmind_Service.on_script_path_request_finished(event)
end
Event_Handler:register_event({
    event_name = "on_script_path_request_finished",
    source_name = "overmind_controller.on_script_path_request_finished",
    func_name = "overmind_controller.on_script_path_request_finished",
    func = overmind_controller.on_script_path_request_finished,
})

function locals.validate_planet(data)
    Log.debug("locals.validate_planet")
    Log.info(data)

    local return_val = false

    if (type(data) ~= "table") then return return_val end
    if (not data.surface or not data.surface.valid) then return return_val end

    -- if (data.surface.name == "gleba") then Log.error("found gleba event", true) end
    return Constants.DEFAULTS.planets[data.surface.name] ~= nil
end

return overmind_controller