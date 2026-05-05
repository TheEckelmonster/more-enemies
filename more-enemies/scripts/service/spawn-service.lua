local storage

local Data = require("__TheEckelmonster-core-library__.libs.data.data")

local BREAM_Constants = require("libs.constants.mods.BREAM-constants")
local Clone_Data = require("scripts.data.clone-data")
local Constants = require("libs.constants.constants")
local Gleba_Settings_Constants = require("libs.constants.settings.gleba-settings-constants")
local Global_Settings_Constants = require("libs.constants.settings.global-settings-constants")
local Initialization = require("scripts.initialization")
local Log = require("libs.log.log")
local Mod_Repository = require("scripts.repositories.mod-repository")
local More_Enemies_Repository = require("scripts.repositories.more-enemies-repository")
local Nauvis_Settings_Constants = require("libs.constants.settings.nauvis-settings-constants")

local _Settings_Service = Settings_Service
local Settings_Service = require("scripts.service.settings-service")

local Settings_Utils = require("scripts.utils.settings-utils")
local Spawn_Utils = require("scripts.utils.spawn-utils")
local Unit_Group_Data = require("scripts.data.unit-group-data")

local BREAM_active = script and script.active_mods and script.active_mods["BREAM"]

local locals = {}

-- local cache = {}
-- local cache_attributes = {}
-- setmetatable(cache_attributes, { __mode = "k" })

local spawn_service = {}

spawn_service.planet = nil
spawn_service.planet_index = nil

spawn_service.entity_list = {}
spawn_service.entity_list_index = {}

spawn_service.entity = {}
spawn_service.entity_index = {}

spawn_service.BREAM = {}
spawn_service.BREAM.unit_group = nil
spawn_service.BREAM.clones_index = nil
spawn_service.BREAM.last_ran = 0

function spawn_service.do_nth_tick(event, more_enemies_data)
    -- Log.debug("spawn_service.do_nth_tick")
    -- Log.info(event)
    -- Log.info(more_enemies_data)
    -- local did_complete = false
    local tick = event.tick
    local more_enemies_data = more_enemies_data and more_enemies_data.valid and more_enemies_data or More_Enemies_Repository.get_more_enemies_data()
    -- if (not cache.more_enemies or not cache_attributes[cache.more_enemies] or cache_attributes[cache.more_enemies].time_to_live < game.tick) then
    --     local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()
    --     if (not more_enemies_data or not more_enemies_data.valid) then return end
    --     cache.more_enemies = { data = more_enemies_data, }
    --     cache_attributes[cache.more_enemies] = Data:new({ time_to_live = game.tick + 1234 + Random(1800)})
    -- end
    -- local more_enemies_data = cache.more_enemies.data

    -- Log.info("spawn_controller.do_nth_tick")
    if (not storage) then return false end
    -- Log.info("passed storage")
    -- if (not more_enemies_data.valid) then more_enemies_data = Initialization.reinit() end
    if (not more_enemies_data.do_nth_tick) then return end

    local mod_data = Mod_Repository.get_mod_data()

    local clones = {}
    --   local clones_per_tick = Settings_Service.get_clones_per_tick()
    local clones_per_tick = _Settings_Service.get_runtime_global_setting({ setting = Mod_Settings.CLONES_PER_TICK.name, })

    for k, planet in pairs(Constants.DEFAULTS.planets) do
        --   Log.info(k)
        -- Log.debug(planet)

        if (not more_enemies_data.clone) then more_enemies_data.clone = {} end
        if (not more_enemies_data.clone[planet.string_val]) then more_enemies_data.clone[planet.string_val] = {} end
        if (more_enemies_data.clone[planet.string_val].unit == nil) then more_enemies_data.clone[planet.string_val].unit = 0 end
        if (more_enemies_data.clone[planet.string_val].unit_group == nil) then more_enemies_data.clone[planet.string_val].unit_group = 0 end

        if (not more_enemies_data.staged_clone) then more_enemies_data.staged_clone = {} end
        if (not more_enemies_data.staged_clone[planet.string_val]) then more_enemies_data.staged_clone[planet.string_val] = {} end
        if (more_enemies_data.staged_clone[planet.string_val].unit == nil) then more_enemies_data.staged_clone[planet.string_val].unit = 0 end
        if (more_enemies_data.staged_clone[planet.string_val].unit_group == nil) then more_enemies_data.staged_clone[planet.string_val].unit_group = 0 end

        -- Log.info(more_enemies_data.clone[planet.string_val].unit)
        -- Log.info(more_enemies_data.clone[planet.string_val].unit_group)

        if (not Settings_Utils.is_vanilla(planet.string_val)) then
            -- Log.info("attempting to clone")

            -- if (not more_enemies_data.valid) then more_enemies_data = Initialization.reinit() end

            if (not more_enemies_data.staged_clones[planet.string_val]) then more_enemies_data.staged_clones[planet.string_val] = {} end
            if (not more_enemies_data.staged_clones[planet.string_val].unit) then more_enemies_data.staged_clones[planet.string_val].unit = {} end
            if (not more_enemies_data.staged_clones[planet.string_val].unit_group) then more_enemies_data.staged_clones[planet.string_val].unit_group = {} end

            local next_list = false

            if (not spawn_service.entity_list[planet.string_val]) then next_list = true end
            if (not spawn_service.entity_index[planet.string_val]) then next_list = true end

            if (next_list) then
                spawn_service.entity_list_index[planet.string_val], spawn_service.entity_list[planet.string_val] = next(more_enemies_data.staged_clones[planet.string_val], spawn_service.entity_list_index[planet.string_val])
            end

            local entity_list = spawn_service.entity_list[planet.string_val]

            if (not entity_list or not spawn_service.entity_list_index[planet.string_val]) then goto continue_2 end

            -- Log.debug("5.1")
            -- Log.info(spawn_service.entity_list_index[planet.string_val])
            -- Log.debug("5.2")
            -- Log.info(spawn_service.entity_index[planet.string_val])
            -- Log.debug("5.3")
            -- Log.info(entity_list)

            for j = 1, clones_per_tick do
                if (not entity_list[spawn_service.entity_index[planet.string_val]]) then
                    spawn_service.entity_index[planet.string_val] = nil
                end

                spawn_service.entity_index[planet.string_val], spawn_service.entity[planet.string_val] = next(entity_list, spawn_service.entity_index[planet.string_val])

                -- Log.debug(j)
                -- Log.debug("6.1")
                -- Log.info(spawn_service.entity_index)
                -- Log.info(spawn_service.entity_index[planet.string_val])
                -- Log.debug("6.2")
                local _staged_clone = spawn_service.entity[planet.string_val]
                -- Log.info(_staged_clone)

                if (not _staged_clone or not spawn_service.entity_index[planet.string_val]) then
                    -- Log.debug("6.3")
                    break
                end
                -- Log.debug("7")

                local skip = false

                -- Log.info(i)
                Log.info(_staged_clone)
                local staged_clone = _staged_clone.obj
                local group = _staged_clone.group
                local unit_number = 1
                -- local surface_name = Constants.DEFAULTS.planets.nauvis.string_val

                if (group and not group.valid) then
                    -- Log.debug("8.1")
                    -- Log.debug("_staged_clone.group was invalid; skipping")
                    -- Log.debug(_staged_clone)
                    skip = true
                end

                if (not staged_clone or not staged_clone.valid or staged_clone.surface.name ~= planet.string_val) then
                    -- Log.debug("8.2")
                    -- Log.debug("staged_clone is nil, invalid, or wrong planet for clone; skipping")
                    skip = true

                    unit_number = spawn_service.entity_index[planet.string_val]
                else
                    -- Log.debug("8.3")
                    unit_number = staged_clone.unit_number
                    -- surface_name = staged_clone.surface.name
                end
                -- Log.debug("8.4")

                if (not skip) then
                    -- Log.debug("8.5")
                    -- Log.debug(surface_name)
                    -- local clone_unit_setting = Settings_Service.get_clone_unit_setting(planet.string_val)
                    -- local clone_unit_group_setting = Settings_Service.get_clone_unit_group_setting(planet.string_val)
                    -- Log.info("clone_unit_setting: " .. serpent.block(clone_unit_setting))
                    -- Log.info("clone_unit_group_setting: " .. serpent.block(clone_unit_group_setting))

                    local clone_unit_setting = 1
                    local clone_unit_group_setting = 1

                    local max_num_unit_clones = 0
                    local max_num_unit_group_clones = 0

                    if (planet.string_val == Constants.DEFAULTS.planets.gleba.string_val) then
                        clone_unit_setting = _Settings_Service.get_runtime_global_setting({ setting = Mod_Settings.CLONE_GLEBA_UNITS.name, })
                        clone_unit_group_setting = _Settings_Service.get_runtime_global_setting({ setting = Mod_Settings.CLONE_GLEBA_UNIT_GROUPS.name, })

                        max_num_unit_clones = _Settings_Service.get_runtime_global_setting({ setting = Mod_Settings.MAXIMUM_NUMBER_OF_SPAWNED_CLONES_GLEBA.name, })
                        max_num_unit_group_clones = _Settings_Service.get_runtime_global_setting({ setting = Mod_Settings.MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES_GLEBA.name, })
                    else
                        clone_unit_setting = _Settings_Service.get_runtime_global_setting({ setting = Mod_Settings.CLONE_NAUVIS_UNITS.name, })
                        clone_unit_group_setting = _Settings_Service.get_runtime_global_setting({ setting = Mod_Settings.CLONE_NAUVIS_UNIT_GROUPS.name, })

                        max_num_unit_clones = _Settings_Service.get_runtime_global_setting({ setting = Mod_Settings.MAXIMUM_NUMBER_OF_SPAWNED_CLONES_NAUVIS.name, })
                        max_num_unit_group_clones = _Settings_Service.get_runtime_global_setting({ setting = Mod_Settings.MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES_NAUVIS.name, })
                    end

                    local clone_settings = {
                        unit = clone_unit_setting,
                        unit_group = clone_unit_group_setting,
                        type = group and "unit-group" or "unit"
                    }

                    -- local max_num_unit_clones = Settings_Service.get_maximum_number_of_spawned_clones(planet.string_val)
                    -- local max_num_unit_group_clones = Settings_Service.get_maximum_number_of_unit_group_clones(planet.string_val)

                    local at_capacity = 0

                    for _, _planet in pairs(Constants.DEFAULTS.planets) do
                        if (not more_enemies_data.clone[_planet.string_val]) then
                            more_enemies_data.clone[_planet.string_val] = {}
                            more_enemies_data.clone[_planet.string_val].unit = 0
                            more_enemies_data.clone[_planet.string_val].unit_group = 0
                        end

                        if (more_enemies_data.clone[_planet.string_val].unit_group > max_num_unit_group_clones) then
                            -- Log.warn("Tried to clone more than the unit-group limit: " .. serpent.block(max_num_unit_group_clones))
                            -- Log.warn("Currently " .. serpent.block(more_enemies_data.clone[_planet.string_val].unit) .. " unit clones")
                            -- Log.warn("Currently " .. serpent.block(more_enemies_data.clone[_planet.string_val].unit_group) .. " unit-group clones")

                            at_capacity = at_capacity + 1
                        end
                        if (more_enemies_data.clone[_planet.string_val].unit > max_num_unit_clones) then
                            -- Log.warn("Tried to clone more than the unit limit: " .. serpent.block(max_num_unit_clones))
                            -- Log.warn("Currently " .. serpent.block(more_enemies_data.clone[_planet.string_val].unit) .. " unit clones")
                            -- Log.warn("Currently " .. serpent.block(more_enemies_data.clone[_planet.string_val].unit_group) .. " unit-group clones")

                            at_capacity = at_capacity + 1
                        end
                    end

                    if (at_capacity > 2) then
                        if (at_capacity > 3) then
                            -- Log.warn("at capacity")
                            more_enemies_data.do_nth_tick = false
                            -- return
                            if (not group or not group.valid or not group.is_script_driven) then
                                -- Log.warn("at capacity - returning")
                                return
                            end
                        end

                        if (clone_settings and clone_settings.type == "unit-group") then
                            if (more_enemies_data.clone[planet.string_val].unit_group > max_num_unit_group_clones) then
                                -- Log.debug("unit_group: continuing")

                                -- goto continue
                                if (not group or not group.valid or not group.is_script_driven) then
                                    goto continue
                                end
                            end
                        else
                            if (more_enemies_data.clone[planet.string_val].unit > max_num_unit_clones) then
                                -- Log.debug("unit: continuing")
                                goto continue
                            end
                        end
                    end

                    clones = {}

                    -- Log.debug("Attempting to clone entity on planet " .. planet.string_val)
                    -- Log.debug(clone_settings)
                    --   log(serpent.block(more_enemies_data))
                    if (planet.string_val == Constants.DEFAULTS.planets.nauvis.string_val) then
                        clones = Spawn_Utils.clone_entity(
                            { value = Nauvis_Settings_Constants.settings.CLONE_NAUVIS_UNITS.default_value },
                            more_enemies_data.difficulties[planet.string_val].difficulty,
                            staged_clone,
                            {
                                clone_settings = clone_settings,
                                tick = tick
                            }
                        )
                    elseif (planet.string_val == Constants.DEFAULTS.planets.gleba.string_val) then
                        clones = Spawn_Utils.clone_entity(
                            { value = Gleba_Settings_Constants.settings.CLONE_GLEBA_UNITS.default_value },
                            more_enemies_data.difficulties[planet.string_val].difficulty,
                            staged_clone,
                            {
                                clone_settings = clone_settings,
                                tick = tick
                            }
                        )
                    else
                        -- Log.warn("Planet is neither nauvis nor gleba\nPlanet is unsupported; making no changes")
                        return
                    end

                    if (clones) then
                        j = j + #clones
                    end

                    -- Log.warn("clones:")
                    -- Log.warn(clones)

                    -- add the new clones to storage
                    if (clones and #clones > 0) then
                        if (not more_enemies_data.clones[planet.string_val]) then
                            more_enemies_data.clones[planet.string_val] = {}
                            more_enemies_data.clones[planet.string_val].unit = {}
                            more_enemies_data.clones[planet.string_val].unit_group = {}
                        end

                        -- local k
                        for k = 1, #clones do
                            if (clones[k] and clones[k] ~= nil and clones[k].clone.valid) then
                                -- Log.info("adding clone: " .. serpent.block(clones[k]))
                                local clone_data = Clone_Data:new({
                                    obj = clones[k].clone,
                                    type = clone_settings.type,
                                    mod_name = nil,
                                    valid = clones[k].clone.valid
                                })
                                if (clone_data.type == "unit-group") then
                                    more_enemies_data.clones[planet.string_val].unit_group[clones[k].clone.unit_number] = clone_data
                                else
                                    more_enemies_data.clones[planet.string_val].unit[clones[k].clone.unit_number] = clone_data
                                end
                            end

                            if (more_enemies_data.clone[planet.string_val].unit_group < 0) then more_enemies_data.clone[planet.string_val].unit_group = 0 end
                            if (more_enemies_data.clone[planet.string_val].unit < 0) then more_enemies_data.clone[planet.string_val].unit = 0 end

                            if (more_enemies_data.staged_clone[planet.string_val].unit_group < 0) then more_enemies_data.staged_clone[planet.string_val].unit_group = 0 end
                            if (more_enemies_data.staged_clone[planet.string_val].unit < 0) then more_enemies_data.staged_clone[planet.string_val].unit = 0 end

                            if (group and group.valid and clone_settings.type == "unit-group") then
                                group.add_member(clones[k].clone)
                                more_enemies_data.clone[planet.string_val].unit_group = more_enemies_data.clone[planet.string_val].unit_group + 1
                            else
                                more_enemies_data.clone[planet.string_val].unit = more_enemies_data.clone[planet.string_val].unit + 1
                            end

                            clones[k] = nil
                        end

                        if (group and group.valid) then
                            if (more_enemies_data.groups[group.surface.name]
                                    and more_enemies_data.groups[group.surface.name][group.unique_id]
                                    and more_enemies_data.groups[group.surface.name][group.unique_id].count ~= nil
                                    and more_enemies_data.groups[group.surface.name][group.unique_id].max_count ~= nil
                                    and more_enemies_data.groups[group.surface.name][group.unique_id].count >= more_enemies_data.groups[group.surface.name][group.unique_id].max_count)
                            then
                                -- Log.debug("removing group: " .. serpent.block(group))
                                more_enemies_data.groups[group.surface.name][group.unique_id] = nil
                            end
                        end
                    end
                end

                -- remove the staged_clone after processing
                if (group) then
                    -- Log.debug("9")
                    more_enemies_data.staged_clones[planet.string_val].unit_group[unit_number] = nil

                    if (more_enemies_data.staged_clone[planet.string_val].unit_group > 0) then
                        -- Log.debug("12")
                        more_enemies_data.staged_clone[planet.string_val].unit_group = more_enemies_data.staged_clone[planet.string_val].unit_group - 1
                    end
                else
                    -- Log.debug("10")
                    more_enemies_data.staged_clones[planet.string_val].unit[unit_number] = nil

                    -- Log.debug("11")
                    if (more_enemies_data.staged_clone[planet.string_val].unit > 0) then
                        -- Log.debug("12")
                        more_enemies_data.staged_clone[planet.string_val].unit = more_enemies_data.staged_clone[planet.string_val].unit - 1
                    end
                end
                ::continue::
                -- Log.debug("13")
            end
            ::continue_2::
            -- Log.debug("14")
        end

        if (BREAM_active) then
            if (not spawn_service.BREAM.last_ran) then spawn_service.BREAM.last_ran = game.tick end

            if (spawn_service.BREAM.last_ran + Settings_Service.get_nth_tick() * 1.5 < game.tick) then
                spawn_service.BREAM.last_ran = game.tick
                locals.do_mod_nth_tick(more_enemies_data, mod_data, planet)
            end
        end
    end

    return true
end

function spawn_service.do_nth_tick_cleanup(event, more_enemies_data)
  Log.warn("spawn_service.do_nth_tick_cleanup")
  Log.info(event)
  Log.info(more_enemies_data)

  more_enemies_data = more_enemies_data or More_Enemies_Repository.get_more_enemies_data()
--   if (not more_enemies_data.valid) then more_enemies_data = Initialization.reinit() end

  local _invalids = {}
  local i = 1
  local limit = 1.5 * Global_Settings_Constants.settings.CLONES_PER_TICK.default_value

  Log.warn("Starting iteration of staged_clones")
  for _, planet in pairs(Constants.DEFAULTS.planets) do

    if (not more_enemies_data.staged_clones[planet.string_val]) then more_enemies_data.staged_clones[planet.string_val] = {} end
    if (not more_enemies_data.staged_clones[planet.string_val].unit) then more_enemies_data.staged_clones[planet.string_val].unit = {} end
    if (not more_enemies_data.staged_clones[planet.string_val].unit_group) then more_enemies_data.staged_clones[planet.string_val].unit_group = {} end

    if (not more_enemies_data.staged_clone[planet.string_val]) then more_enemies_data.staged_clone[planet.string_val] = {} end
    if (more_enemies_data.staged_clone[planet.string_val].unit == nil) then more_enemies_data.staged_clone[planet.string_val].unit = 0 end
    if (more_enemies_data.staged_clone[planet.string_val].unit_group == nil) then more_enemies_data.staged_clone[planet.string_val].unit_group = 0 end

    if (not more_enemies_data.clones[planet.string_val]) then more_enemies_data.clones[planet.string_val] = {} end
    if (not more_enemies_data.clones[planet.string_val].unit) then more_enemies_data.clones[planet.string_val].unit = {} end
    if (not more_enemies_data.clones[planet.string_val].unit_group) then more_enemies_data.clones[planet.string_val].unit_group = {} end

    if (not more_enemies_data.clone[planet.string_val]) then more_enemies_data.clone[planet.string_val] = {} end
    if (more_enemies_data.clone[planet.string_val].unit == nil) then more_enemies_data.clone[planet.string_val].unit = 0 end
    if (more_enemies_data.clone[planet.string_val].unit_group == nil) then more_enemies_data.clone[planet.string_val].unit_group = 0 end

    Log.warn("staged_clones.unit")
    if (more_enemies_data.staged_clone[planet.string_val].unit <= Settings_Service.get_maximum_number_of_spawned_clones(planet.string_val)) then
      more_enemies_data.staged_clone[planet.string_val].unit = table_size(more_enemies_data.staged_clones[planet.string_val].unit)
    end

    i = 1
    for k,v in pairs(more_enemies_data.staged_clones[planet.string_val].unit) do
      Log.info(v)
      -- TODO: Come back to this; seems to be erroneously detecting valid objects as invalid
      if (not v or not v.obj or not v.obj.valid or v.obj == planet.string_val) then
        Log.warn("Found nil or invalid clone")
        Log.warn(v)
        _invalids[k] = v
      end
      i = i + 1
      if (i > limit) then
        Log.warn("breaking from initial step of cleanup")
        break
      end
    end

    i = 1
    Log.warn("Starting iteration of _invalids")
    for k,v in pairs(_invalids) do
      Log.warn("Removing invalids")
      table.remove(more_enemies_data.staged_clones[planet.string_val].unit, k)
      if (more_enemies_data.staged_clone[planet.string_val].unit > 0) then more_enemies_data.staged_clone[planet.string_val].unit = more_enemies_data.staged_clone[planet.string_val].unit - 1 end

      i = i + 1
      if (i > limit) then
        Log.warn("breaking from second step of cleanup")
        break
      end
    end

    Log.warn("staged_clones.unit_group")
    if (more_enemies_data.staged_clone[planet.string_val].unit_group <= Settings_Service.get_maximum_number_of_unit_group_clones(planet.string_val)) then
      more_enemies_data.staged_clone[planet.string_val].unit_group = table_size(more_enemies_data.staged_clones[planet.string_val].unit_group)
    end

    i = 1
    _invalids = {}
    for k,v in pairs(more_enemies_data.staged_clones[planet.string_val].unit_group) do
      -- Log.warn(v)
      -- TODO: Come back to this; seems to be erroneously detecting valid objects as invalid
      if (not v or not v.obj or not v.obj.valid or v.obj == planet.string_val) then
        Log.warn("Found nil or invalid clone")
        _invalids[k] = v
      end
      i = i + 1
      if (i > limit) then
        Log.warn("breaking from initial step of cleanup")
        break
      end
    end

    i = 1
    Log.warn("Starting iteration of _invalids")
    for k,v in pairs(_invalids) do
      Log.warn("Removing invalids")
      table.remove(more_enemies_data.staged_clones[planet.string_val].unit_group, k)
      if (more_enemies_data.staged_clone[planet.string_val].unit_group > 0) then more_enemies_data.staged_clone[planet.string_val].unit_group = more_enemies_data.staged_clone[planet.string_val].unit_group - 1 end

      i = i + 1
      if (i > limit) then
        Log.warn("breaking from second step of cleanup")
        break
      end
    end

    Log.warn("clones.unit")
    if (more_enemies_data.clone[planet.string_val].unit <= Settings_Service.get_maximum_number_of_spawned_clones(planet.string_val)) then
      more_enemies_data.clone[planet.string_val].unit = table_size(more_enemies_data.clones[planet.string_val].unit)
    end

    i = 1
    _invalids = {}
    for k,v in pairs(more_enemies_data.clones[planet.string_val].unit) do
      -- Log.warn(v)
      -- if (not v or not v.obj or not v.obj.valid or v.obj == planet.string_val) then
      if (not v or not v.obj or not v.obj.valid) then
        Log.warn("Found nil or invalid clone")
        _invalids[k] = v
      end
      i = i + 1
      if (i > limit) then
        Log.warn("breaking from initial step of cleanup")
        break
      end
    end

    i = 1
    Log.warn("Starting iteration of _invalids")
    for k,v in pairs(_invalids) do
      Log.warn("Removing invalids")
      more_enemies_data.clones[planet.string_val].unit[k] = nil

      if (more_enemies_data.clone[planet.string_val].unit > 0) then
        more_enemies_data.clone[planet.string_val].unit = more_enemies_data.clone[planet.string_val].unit - 1
      end

      i = i + 1
      if (i > limit) then
        Log.warn("breaking from second step of cleanup")
        break
      end
    end

    Log.warn("clones.unit_group")
    if (more_enemies_data.clone[planet.string_val].unit_group <= Settings_Service.get_maximum_number_of_unit_group_clones(planet.string_val)) then
      more_enemies_data.clone[planet.string_val].unit_group = table_size(more_enemies_data.clones[planet.string_val].unit_group)
    end

    i = 1
    _invalids = {}
    for k,v in pairs(more_enemies_data.clones[planet.string_val].unit_group) do
      -- Log.warn(v)
      -- TODO: Come back to this; seems to be erroneously detecting valid objects as invalid
      -- if (not v or not v.obj or not v.obj.valid or v.obj == planet.string_val) then
      if (not v or not v.obj or not v.obj.valid) then
        Log.warn("Found nil or invalid clone")
        _invalids[k] = v
      end
      i = i + 1
      if (i > limit) then
        Log.warn("breaking from initial step of cleanup")
        break
      end
    end

    i = 1
    Log.warn("Starting iteration of _invalids")
    for k,v in pairs(_invalids) do
      Log.warn("Removing invalids")
      more_enemies_data.clones[planet.string_val].unit_group[k] = nil

      if (more_enemies_data.clone[planet.string_val].unit_group > 0) then
        more_enemies_data.clone[planet.string_val].unit_group = more_enemies_data.clone[planet.string_val].unit_group - 1
      end

      i = i + 1
      if (i > limit) then
        Log.warn("breaking from second step of cleanup")
        break
      end
    end

    if (BREAM_active) then
      local mod_data = Mod_Repository.get_mod_data()

      if (not mod_data) then return end
      if (not mod_data.clone) then mod_data.clone = {} end
      if (not mod_data.clone[planet.string_val]) then mod_data.clone[planet.string_val] = {} end
      if (mod_data.clone[planet.string_val].count == nil) then mod_data.clone[planet.string_val].count = 0 end

      Log.warn("mod_data.clones")
      -- if (mod_data.clone[planet.string_val].unit_group <= Settings_Service.get_maximum_number_of_unit_group_clones(planet.string_val)) then
      --   more_enemies_data.clone[planet.string_val].unit_group = table_size(more_enemies_data.clones[planet.string_val].unit_group)
      -- end

      i = 1
      _invalids = {}
      for k,v in pairs(mod_data.clones[planet.string_val].unit_group) do
        -- Log.warn(v)
        -- TODO: Come back to this; seems to be erroneously detecting valid objects as invalid
        -- if (not v or not v.obj or not v.obj.valid or v.obj == planet.string_val) then
        if (not v or not v.obj or not v.obj.valid) then
          Log.warn("Found nil or invalid clone")
          _invalids[k] = v
        end
        i = i + 1
        if (i > limit) then
          Log.warn("breaking from initial step of cleanup")
          break
        end
      end

      i = 1
      Log.warn("Starting iteration of _invalids")
      for k,v in pairs(_invalids) do
        Log.warn("Removing invalids")
        more_enemies_data.clones[planet.string_val].unit_group[k] = nil

        if (mod_data.clone[planet.string_val].count > 0) then
          mod_data.clone[planet.string_val].count = mod_data.clone[planet.string_val].count - 1
        end

        i = i + 1
        if (i > limit) then
          Log.warn("breaking from second step of cleanup")
          break
        end
      end
    end
  end

  return true
end

function spawn_service.entity_died(event)
    Log.debug("spawn_service.entity_died")
    Log.info(event)

    local entity = event.entity
    if (not entity or not entity.valid) then return end
    local surface = entity.surface
    if (not surface or not surface.valid or not surface.name) then return end

    local valid_planet = false
    for _, planet in pairs(Constants.DEFAULTS.planets) do
        if (planet.string_val == surface.name) then
            valid_planet = true
            break
        end
    end

    if (not valid_planet) then return end

    -- local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()
    storage.more_enemies = storage.more_enemies or More_Enemies_Repository.get_more_enemies_data()
    local more_enemies_data = storage.more_enemies
    -- if (not more_enemies_data.valid) then more_enemies_data = Initialization.reinit() end
    -- if (not cache.more_enemies or not cache_attributes[cache.more_enemies] or cache_attributes[cache.more_enemies].time_to_live < game.tick) then
    --     local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()
    --     if (not more_enemies_data or not more_enemies_data.valid) then return end
    --     cache.more_enemies = { data = more_enemies_data, }
    --     cache_attributes[cache.more_enemies] = Data:new({ time_to_live = game.tick + 1234 + Random(1800)})
    -- end
    -- local more_enemies_data = cache.more_enemies.data

    -- local mod_data = Mod_Repository.get_mod_data()
    storage.more_enemies = storage.more_enemies or Initialization.reinit()
    if (not storage.more_enemies) then return end
    storage.more_enemies.mod_data = storage.more_enemies.mod_data or Mod_Repository.get_mod_data()
    local mod_data = storage.more_enemies.mod_data

    if (not mod_data.clones) then mod_data.clones = {} end
    if (not mod_data.clones[surface.name]) then mod_data.clones[surface.name] = {} end
    if (not mod_data.clones[surface.name].unit) then mod_data.clones[surface.name].unit = {} end
    if (not mod_data.clones[surface.name].unit_group) then mod_data.clones[surface.name].unit_group = {} end

    if (not more_enemies_data.clone) then more_enemies_data.clone = {} end
    if (not more_enemies_data.clone[surface.name]) then more_enemies_data.clone[surface.name] = {} end
    if (more_enemies_data.clone[surface.name] == nil) then more_enemies_data.clone[surface.name].unit = 0 end
    if (more_enemies_data.clone[surface.name] == nil) then more_enemies_data.clone[surface.name].unit_group = 0 end

    if (more_enemies_data.clone[surface.name].unit_group < 0) then more_enemies_data.clone[surface.name].unit_group = 0 end
    if (more_enemies_data.clone[surface.name].unit < 0) then more_enemies_data.clone[surface.name].unit = 0 end

    if (not mod_data.clone) then mod_data.clone = {} end
    if (not mod_data.clone[surface.name]) then mod_data.clone[surface.name] = {} end
    if (mod_data.clone[surface.name].count == nil) then mod_data.clone[surface.name].count = 0 end

    if (not more_enemies_data.clones) then more_enemies_data.clones = {} end
    if (not more_enemies_data.clones[surface.name]) then more_enemies_data.clones[surface.name] = {} end
    if (not more_enemies_data.clones[surface.name].unit) then more_enemies_data.clones[surface.name].unit = {} end
    if (not more_enemies_data.clones[surface.name].unit_group) then more_enemies_data.clones[surface.name].unit = {} end

    Log.info("Attempting to remove entity")

    if (not entity or not entity.valid) then return end

    if (   more_enemies_data.clones[surface.name].unit[entity.unit_number] ~= nil
        or more_enemies_data.clones[surface.name].unit_group[entity.unit_number] ~= nil
        or mod_data.clones[surface.name].unit[entity.unit_number] ~= nil
        or mod_data.clones[surface.name].unit_group[entity.unit_number] ~= nil
    ) then
        Log.debug("Removing entity: " .. serpent.block(entity.unit_number))

        if (   mod_data.clones[surface.name].unit[entity.unit_number]
            or mod_data.clones[surface.name].unit_group[entity.unit_number]
        ) then
            if (mod_data.clone[surface.name].count > 0) then mod_data.clone[surface.name].count = mod_data.clone[surface.name].count - 1 end

            if (mod_data.clones[surface.name].unit[entity.unit_number]) then
                mod_data.clones[surface.name].unit[entity.unit_number] = nil
            elseif (mod_data.clones[surface.name].unit_group[entity.unit_number]) then
                mod_data.clones[surface.name].unit_group[entity.unit_number] = nil
            end
        else
            if (more_enemies_data.clones[surface.name].unit_group[entity.unit_number]) then
                if (more_enemies_data.clone[surface.name].unit_group > 0) then more_enemies_data.clone[surface.name].unit_group = more_enemies_data.clone[surface.name].unit_group - 1 end
            elseif (more_enemies_data.clones[surface.name].unit[entity.unit_number]) then
                if (more_enemies_data.clone[surface.name].unit > 0) then more_enemies_data.clone[surface.name].unit = more_enemies_data.clone[surface.name].unit - 1 end
            end

            if (more_enemies_data.clones[surface.name].unit[entity.unit_number]) then
                more_enemies_data.clones[surface.name].unit[entity.unit_number] = nil
            elseif (more_enemies_data.clones[surface.name].unit_group[entity.unit_number]) then
                more_enemies_data.clones[surface.name].unit_group[entity.unit_number] = nil
            end
        end

        return
    end

    Log.info("Attempting to remove entity again")
    if (    entity
        and (more_enemies_data.clone[surface.name].unit > 0 or more_enemies_data.clone[surface.name].unit_group > 0)
        and (  more_enemies_data.clones[surface.name].unit[entity.unit_number]
            or more_enemies_data.clones[surface.name].unit_group[entity.unit_number]
        )
    ) then
        Log.debug("removing, second try")

        if (   mod_data.clones[surface.name].unit[entity.unit_number]
            or mod_data.clones[surface.name].unit_group[entity.unit_number]
        ) then
            if (mod_data.clone[surface.name].count > 0) then mod_data.clone[surface.name].count = mod_data.clone[surface.name].count - 1 end

            if (mod_data.clones[surface.name].unit[entity.unit_number]) then
                mod_data.clones[surface.name].unit[entity.unit_number] = nil
            elseif (mod_data.clones[surface.name].unit_group[entity.unit_number]) then
                mod_data.clones[surface.name].unit_group[entity.unit_number] = nil
            end
        else
            if (more_enemies_data.clones[surface.name].unit_group[entity.unit_number]) then
                if (more_enemies_data.clone[surface.name].unit_group > 0) then more_enemies_data.clone[surface.name].unit_group = more_enemies_data.clone[surface.name].unit_group - 1 end
            elseif (more_enemies_data.clones[surface.name].unit[entity.unit_number]) then
                if (more_enemies_data.clone[surface.name].unit > 0) then more_enemies_data.clone[surface.name].unit = more_enemies_data.clone[surface.name].unit - 1 end
            end

            if (more_enemies_data.clones[surface.name].unit[entity.unit_number]) then
                more_enemies_data.clones[surface.name].unit[entity.unit_number] = nil
            elseif (more_enemies_data.clones[surface.name].unit_group[entity.unit_number]) then
                more_enemies_data.clones[surface.name].unit_group[entity.unit_number] = nil
            end
        end

        return
    end

    if (    entity
        and mod_data.clone[surface.name].count > 0
        and (  mod_data.clones[surface.name].unit[entity.unit_number] ~= nil
            or mod_data.clones[surface.name].unit_group[entity.unit_number] ~= nil
        )
    ) then
        Log.debug("mod removing, second try")

        if (mod_data.clones[surface.name].unit[entity.unit_number]
                or mod_data.clones[surface.name].unit_group[entity.unit_number])
        then
            if (mod_data.clone[surface.name].count > 0) then mod_data.clone[surface.name].count = mod_data.clone[surface.name].count - 1 end

            if (mod_data.clones[surface.name].unit[entity.unit_number]) then
                mod_data.clones[surface.name].unit[entity.unit_number] = nil
            elseif (mod_data.clones[surface.name].unit_group[entity.unit_number]) then
                mod_data.clones[surface.name].unit_group[entity.unit_number] = nil
            end
        else
            if (more_enemies_data.clones[surface.name].unit_group[entity.unit_number]) then
                if (more_enemies_data.clone[surface.name].unit_group > 0) then more_enemies_data.clone[surface.name].unit_group = more_enemies_data.clone[surface.name].unit_group - 1 end
            elseif (more_enemies_data.clones[surface.name].unit[entity.unit_number]) then
                if (more_enemies_data.clone[surface.name].unit > 0) then more_enemies_data.clone[surface.name].unit = more_enemies_data.clone[surface.name].unit - 1 end
            end

            if (more_enemies_data.clones[surface.name].unit[entity.unit_number]) then
                more_enemies_data.clones[surface.name].unit[entity.unit_number] = nil
            elseif (more_enemies_data.clones[surface.name].unit_group[entity.unit_number]) then
                more_enemies_data.clones[surface.name].unit_group[entity.unit_number] = nil
            end
        end

        return
    end

    Log.debug("failed to remove")
end

function spawn_service.entity_spawned(event)
    Log.debug("spawn_service.entity_spawned")
    Log.info(event)

    -- local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()
    storage.more_enemies = storage.more_enemies or More_Enemies_Repository.get_more_enemies_data()
    local more_enemies_data = storage.more_enemies

    local spawner = event.spawner
    if (not spawner or not spawner.valid) then return end
    local entity = event.entity
    if (not entity or not entity.valid) then return end
    local surface = entity.surface
    if (not surface or not surface.valid or not surface.name) then return end

    -- if (not more_enemies_data.valid) then more_enemies_data = Initialization.reinit() end
    if (not more_enemies_data.do_nth_tick) then return end
    if (not entity or not entity.valid or not entity.surface or not entity.surface.valid or Settings_Utils.is_vanilla(entity.surface.name)) then return end

    local max_num_clones = Settings_Service.get_maximum_number_of_spawned_clones(surface.name)

    if (not more_enemies_data.clone[surface.name]) then
        more_enemies_data.clone[surface.name] = {}
        more_enemies_data.clone[surface.name].unit = 0
        more_enemies_data.clone[surface.name].unit_group = 0
    end

    if (more_enemies_data.clone[surface.name].unit > max_num_clones) then
        Log.warn("Tried to clone more than the unit limit: " .. serpent.block(max_num_clones))
        Log.warn("Currently " .. serpent.block(more_enemies_data.clone[surface.name].unit) .. " unit clones")
        return
    end

    if (not spawner or not spawner.valid) then return end
    if (not entity or not entity.valid) then return end
    if (not entity.surface or not entity.surface.name) then return end

    Log.info("Attempting to add to staged_clones")
    if (more_enemies_data.valid) then
        Log.debug("Adding to staged_clones: " .. serpent.block(entity.unit_number))

        if (not more_enemies_data.staged_clones) then more_enemies_data.staged_clones = {} end
        if (not more_enemies_data.staged_clones[entity.surface.name]) then more_enemies_data.staged_clones[entity.surface.name] = {} end
        if (not more_enemies_data.staged_clones[entity.surface.name].unit) then more_enemies_data.staged_clones[entity.surface.name].unit = {} end

        if (not more_enemies_data.staged_clone[entity.surface.name]) then more_enemies_data.staged_clone[entity.surface.name] = {} end
        if (not more_enemies_data.staged_clone[entity.surface.name].unit) then more_enemies_data.staged_clone[entity.surface.name].unit = 0 end

        if (more_enemies_data.staged_clone[entity.surface.name].unit == 0) then
            local exists = next(more_enemies_data.staged_clones[entity.surface.name].unit, nil)
            if (exists) then
                more_enemies_data.staged_clone[entity.surface.name].unit = table_size(more_enemies_data.staged_clones
                [entity.surface.name].unit)
            end
        end

        if (more_enemies_data.staged_clone[entity.surface.name].unit <= max_num_clones) then
            more_enemies_data.staged_clone[entity.surface.name].unit = table_size(more_enemies_data.staged_clones
            [entity.surface.name].unit)
        end
        if (more_enemies_data.staged_clone[entity.surface.name].unit > max_num_clones) then
            Log.info("27")
            return
        end

        Log.info("Adding to staged_clones[" .. entity.surface.name .. "].unit")

        more_enemies_data.staged_clone[entity.surface.name].unit = more_enemies_data.staged_clone[entity.surface.name]
        .unit + 1

        more_enemies_data.staged_clones[entity.surface.name].unit[entity.unit_number] = Clone_Data:new({
            obj = entity,
            surface = entity.surface,
            group = nil,
            mod_name = nil,
            valid = entity.valid and entity.surface.valid
        })
    end
end

function spawn_service.entity_built(event)
  Log.info(event)

  local mod_name = event.mod_name
  local entity = event.entity
--   local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()
  storage.more_enemies = storage.more_enemies or More_Enemies_Repository.get_more_enemies_data()
  local more_enemies_data = storage.more_enemies

  if (not mod_name or mod_name ~= "BREAM") then return end

--   if (not more_enemies_data.valid) then more_enemies_data = Initialization.reinit() end
  if (not more_enemies_data.do_nth_tick) then return end
  if (not entity or not entity.valid or not entity.surface or not entity.surface.valid or not entity.surface.name or Settings_Utils.is_vanilla(entity.surface.name)) then return end

  local mod_data = Mod_Repository.get_mod_data()

  local max_num_modded_clones = Settings_Service.get_maximum_number_of_modded_clones()

  if (not mod_data.clone) then mod_data.clone = {} end
  if (not mod_data.clone[entity.surface.name]) then mod_data.clone[entity.surface.name] = {} end
  if (mod_data.clone[entity.surface.name].count == nil) then mod_data.clone[entity.surface.name].count = 0 end

  if (not mod_data.staged_clone) then mod_data.staged_clone = {} end
  if (not mod_data.staged_clone[entity.surface.name]) then mod_data.staged_clone[entity.surface.name] = {} end
  if (mod_data.staged_clone[entity.surface.name].count == nil) then mod_data.staged_clone[entity.surface.name].count = 0 end

  if (mod_data.clone[entity.surface.name]
    and mod_data.clone[entity.surface.name].count
    and mod_data.clone[entity.surface.name].count > max_num_modded_clones)
  then
    Log.warn("Tried to clone more than the mod unit limit: " .. serpent.block(max_num_modded_clones))
    Log.warn("Currently " .. serpent.block(mod_data.clone[entity.surface.name].count) .. " clones")
    return
  end

  if (mod_data.staged_clone[entity.surface.name]
    and mod_data.staged_clone[entity.surface.name].count
    and mod_data.staged_clone[entity.surface.name].count > max_num_modded_clones)
  then
    Log.warn("Tried to clone more than the mod unit limit: " .. serpent.block(max_num_modded_clones))
    Log.warn("Currently " .. serpent.block(mod_data.staged_clone[entity.surface.name].count) .. " staged clones")
    return
  end

--   if (not more_enemies_data.valid) then more_enemies_data = Initialization.reinit() end

  Log.info("Attempting to add to staged_clones")
  if (more_enemies_data.valid) then
    Log.debug("entity_built - Adding to mod.staged_clones: " .. serpent.block(entity.unit_number))

    if (not mod_data.staged_clones) then mod_data.staged_clones = {} end
    if (not mod_data.staged_clones[entity.surface.name]) then mod_data.staged_clones[entity.surface.name] = {} end

    mod_data.staged_clones[entity.surface.name][entity.unit_number] = Clone_Data:new({
      obj = entity,
      surface = entity.surface,
      group = nil,
      mod_name = mod_name,
      valid = entity.valid and entity.surface.valid,
    })

    mod_data.staged_clone[entity.surface.name].count = table_size(mod_data.staged_clones[entity.surface.name])
  end
end

locals.do_mod_nth_tick = function (more_enemies_data, mod_data, planet)
  Log.debug("locals.do_mod_nth_tick")

  if (not mod_data.clone[planet.string_val]) then mod_data.clone[planet.string_val] = {} end
  if (mod_data.clone[planet.string_val].count == nil) then mod_data.clone[planet.string_val].count = 0 end

  local difficulty_setting = Settings_Service.get_BREAM_difficulty()

  if (  difficulty_setting == Constants.difficulty.VANILLA.string_val
     or Settings_Service.get_BREAM_do_clone() == false)
  then
    Log.debug("found Vanilla settings for BREAM; returning")
    return
  end

  local unit_group = spawn_service.BREAM.unit_group
  Log.info(unit_group)
  local skip = false
  local max_num_modded_clones = Settings_Service.get_maximum_number_of_modded_clones()

  Log.info(difficulty_setting)
  local difficulty =
  {
    selected_difficulty = Constants.difficulty[Constants.difficulty.difficulties[difficulty_setting]],
    valid = true
  }
  Log.info(difficulty)
  Log.info(Constants.difficulty)

  if (mod_data.staged_clones[planet.string_val] and not spawn_service.BREAM.clones_index) then
    for i, _staged_clone in pairs(mod_data.staged_clones[planet.string_val]) do
      local staged_clone = _staged_clone.obj
      local mod_name = _staged_clone.mod_name

      spawn_service.BREAM.clones_index = i

      if (not unit_group) then
        if (mod_name and mod_name == BREAM_Constants.name) then
          if (staged_clone and staged_clone.valid) then
            if (not spawn_service.BREAM.unit_group) then
              Log.debug("creating unit group from: " .. serpent.block(staged_clone))
              spawn_service.BREAM.unit_group = staged_clone.surface.create_unit_group({ position = staged_clone.position, force = "enemy" })
            end
          end
        end
      end
      break
    end
  end

  unit_group = spawn_service.BREAM.unit_group
  Log.info(unit_group)
  local j = 0
  local clones_per_tick = Settings_Service.get_clones_per_tick()

  if (not mod_data.staged_clones) then mod_data.staged_clones = {} end
  if (not mod_data.staged_clones[spawn_service.BREAM.clones_index]) then spawn_service.BREAM.clones_index = nil end

  local unit_number = 1

  if (not mod_data.staged_clones[planet.string_val]) then mod_data.staged_clones[planet.string_val] = {} end

  for _unit_number, _mod_staged_clone in pairs(mod_data.staged_clones[planet.string_val]) do
    skip = false

    -- Log.info(i)
    Log.info(_mod_staged_clone)
    unit_number = _unit_number
    local mod_stage_clone = _mod_staged_clone.obj
    local surface_name = Constants.DEFAULTS.planets.nauvis.string_val
    local mod_name = nil

    j = j + 1

    if (j > clones_per_tick / 1.5) then
      Log.warn("Tried to clone more than the clone_per_tick limit; breaking inner loop")
      return
    end

    if (not mod_stage_clone or not mod_stage_clone.valid or mod_stage_clone.surface.name ~= planet.string_val) then
      Log.warn("mod_stage_clone is nil, invalid, or wrong planet for clone; skipping")
      skip = true
    else
      surface_name = mod_stage_clone.surface.name
      mod_name = _mod_staged_clone.mod_name
    end

    if (not skip) then
      if (mod_data.clone[surface_name].count > max_num_modded_clones) then
        Log.warn("Tried to clone more than the mod unit limit: " .. serpent.block(max_num_modded_clones))
        Log.warn("Currently " .. serpent.block(more_enemies_data.clone[surface_name].unit) .. " unit clones")
        return
      end

      Log.info(surface_name)
      local bream_clone_units_setting = Settings_Service.get_BREAM_clone_units(surface_name)
      Log.info("clone_unit_setting: " .. serpent.block(clone_unit_setting))
      Log.info("clone_unit_group_setting: " .. serpent.block(clone_unit_group_setting))

      local clone_settings = {
        unit = bream_clone_units_setting,
        unit_group = bream_clone_units_setting,
        type = unit_group and "unit-group" or "unit",
      }

      local clones = {}

      Log.debug("mod added: Attempting to clone entity on planet " .. surface_name)
      Log.info(clone_settings)
      if (surface_name == Constants.DEFAULTS.planets.nauvis.string_val) then
        clones = Spawn_Utils.clone_entity(
          {
            value = Nauvis_Settings_Constants.settings.CLONE_NAUVIS_UNITS.default_value
          },
          difficulty,
          mod_stage_clone,
          {
            clone_settings = clone_settings,
            tick = tick,
            mod_name = mod_name,
            surface = surface_name,
          }
        )
      elseif (surface_name == Constants.DEFAULTS.planets.gleba.string_val) then
        clones = Spawn_Utils.clone_entity(
          {
            value = Gleba_Settings_Constants.settings.CLONE_GLEBA_UNITS.default_value
          },
          difficulty,
          mod_stage_clone,
          {
            clone_settings = clone_settings,
            tick = tick,
            mod_name = mod_name,
            surface = surface_name,
          }
        )
      else
        Log.warn("Planet is neither nauvis nor gleba\nPlanet is unsupported; making no changes")
        return
      end

      if (clones) then
        j = j + #clones
      end

      Log.info("clones = " .. serpent.block(clones))

      -- add the new clones to storage
      if (clones and #clones > 0) then
        if (mod_name and mod_name == BREAM_Constants.name) then
          if (unit_group and unit_group.valid) then

            Log.info("Getting selected_difficulty")
            local selected_difficulty = difficulty.selected_difficulty
            if (not selected_difficulty) then return end

            local clone_unit_group_setting = Settings_Service.get_clone_unit_group_setting(unit_group.surface.name)

            Log.info("adding unit_group: " .. serpent.block(unit_group))

            Log.info(unit_group.surface.name)

            Log.info("before: " .. serpent.block(more_enemies_data.groups))

            if (not more_enemies_data.groups[unit_group.surface.name]) then
              more_enemies_data.groups[unit_group.surface.name] = {}
            end

            Log.info("after: " .. serpent.block(more_enemies_data.groups))

            local loop_len = 1
            local use_evolution_factor = Settings_Service.get_BREAM_use_evolution_factor(unit_group.surface.name)
            local evolution_factor = 1

            Log.info("use_evolution_factor = "  .. serpent.block(use_evolution_factor))
            if (use_evolution_factor) then
            --   evolution_factor = unit_group.force.get_evolution_factor()
              evolution_factor = unit_group.force.get_evolution_factor(unit_group.surface)
            end

            if (selected_difficulty.value > 1) then
              loop_len = math.floor((selected_difficulty.value + clone_unit_group_setting) * evolution_factor)
            else
              loop_len = math.floor((selected_difficulty.value * clone_unit_group_setting) * evolution_factor)
            end
            Log.info("loop_len: " .. serpent.block(loop_len))

            if (not more_enemies_data.groups[unit_group.surface.name]) then more_enemies_data.groups[unit_group.surface.name] = {} end

            more_enemies_data.groups[unit_group.surface.name][unit_group.unique_id] = Unit_Group_Data:new({
              valid = true,
              group = unit_group,
              count = 0,
              max_count = loop_len,
              mod_name = BREAM_Constants.name,
            })
          end
        end

        if (not mod_data.clones) then
          mod_data.clones = {}
        end
        if (not mod_data.clones[surface_name]) then
          mod_data.clones[surface_name] = {}
          mod_data.clones[surface_name].unit = {}
          mod_data.clones[surface_name].unit_group = {}
        end

        for k=1, #clones do
          if (clones[k] and clones[k] ~= nil and clones[k].clone.valid) then
            Log.debug("adding clone: " .. serpent.block(clones[k]))
            local clone_data = Clone_Data:new({
              obj = clones[k].clone,
              type = unit_group and "unit-group" or "unit",
              mod_name = clones[k].mod_name,
              surface = clones[k].clone.surface,
              valid = clones[k].clone.valid
            })
            if (unit_group) then
              mod_data.clones[surface_name].unit_group[clones[k].clone.unit_number] = clone_data
            else
              mod_data.clones[surface_name].unit[clones[k].clone.unit_number] = clone_data
            end
          end

          if (unit_group and unit_group.valid and unit_group.surface.name == clones[k].clone.surface.name) then
            Log.debug("adding to unit_group")
            unit_group.add_member(clones[k].clone)
          end

          clones[k] = nil

          mod_data.clone[surface_name].count = mod_data.clone[surface_name].count + 1
        end
      end

      if (not mod_data.clone[surface_name]) then mod_data.clone[surface_name] = {} end
      if (mod_data.clone[surface_name].count == nil) then mod_data.clone[surface_name].count = 0 end

      Log.info("unit_group: " .. table_size(mod_data.clones[surface_name].unit_group))
      Log.info("unit: " .. table_size(mod_data.clones[surface_name].unit))

      mod_data.clone[surface_name].count = table_size(mod_data.clones[surface_name].unit_group) + table_size(mod_data.clones[surface_name].unit)
    end

    if (unit_number) then
      if (unit_number == 1) then
        unit_number = next(mod_data.staged_clones[surface_name], nil)
      end

      if (unit_number and mod_data.staged_clones[surface_name][unit_number]) then mod_data.staged_clones[surface_name][unit_number] = nil end
    end
    if (mod_data.staged_clone[surface_name].count and mod_data.staged_clone[surface_name].count > 0) then mod_data.staged_clone[surface_name].count = table_size(mod_data.staged_clones[surface_name]) end
  end

  Log.debug("before unit_group")

  if (unit_group and unit_group.valid) then
    local target_entity = unit_group.surface.find_nearest_enemy({
      position = unit_group.position,
      max_distance = 111111, -- TODO: Make this configurable
      force = "enemy"
    })

    Log.debug("target_entity")
    Log.info(target_entity)

    if (target_entity) then
      unit_group.set_command({
        type = defines.command.attack_area,
        destination = target_entity.position,
        radius = 1111, -- TODO: Make this configurable
      })
      Log.debug("releasing from spawner")
      unit_group.release_from_spawner()
      Log.debug("start moving")
      unit_group.start_moving()
    else
      Log.warn("no target; destroying")
      unit_group.destroy()
    end

    if (not more_enemies_data.groups[unit_group.surface.name]) then more_enemies_data.groups[unit_group.surface.name] = {} end

    -- remove the unit_group after processing
    spawn_service.BREAM.unit_group = nil
    more_enemies_data.groups[unit_group.surface.name][unit_group.unique_id] = nil
  end

  Log.debug("after unit_group")
end

function spawn_service.init(__storage)
    storage = __storage
end

return spawn_service