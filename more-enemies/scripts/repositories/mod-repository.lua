local storage

local Log = require("libs.log.log")
local Mod_Data = require("scripts.data.mod-data")
local More_Enemies_Data = require("scripts.data.more-enemies-data")

local mod_repository = {}

function mod_repository.save_mod_data(optionals)
  Log.debug("mod_repository.save_mod_data")
  Log.info(optionals)

  local return_val = Mod_Data:new()

  if (not game) then return return_val end

  optionals = optionals or {}

  if (not storage) then return return_val end
  if (not storage.more_enemies) then storage.more_enemies = More_Enemies_Data:new() end
  if (not storage.more_enemies.mod) then storage.more_enemies.mod = return_val end

  return_val = storage.more_enemies.mod
  return_val.created = return_val.created or game.tick

  return mod_repository.update_mod_data(return_val)
end

function mod_repository.update_mod_data(update_data, optionals)
  Log.debug("mod_repository.update_mod_data")
  Log.info(update_data)
  Log.info(optionals)

  local return_val = Mod_Data:new()

  if (not game) then return return_val end
  if (not update_data) then return return_val end

  optionals = optionals or {}

  if (not storage) then return return_val end
  if (not storage.more_enemies) then storage.more_enemies = More_Enemies_Data:new() end
  if (not storage.more_enemies.mod) then
    -- If it doesn't exist, generate it
    storage.more_enemies.mod = return_val
    mod_repository.save_mod_data()
  end

  local mod_data = storage.more_enemies.mod

  for k, v in pairs(update_data) do
    mod_data[k] = v
  end

  mod_data.updated = game.tick

  -- Don't think this is necessary, but oh well
  storage.more_enemies.mod = mod_data

  return mod_data
end

function mod_repository.get_mod_data(optionals)
  Log.debug("mod_repository.get_mod_data")
  Log.info(optionals)

  local return_val = Mod_Data:new()

  if (not game) then return return_val end

  optionals = optionals or {}

  if (not storage) then return return_val end
  if (not storage.more_enemies) then storage.more_enemies = More_Enemies_Data:new() end
  if (not storage.more_enemies.mod) then
    -- If it doesn't exist, generate it
    storage.more_enemies.mod = return_val
    mod_repository.save_mod_data()
  end

  return storage.more_enemies.mod
end

function mod_repository.init(__storage)
    storage = __storage
end

return mod_repository