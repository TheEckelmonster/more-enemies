local storage

local Difficulty_Utils = require("scripts.utils.difficulty-utils")
local Initialization = require("scripts.initialization")
local Log = require("libs.log.log")
local More_Enemies_Repository = require("scripts.repositories.more-enemies-repository")
local Settings_Service = require("scripts.service.settings-service")
local Settings_Utils = require("scripts.utils.settings-utils")
local Spawn_Utils = require("scripts.utils.spawn-utils")
local Unit_Group_Data = require("scripts.data.unit-group-data")

local unit_group_service = {}

function unit_group_service.unit_group_created(data)
    Log.debug("unit_group_service.unit_group_created")
    Log.info(data)

    if (not data) then return end
    if (not data.event) then return end

    -- local more_enemies_data = data.more_enemies_data or More_Enemies_Repository.get_more_enemies_data()
    storage.more_enemies = storage.more_enemies or More_Enemies_Repository.get_more_enemies_data()
    local more_enemies_data = storage.more_enemies
    -- if (not more_enemies_data.valid) then more_enemies_data = Initialization.reinit() end

    local group = data.event.group
    if (not group) then return end
    if (not group.valid) then return end
    if (not group.surface or not group.surface.valid or not group.surface.name) then return end

    if (Settings_Utils.is_vanilla(group.surface.name)) then return end

    if (not group.is_unit_group) then return end
    if (not group.position) then return end

    if (more_enemies_data.groups[group.surface.name]
            and more_enemies_data.groups[group.surface.name][group.unique_id]
            and more_enemies_data.groups[group.surface.name][group.unique_id].valid)
    then
        Log.warn("group already exists; returning")
        return
    end

    Log.info("Getting difficulty")
    local difficulty = Difficulty_Utils.get_difficulty(group.surface.name).difficulty
    if (not difficulty or not difficulty.valid) then
        Log.warn("difficulty was nil or invalid; reindexing")
        difficulty = Difficulty_Utils.get_difficulty(group.surface.name, true).difficulty
    end
    if (not difficulty or not difficulty.valid) then
        Log.error("Failed to find a valid difficulty for " .. serpent.block(group.surface.name))
        return
    end

    Log.info("Getting selected_difficulty")
    local selected_difficulty = difficulty.selected_difficulty
    if (not selected_difficulty) then return end

    local clone_unit_group_setting = Settings_Service.get_clone_unit_group_setting(group.surface.name)

    Log.info("adding group: " .. serpent.block(group))

    Log.info(group.surface.name)

    Log.info("before: " .. serpent.block(more_enemies_data.groups))

    if (not more_enemies_data.groups[group.surface.name]) then
        more_enemies_data.groups[group.surface.name] = {}
    end

    Log.info("after: " .. serpent.block(more_enemies_data.groups))

    local loop_len = 1
    local use_evolution_factor = Settings_Service.get_do_evolution_factor(group.surface.name)
    local evolution_factor = 1

    Log.debug("use_evolution_factor = " .. serpent.block(use_evolution_factor))
    if (use_evolution_factor) then
        evolution_factor = group.force.get_evolution_factor(group.surface)
    end

    if (selected_difficulty.value > 1) then
        if (clone_unit_group_setting > 1) then
            loop_len = math.floor((selected_difficulty.value + clone_unit_group_setting - 1) * evolution_factor)
        else
            loop_len = math.floor((selected_difficulty.value * clone_unit_group_setting) * evolution_factor)
        end
    else
        loop_len = math.floor((selected_difficulty.value * clone_unit_group_setting) * evolution_factor)
    end
    Log.info("loop_len: " .. serpent.block(loop_len))

    local unit_group_data = Unit_Group_Data:new({
        group = group,
        max_count = loop_len,
        valid = true,
    })

    more_enemies_data.groups[group.surface.name][group.unique_id] = unit_group_data

    --   Log.error(unit_group_data)
    Log.debug(more_enemies_data.groups[group.surface.name][group.unique_id])
end

function unit_group_service.unit_group_finished_gathering(data)
    Log.debug("unit_group_service.unit_group_finished_gathering")
    Log.info(data)

    if (not data) then return end
    if (not data.event) then return end

    local group = data.event.group
    local tick = data.event.tick

    if (not group or not group.valid or not group.surface or not group.surface.valid or Settings_Utils.is_vanilla(group.surface.name)) then return end

    -- local more_enemies_data = data.more_enemies_data or More_Enemies_Repository.get_more_enemies_data()
    storage.more_enemies = storage.more_enemies or More_Enemies_Repository.get_more_enemies_data()
    local more_enemies_data = storage.more_enemies
    -- if (not more_enemies_data.valid) then more_enemies_data = Initialization.reinit() end

    Log.info("1")
    if (not group) then return end
    if (not group.valid) then return end
    if (not group.surface or not group.surface.name) then return end
    if (not group.is_unit_group) then return end
    if (not group.force) then return end

    Log.info("2")

    local difficulty = Difficulty_Utils.get_difficulty(group.surface.name).difficulty
    if (not difficulty or not difficulty.valid) then
        Log.warn("difficulty was nil or invalid; reindexing")
        difficulty = Difficulty_Utils.get_difficulty(group.surface.name, true).difficulty
    end
    if (not difficulty or not difficulty.valid) then
        Log.error("Failed to find a valid difficulty for " .. serpent.block(group.surface.name))
        return
    end
    Log.debug(difficulty)

    if (not difficulty) then return end

    local selected_difficulty = difficulty.selected_difficulty
    Log.debug(selected_difficulty)
    if (not selected_difficulty) then return end

    Log.info("3")

    local loop_len = 1

    local use_evolution_factor = Settings_Service.get_do_evolution_factor(group.surface.name)

    local evolution_factor = 1
    Log.info("use_evolution_factor = " .. serpent.block(use_evolution_factor))
    if (use_evolution_factor) then
        evolution_factor = group.force.get_evolution_factor(group.surface)
    end

    local clone_unit_group_setting = Settings_Service.get_clone_unit_group_setting(group.surface.name)

    Log.info(clone_unit_group_setting)
    Log.info(selected_difficulty.value)
    Log.info(evolution_factor)

    loop_len = math.floor((selected_difficulty.value * clone_unit_group_setting) * evolution_factor)
    Log.info("loop_len: " .. serpent.block(loop_len))

    Log.info("4")

    local unit_group_data = Unit_Group_Data:new()
    if (more_enemies_data.groups[group.surface.name]
            and more_enemies_data.groups[group.surface.name][group.unique_id] ~= nil)
    then
        unit_group_data = more_enemies_data.groups[group.surface.name][group.unique_id]
    end

    if (not unit_group_data or not unit_group_data.valid) then
        -- Log.error(unit_group_data)
        Log.debug("returning", true)
        return
    end

    if (unit_group_data.count >= unit_group_data.max_count) then
        more_enemies_data.groups[group.surface.name][group.unique_id] = nil
        return
    end

    for i = 1, loop_len do
        if (unit_group_data.count >= unit_group_data.max_count) then
            Log.error("breaking", true)
            break
        end

        Log.debug("attempting to duplicate unit group")
        if (unit_group_data.count < unit_group_data.max_count) then
            Log.info("duplicating unit group: " .. serpent.block(i))
            Log.info("tick: " .. tick)
            Spawn_Utils.duplicate_unit_group(group)
        end

        if (unit_group_data and unit_group_data.valid) then
            unit_group_data.count = unit_group_data.count + 1
        end
    end

    if (unit_group_data and unit_group_data.count ~= nil) then
        Log.info("before: " .. unit_group_data.count)
        unit_group_data.count = unit_group_data.count + 1
        Log.info("after: " .. unit_group_data.count)
    end

    Log.info("5")

    if (unit_group_data and unit_group_data.valid and not unit_group_data.mod_name) then
        Log.debug("releasing from spawner")
        group.release_from_spawner()
        Log.debug("start moving")
        group.start_moving()
    end

    if (unit_group_data.count >= unit_group_data.max_count) then
        more_enemies_data.groups[group.surface.name][group.unique_id] = nil
    end
end

function unit_group_service.init(__storage)
    storage = __storage
end

return unit_group_service
