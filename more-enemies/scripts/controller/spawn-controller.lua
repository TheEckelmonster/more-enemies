
local Constants = require("libs.constants.constants")
local Initialization = require("scripts.initialization")
local Log = require("libs.log.log")
local More_Enemies_Repository = require("scripts.repositories.more-enemies-repository")
local Nth_Tick_Repository = require("scripts.repositories.nth-tick-repository")
local Spawn_Service = require("scripts.service.spawn-service")
local Settings_Service = require("scripts.service.settings-service")
local Version_Validations = require("scripts.validations.version-validations")

local spawn_controller = {}
spawn_controller.name = "spawn_controller"

-- function spawn_controller.do_tick(event)
function spawn_controller.on_tick(event)
    -- Log.debug("spawn_controller.on_tick")
    -- Log.info(event)

    local tick = event.tick
    local nth_tick = Settings_Service.get_nth_tick()
    local offset = 1 + nth_tick -- Constants.time.TICKS_PER_SECOND / 2
    local tick_modulo = tick % offset

    if (nth_tick ~= tick_modulo) then return end

    -- Check/validate the storage version
    if (not Version_Validations.validate_version()) then return end

    local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()

    if (not more_enemies_data.valid) then more_enemies_data = Initialization.reinit() end

    local nth_tick_complete_data = Nth_Tick_Repository.get_nth_tick_complete_data()
    local nth_tick_cleanup_complete_data = Nth_Tick_Repository.get_nth_tick_cleanup_complete_data()

    nth_tick_complete_data.previous = nth_tick_complete_data.current
    nth_tick_cleanup_complete_data.previous = nth_tick_cleanup_complete_data.current
    nth_tick_complete_data.current = false
    nth_tick_cleanup_complete_data.current = false

    if (more_enemies_data.do_nth_tick) then
        Log.info("attempt to process")
        if (nth_tick_cleanup_complete_data.previous and Spawn_Service.do_nth_tick(event, more_enemies_data)) then
            Log.debug("do_nth_tick completed")
            nth_tick_complete_data.current = true
        else
            Log.debug("failed to finish processing")
        end
    end

    Log.info("attempt to clean up")
    if (not more_enemies_data.do_nth_tick or nth_tick_complete_data.current or not nth_tick_cleanup_complete_data.previous) then
        if (Spawn_Service.do_nth_tick_cleanup(event, more_enemies_data)) then
            Log.debug("do_nth_tick_cleanup completed")
            nth_tick_cleanup_complete_data.current = true
        else
            Log.debug("failed to finish cleaning up")
        end
    end

    if (not more_enemies_data.do_nth_tick) then
        local at_capacity = 0

        for _, planet in pairs(Constants.DEFAULTS.planets) do
            local max_num_unit_clones = Settings_Service.get_maximum_number_of_spawned_clones(planet.string_val)
            local max_num_unit_group_clones = Settings_Service.get_maximum_number_of_unit_group_clones(planet.string_val)

            if (not more_enemies_data.clone[planet.string_val]) then
                more_enemies_data.clone[planet.string_val] = {}
                more_enemies_data.clone[planet.string_val].unit = 0
                more_enemies_data.clone[planet.string_val].unit_group = 0
            end

            if (more_enemies_data.clone[planet.string_val].unit_group > max_num_unit_group_clones) then
                Log.warn("Tried to clone more than the unit-group limit: " .. serpent.block(max_num_unit_group_clones))
                Log.warn("Currently " .. serpent.block(more_enemies_data.clone[planet.string_val].unit) .. " unit clones")
                Log.warn("Currently " .. serpent.block(more_enemies_data.clone[planet.string_val].unit_group) .. " unit-group clones")

                at_capacity = at_capacity + 1
            end
            if (more_enemies_data.clone[planet.string_val].unit > max_num_unit_clones) then
                Log.warn("Tried to clone more than the unit limit: " .. serpent.block(max_num_unit_clones))
                Log.warn("Currently " .. serpent.block(more_enemies_data.clone[planet.string_val].unit) .. " unit clones")
                Log.warn("Currently " .. serpent.block(more_enemies_data.clone[planet.string_val].unit_group) .. " unit-group clones")

                at_capacity = at_capacity + 1
            end
        end

        if (nth_tick_cleanup_complete_data.current and at_capacity < 4) then
            more_enemies_data.do_nth_tick = true
        end
    end
end
Event_Handler:register_event({
    event_name = "on_tick",
    source_name = "spawn_controller.on_tick",
    func_name = "spawn_controller.on_tick",
    func = spawn_controller.on_tick,
})

-- function spawn_controller.entity_died(event)
function spawn_controller.on_entity_died(event)
    Log.debug("spawn_controller.on_entity_died")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end
    if (not event.entity or not event.entity.valid) then return end
    if (not event.entity.force or not event.entity.force.valid) then return end
    if (event.entity.force ~= "enemy") then return end

    Spawn_Service.entity_died(event)
end
Event_Handler:register_event({
    event_name = "on_entity_died",
    filter = Filters.on_entity_died,
    source_name = "spawn_controller.on_entity_died",
    func_name = "spawn_controller.on_entity_died",
    func = spawn_controller.on_entity_died,
})

-- function spawn_controller.entity_spawned(event)
function spawn_controller.on_entity_spawned(event)
    Log.debug("spawn_controller.on_entity_spawned")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end
    if (not event.entity or not event.entity.valid) then return end
    if (not event.entity.force or not event.entity.force.valid) then return end
    if (event.entity.force.name ~= "enemy") then return end

    Spawn_Service.entity_spawned(event)
end
Event_Handler:register_event({
    event_name = "on_entity_spawned",
    source_name = "spawn_controller.on_entity_spawned",
    func_name = "spawn_controller.on_entity_spawned",
    func = spawn_controller.on_entity_spawned,
})

-- function spawn_controller.entity_built(event)
function spawn_controller.script_raised_built(event)
    Log.debug("spawn_controller.script_raised_built")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end
    if (not event.entity or not event.entity.valid) then return end
    if (not event.entity.force or not event.entity.force.valid) then return end
    if (event.entity.force ~= "enemy") then return end

    if (not Settings_Service.get_BREAM_do_clone()) then
        Log.debug("more-enemies cloning of BREAM entities is disabled; returning")
        return
    end

    Spawn_Service.entity_built(event)
end
Event_Handler:register_event({
    event_name = "script_raised_built",
    filter = Filters.script_raised_built,
    source_name = "spawn_controller.script_raised_built",
    func_name = "spawn_controller.script_raised_built",
    func = spawn_controller.script_raised_built,
})

return spawn_controller