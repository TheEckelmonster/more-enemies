-- If already defined, return
if (_difficulty_utils and _difficulty_utils.more_enemies) then
  return _difficulty_utils
end

local Armoured_Biters_Constants = require("libs.constants.mods.armoured-biters-constants")
local Cold_Biters_Constants = require("libs.constants.mods.cold-biters-constants")
local Constants = require("libs.constants.constants")
local Easy_Difficulty_Data = require("scripts.data.difficulties.easy-difficulty-data")
local Explosive_Biters_Constants = require("libs.constants.mods.explosive-biters-constants")
local Gleba_Constants = require("libs.constants.gleba-constants")
local Hard_Difficulty_Data = require("scripts.data.difficulties.hard-difficulty-data")
local Insanity_Difficulty_Data = require("scripts.data.difficulties.insanity-difficulty-data")
local Log = require("libs.log.log")
local More_Enemies_Data = require("scripts.data.more-enemies-data")
local More_Enemies_Repository = require("scripts.repositories.more-enemies-repository")
local Nauvis_Constants = require("libs.constants.nauvis-constants")
local Proto_Biters_Constants = require("libs.constants.mods.proto-biters-constants")
local Settings_Service = require("scripts.service.settings-service")
local Toxic_Biters_Constants = require("libs.constants.mods.toxic-biters-constants")
local Vanilla_Plus_Difficulty_Data = require("scripts.data.difficulties.vanilla-plus-difficulty-data")
local Vanilla_Difficulty_Data = require("scripts.data.difficulties.vanilla-difficulty-data")

local locals = {}

local difficulty_utils = {}

function difficulty_utils.get_difficulty(planet, reindex)
    Log.debug("difficulty_utils.get_difficulty")
    Log.info(planet)
    Log.info(reindex)

  local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()

  reindex = reindex or false

  Log.debug(reindex)
  -- if (storage) then Log.info(storage.more_enemies.difficulties) end

  if (  not reindex
    and planet
    and storage
    and more_enemies_data
    and more_enemies_data.difficulties
    and more_enemies_data.difficulties[planet]
    and more_enemies_data.difficulties[planet].valid)
  then
    -- While it may exist, check if it's still valid
    local planet_difficulty_setting = Settings_Service.get_difficulty(planet)
    -- Log.info(planet_difficulty_setting)
    -- log(serpent.block(planet_difficulty_setting))
    -- Log.info(storage.more_enemies.difficulties)

    if ( not more_enemies_data.difficulties
      or not more_enemies_data.difficulties[planet]
      or not more_enemies_data.difficulties[planet].difficulty
      or not more_enemies_data.difficulties[planet].difficulty.selected_difficulty
      or not more_enemies_data.difficulties[planet].difficulty.selected_difficulty.valid
      or     more_enemies_data.difficulties[planet].difficulty.selected_difficulty.string_val ~= planet_difficulty_setting)
    then
      Log.debug("reindexing")
      return difficulty_utils.get_difficulty(planet, true)
    else
      return more_enemies_data.difficulties[planet]
    end
  end

  local difficulty = {
    valid = false
  }

  if (  planet == "gleba"
    and ((mods and not mods["space-age"]) or (script and script.active_mods and not script.active_mods["space-age"])))
  then
    Log.warn("planet invalid")
    return difficulty
  end

  if (storage and not more_enemies_data) then more_enemies_data = More_Enemies_Data:new() end
  if (storage and not more_enemies_data.difficulties) then more_enemies_data.difficulties = {} end

  Log.info(planet)
  if (not planet or planet == "") then
    Log.warn("planet invalid")
    return difficulty
  end

  if (storage and more_enemies_data.difficulties and not more_enemies_data.difficulties[planet]) then more_enemies_data.difficulties[planet] = difficulty end

  local planet_difficulty = Settings_Service.get_difficulty(planet)
  Log.info(planet_difficulty)

  local selected_difficulty = Constants.difficulty[Constants.difficulty.difficulties[planet_difficulty]]
  Log.info(selected_difficulty)

  if (selected_difficulty and selected_difficulty.valid) then
    if (reindex) then
      difficulty = locals.init_difficulty(planet, selected_difficulty)
    else
      difficulty = locals.set_difficulty(planet, selected_difficulty)
    end
  else
    difficulty = locals.init_difficulty(planet)
  end

  Log.info(difficulty)

  -- If storage difficulty for the planet is invalid, replace it
  if (  storage
    and more_enemies_data
    and more_enemies_data.difficulties
    and more_enemies_data.difficulties[planet]
    and not more_enemies_data.difficulties[planet].valid)
  then
    more_enemies_data.difficulties[planet] = difficulty
  end

  return difficulty
end

function locals.set_difficulty(planet, difficulty_setting)
  local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()

  difficulty_setting = difficulty_setting or Vanilla_Difficulty_Data:new()
  planet = planet or "nauvis"

  local difficulty = {
    valid = false
  }

  -- local modifier = 1
  -- local cooldown_modifier = 1
  local vanilla = false
  local selected_difficulty = nil

  -- Determine difficulty
  if (difficulty_setting == Easy_Difficulty_Data.string_val or difficulty_setting == Easy_Difficulty_Data.value) then
    selected_difficulty = Easy_Difficulty_Data:new()
  elseif (difficulty_setting == Vanilla_Difficulty_Data.string_val or difficulty_setting == Vanilla_Difficulty_Data.value) then
    vanilla = true
    selected_difficulty = Vanilla_Difficulty_Data:new()
  elseif (difficulty_setting == Vanilla_Plus_Difficulty_Data.string_val or difficulty_setting == Vanilla_Plus_Difficulty_Data.value) then
    selected_difficulty = Vanilla_Plus_Difficulty_Data:new()
  elseif (difficulty_setting == Hard_Difficulty_Data.string_val or difficulty_setting == Hard_Difficulty_Data.value) then
    selected_difficulty = Hard_Difficulty_Data:new()
  elseif (difficulty_setting == Insanity_Difficulty_Data.string_val or difficulty_setting == Insanity_Difficulty_Data.value) then
    selected_difficulty = Insanity_Difficulty_Data:new()
  else
    Log.error("No difficulty detected")
  end

  difficulty = locals.create_difficulty(planet, selected_difficulty, vanilla)

  if (storage) then
    if (not more_enemies_data.difficulties) then more_enemies_data.difficulties = {} end
    if (not more_enemies_data.difficulties[planet]) then more_enemies_data.difficulties[planet] = {} end
    more_enemies_data.difficulties[planet].difficulty = difficulty
  end

  Log.info(difficulty)

  return difficulty
end

function locals.init_difficulty(planet, difficulty_setting)
  local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()

  difficulty_setting = difficulty_setting or Vanilla_Difficulty_Data:new()
  planet = planet or "nauvis"

  local difficulty = {
    valid = false
  }

  if (not planet) then
    Log.warn("planet invalid")
    return difficulty
  end

  difficulty = locals.create_difficulty(planet, difficulty_setting)

  if (storage) then
    if (not more_enemies_data.difficulties) then more_enemies_data.difficulties = More_Enemies_Data:new() end
    if (not more_enemies_data.difficulties[planet]) then more_enemies_data.difficulties[planet] = {} end
    more_enemies_data.difficulties[planet].difficulty = difficulty
  end

  return difficulty
end

function locals.create_difficulty(planet, selected_difficulty, vanilla)
  Log.debug("create_difficulty")
  Log.info(planet)
  Log.info(selected_difficulty)
  Log.info(vanilla)

  local modifier = modifier or 1
  if (modifier < 0) then modifier = 0 end
  local cooldown_modifier = cooldown_modifier or 1
  if (cooldown_modifier <= 0) then cooldown_modifier = 0.000001 end

  local difficulty = {
    valid = false
  }

  if (selected_difficulty and selected_difficulty.valid) then
    modifier = selected_difficulty.value
    cooldown_modifier = selected_difficulty.value
  end

  if (selected_difficulty and selected_difficulty.valid and modifier >= 0 and cooldown_modifier > 0) then
    if (planet == Constants.DEFAULTS.planets.nauvis.string_val) then

      difficulty = {
        valid = true,
        selected_difficulty = selected_difficulty,
        biter = {
          max_count_of_owned_units = vanilla and Nauvis_Constants.nauvis.biter.MAX_COUNT_OF_OWNED_UNITS or (Nauvis_Constants.nauvis.biter.MAX_COUNT_OF_OWNED_UNITS * modifier) + 1,
          max_count_of_owned_defensive_units = vanilla and Nauvis_Constants.nauvis.biter.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS or (Nauvis_Constants.nauvis.biter.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS * modifier) + 1,
          max_friends_around_to_spawn = vanilla and Nauvis_Constants.nauvis.biter.MAX_FRIENDS_AROUND_TO_SPAWN or (Nauvis_Constants.nauvis.biter.MAX_FRIENDS_AROUND_TO_SPAWN * modifier) + 1,
          max_defensive_friends_around_to_spawn = vanilla and Nauvis_Constants.nauvis.biter.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN or (Nauvis_Constants.nauvis.biter.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN * modifier) + 1,
          spawning_cooldown = {
            max = 360 / cooldown_modifier,
            min = 150 / cooldown_modifier
          },
        },
        spitter = {
          max_count_of_owned_units = vanilla and Nauvis_Constants.nauvis.spitter.MAX_COUNT_OF_OWNED_UNITS or (Nauvis_Constants.nauvis.spitter.MAX_COUNT_OF_OWNED_UNITS * modifier) + 1,
          max_count_of_owned_defensive_units = vanilla and Nauvis_Constants.nauvis.spitter.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS or (Nauvis_Constants.nauvis.spitter.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS * modifier) + 1,
          max_friends_around_to_spawn = vanilla and Nauvis_Constants.nauvis.spitter.MAX_FRIENDS_AROUND_TO_SPAWN or (Nauvis_Constants.nauvis.spitter.MAX_FRIENDS_AROUND_TO_SPAWN * modifier) + 1,
          max_defensive_friends_around_to_spawn = vanilla and Nauvis_Constants.nauvis.spitter.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN or (Nauvis_Constants.nauvis.spitter.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN * modifier) + 1,
          spawning_cooldown = {
            max = 360 / cooldown_modifier,
            min = 150 / cooldown_modifier
          }
        }
      }

      if ( (script and script.active_mods and script.active_mods["ArmouredBiters"])
        or (mods and mods["ArmouredBiters"]))
      then
        difficulty.biter_armoured = {
          max_count_of_owned_units = vanilla and Armoured_Biters_Constants.nauvis.biter_armoured.MAX_COUNT_OF_OWNED_UNITS or (Armoured_Biters_Constants.nauvis.biter_armoured.MAX_COUNT_OF_OWNED_UNITS * modifier) + 1,
          max_count_of_owned_defensive_units = vanilla and Armoured_Biters_Constants.nauvis.biter_armoured.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS or (Armoured_Biters_Constants.nauvis.biter_armoured.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS * modifier) + 1,
          max_friends_around_to_spawn = vanilla and Armoured_Biters_Constants.nauvis.biter_armoured.MAX_FRIENDS_AROUND_TO_SPAWN or (Armoured_Biters_Constants.nauvis.biter_armoured.MAX_FRIENDS_AROUND_TO_SPAWN * modifier) + 1,
          max_defensive_friends_around_to_spawn = vanilla and Armoured_Biters_Constants.nauvis.biter_armoured.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN or (Armoured_Biters_Constants.nauvis.biter_armoured.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN * modifier) + 1,
          spawning_cooldown = {
            max = Armoured_Biters_Constants.nauvis.biter_armoured.MAX_SPAWNING_COOLDOWN / cooldown_modifier,
            min = Armoured_Biters_Constants.nauvis.biter_armoured.MIN_SPAWNING_COOLDOWN / cooldown_modifier
          },
        }
      end

      if ( (script and script.active_mods and script.active_mods["Cold_biters"])
        or (mods and mods["Cold_biters"]))
      then
          difficulty.biter_cold = {
              max_count_of_owned_units = vanilla and Cold_Biters_Constants.nauvis.biter_cold.MAX_COUNT_OF_OWNED_UNITS or (Cold_Biters_Constants.nauvis.biter_cold.MAX_COUNT_OF_OWNED_UNITS * modifier) + 1,
              max_count_of_owned_defensive_units = vanilla and Cold_Biters_Constants.nauvis.biter_cold.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS or (Cold_Biters_Constants.nauvis.biter_cold.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS * modifier) + 1,
              max_friends_around_to_spawn = vanilla and Cold_Biters_Constants.nauvis.biter_cold.MAX_FRIENDS_AROUND_TO_SPAWN or (Cold_Biters_Constants.nauvis.biter_cold.MAX_FRIENDS_AROUND_TO_SPAWN * modifier) + 1,
              max_defensive_friends_around_to_spawn = vanilla and Cold_Biters_Constants.nauvis.biter_cold.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN or (Cold_Biters_Constants.nauvis.biter_cold.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN * modifier) + 1,
              spawning_cooldown = {
                  max = Cold_Biters_Constants.nauvis.biter_cold.MAX_SPAWNING_COOLDOWN / cooldown_modifier,
                  min = Cold_Biters_Constants.nauvis.biter_cold.MIN_SPAWNING_COOLDOWN / cooldown_modifier
              },
          }
      end

      if ( (script and script.active_mods and script.active_mods["Explosive_biters"])
        or (mods and mods["Explosive_biters"]))
      then
          difficulty.biter_explosive = {
              max_count_of_owned_units = vanilla and Explosive_Biters_Constants.nauvis.biter_explosive.MAX_COUNT_OF_OWNED_UNITS or (Explosive_Biters_Constants.nauvis.biter_explosive.MAX_COUNT_OF_OWNED_UNITS * modifier) + 1,
              max_count_of_owned_defensive_units = vanilla and Explosive_Biters_Constants.nauvis.biter_explosive.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS or (Explosive_Biters_Constants.nauvis.biter_explosive.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS * modifier) + 1,
              max_friends_around_to_spawn = vanilla and Explosive_Biters_Constants.nauvis.biter_explosive.MAX_FRIENDS_AROUND_TO_SPAWN or (Explosive_Biters_Constants.nauvis.biter_explosive.MAX_FRIENDS_AROUND_TO_SPAWN * modifier) + 1,
              max_defensive_friends_around_to_spawn = vanilla and Explosive_Biters_Constants.nauvis.biter_explosive.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN or (Explosive_Biters_Constants.nauvis.biter_explosive.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN * modifier) + 1,
              spawning_cooldown = {
                  max = Explosive_Biters_Constants.nauvis.biter_explosive.MAX_SPAWNING_COOLDOWN / cooldown_modifier,
                  min = Explosive_Biters_Constants.nauvis.biter_explosive.MIN_SPAWNING_COOLDOWN / cooldown_modifier
              },
          }
      end

      if ( (script and script.active_mods and script.active_mods["Toxic_biters"])
        or (mods and mods["Toxic_biters"]))
      then
          difficulty.biter_toxic = {
              max_count_of_owned_units = vanilla and Toxic_Biters_Constants.nauvis.biter_toxic.MAX_COUNT_OF_OWNED_UNITS or (Toxic_Biters_Constants.nauvis.biter_toxic.MAX_COUNT_OF_OWNED_UNITS * modifier) + 1,
              max_count_of_owned_defensive_units = vanilla and Toxic_Biters_Constants.nauvis.biter_toxic.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS or (Toxic_Biters_Constants.nauvis.biter_toxic.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS * modifier) + 1,
              max_friends_around_to_spawn = vanilla and Toxic_Biters_Constants.nauvis.biter_toxic.MAX_FRIENDS_AROUND_TO_SPAWN or (Toxic_Biters_Constants.nauvis.biter_toxic.MAX_FRIENDS_AROUND_TO_SPAWN * modifier) + 1,
              max_defensive_friends_around_to_spawn = vanilla and Toxic_Biters_Constants.nauvis.biter_toxic.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN or (Toxic_Biters_Constants.nauvis.biter_toxic.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN * modifier) + 1,
              spawning_cooldown = {
                  max = Toxic_Biters_Constants.nauvis.biter_toxic.MAX_SPAWNING_COOLDOWN / cooldown_modifier,
                  min = Toxic_Biters_Constants.nauvis.biter_toxic.MIN_SPAWNING_COOLDOWN / cooldown_modifier
              },
          }
      end

      if ( (script and script.active_mods and script.active_mods["old_biters_remastered"])
        or (mods and mods["old_biters_remastered"]))
      then
          difficulty.biter_old = {
              max_count_of_owned_units = vanilla and Proto_Biters_Constants.nauvis.biter_old.MAX_COUNT_OF_OWNED_UNITS or (Proto_Biters_Constants.nauvis.biter_old.MAX_COUNT_OF_OWNED_UNITS * modifier) + 1,
              max_count_of_owned_defensive_units = vanilla and Proto_Biters_Constants.nauvis.biter_old.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS or (Proto_Biters_Constants.nauvis.biter_old.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS * modifier) + 1,
              max_friends_around_to_spawn = vanilla and Proto_Biters_Constants.nauvis.biter_old.MAX_FRIENDS_AROUND_TO_SPAWN or (Proto_Biters_Constants.nauvis.biter_old.MAX_FRIENDS_AROUND_TO_SPAWN * modifier) + 1,
              max_defensive_friends_around_to_spawn = vanilla and Proto_Biters_Constants.nauvis.biter_old.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN or (Proto_Biters_Constants.nauvis.biter_old.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN * modifier) + 1,
              spawning_cooldown = {
                  max = Proto_Biters_Constants.nauvis.biter_old.MAX_SPAWNING_COOLDOWN / cooldown_modifier,
                  min = Proto_Biters_Constants.nauvis.biter_old.MIN_SPAWNING_COOLDOWN / cooldown_modifier
              },
          }

          difficulty.spitter_old = {
              max_count_of_owned_units = vanilla and Proto_Biters_Constants.nauvis.spitter_old.MAX_COUNT_OF_OWNED_UNITS or (Proto_Biters_Constants.nauvis.spitter_old.MAX_COUNT_OF_OWNED_UNITS * modifier) + 1,
              max_count_of_owned_defensive_units = vanilla and Proto_Biters_Constants.nauvis.spitter_old.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS or (Proto_Biters_Constants.nauvis.spitter_old.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS * modifier) + 1,
              max_friends_around_to_spawn = vanilla and Proto_Biters_Constants.nauvis.spitter_old.MAX_FRIENDS_AROUND_TO_SPAWN or (Proto_Biters_Constants.nauvis.spitter_old.MAX_FRIENDS_AROUND_TO_SPAWN * modifier) + 1,
              max_defensive_friends_around_to_spawn = vanilla and Proto_Biters_Constants.nauvis.spitter_old.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN or (Proto_Biters_Constants.nauvis.spitter_old.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN * modifier) + 1,
              spawning_cooldown = {
                  max = Proto_Biters_Constants.nauvis.spitter_old.MAX_SPAWNING_COOLDOWN / cooldown_modifier,
                  min = Proto_Biters_Constants.nauvis.spitter_old.MIN_SPAWNING_COOLDOWN / cooldown_modifier
              },
          }
      end

    elseif (planet == Constants.DEFAULTS.planets.gleba.string_val) then
      difficulty = {
        valid = true,
        selected_difficulty = selected_difficulty,
        small = {
          max_count_of_owned_units = vanilla and Gleba_Constants.gleba.small.MAX_COUNT_OF_OWNED_UNITS or (Gleba_Constants.gleba.small.MAX_COUNT_OF_OWNED_UNITS * modifier) + 1,
          max_count_of_owned_defensive_units = vanilla and Gleba_Constants.gleba.small.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS or (Gleba_Constants.gleba.small.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS * modifier) + 1,
          max_friends_around_to_spawn = vanilla and Gleba_Constants.gleba.small.MAX_FRIENDS_AROUND_TO_SPAWN or (Gleba_Constants.gleba.small.MAX_FRIENDS_AROUND_TO_SPAWN * modifier) + 1,
          max_defensive_friends_around_to_spawn = vanilla and Gleba_Constants.gleba.small.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN or (Gleba_Constants.gleba.small.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN * modifier) + 1,
          spawning_cooldown = {
            max = 360 / cooldown_modifier,
            min = 150 / cooldown_modifier
          },
        },
        regular = {
          max_count_of_owned_units = vanilla and Gleba_Constants.gleba.regular.MAX_COUNT_OF_OWNED_UNITS or (Gleba_Constants.gleba.regular.MAX_COUNT_OF_OWNED_UNITS * modifier) + 1,
          max_count_of_owned_defensive_units = vanilla and Gleba_Constants.gleba.regular.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS or (Gleba_Constants.gleba.regular.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS * modifier) + 1,
          max_friends_around_to_spawn = vanilla and Gleba_Constants.gleba.regular.MAX_FRIENDS_AROUND_TO_SPAWN or (Gleba_Constants.gleba.regular.MAX_FRIENDS_AROUND_TO_SPAWN * modifier) + 1,
          max_defensive_friends_around_to_spawn = vanilla and Gleba_Constants.gleba.regular.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN or (Gleba_Constants.gleba.regular.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN * modifier) + 1,
          spawning_cooldown = {
            max = 360 / cooldown_modifier,
            min = 150 / cooldown_modifier
          }
        }
      }
    end
  elseif (not selected_difficulty) then
    Log.error("selected difficulty is nil")
    Log.error("defaulting to vanilla")
    difficulty.selected_difficulty = Vanilla_Difficulty_Data:new()
  elseif (not selected_difficulty.valid) then
    Log.warn("selected_difficulty is not valid")
    -- If (attempt fixes)
    Log.error("defaulting to vanilla")
    difficulty.selected_difficulty = Vanilla_Difficulty_Data:new()
  end

  Log.info("returning difficulty: " .. serpent.block(difficulty))
  return difficulty
end

difficulty_utils.more_enemies = true

local _difficulty_utils = difficulty_utils

return difficulty_utils