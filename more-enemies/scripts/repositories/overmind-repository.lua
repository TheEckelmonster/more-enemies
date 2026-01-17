-- If already defined, return
if _overmind_repository and _overmind_repository.more_enemies then
  return _overmind_repository
end

local Overmind_Data = require("scripts.data.overmind-data")
local Log = require("libs.log.log")
local More_Enemies_Data = require("scripts.data.more-enemies-data")

local overmind_repository = {}

function overmind_repository.save_overmind_data(surface_name, optionals)
    Log.debug("overmind_repository.save_overmind_data")
    Log.info(optionals)

    local return_val = Overmind_Data:new()

    if (not game) then return return_val end
    if (not surface_name) then return return_val end

    optionals = optionals or {}

    if (not game.surfaces or not game.surfaces[surface_name]) then return return_val end
    local surface = game.surfaces[surface_name]
    if (not surface or not surface.valid) then return return_val end

    if (not storage) then return return_val end
    if (not storage.more_enemies) then storage.more_enemies = More_Enemies_Data:new() end
    if (not storage.more_enemies.overmind) then storage.more_enemies.overmind = {} end
    -- if (not storage.more_enemies.overmind[surface_name]) then storage.more_enemies.overmind[surface_name] = return_val end
    storage.more_enemies.overmind[surface_name] = return_val
    -- return_val = storage.more_enemies.overmind[surface_name]

    return_val.created = return_val.created or game.tick

    return_val.surface = surface
    return_val.surface_name = surface_name

    return overmind_repository.update_overmind_data(return_val)
end

function overmind_repository.update_overmind_data(update_data, optionals)
  Log.debug("overmind_repository.update_overmind_data")
  Log.info(update_data)
  Log.info(optionals)

  local return_val = Overmind_Data:new()

  if (not game) then return return_val end
  if (not update_data) then return return_val end
  if (not update_data.surface or not update_data.surface.valid) then return return_val end

  optionals = optionals or {}

  local surface_name = update_data.surface.name
  if (not surface_name) then return return_val end

  if (not storage) then return return_val end
  if (not storage.more_enemies) then storage.more_enemies = More_Enemies_Data:new() end
  if (not storage.more_enemies.overmind) then storage.more_enemies.overmind = {} end
  if (not storage.more_enemies.overmind[surface_name]) then
    -- If it doesn't exist, generate it
    storage.more_enemies.overmind[surface_name] = return_val
    overmind_repository.save_overmind_data(surface_name)
  end

  local overmind_data = storage.more_enemies.overmind[surface_name]

  for k, v in pairs(update_data) do
    overmind_data[k] = v
  end

  overmind_data.updated = game.tick

  -- Don't think this is necessary, but oh well
  storage.more_enemies.overmind[surface_name] = overmind_data

  return overmind_data
end

function overmind_repository.get_overmind_data(surface_name, optionals)
  Log.debug("overmind_repository.get_overmind_data")
  Log.info(optionals)

  local return_val = Overmind_Data:new()

  if (not game) then return return_val end
  if (type(surface_name) ~= "string") then return return_val end

  optionals = optionals or {}

  if (not storage) then return return_val end
  if (not storage.more_enemies) then storage.more_enemies = More_Enemies_Data:new() end
  if (not storage.more_enemies.overmind) then storage.more_enemies.overmind = {} end
  if (not storage.more_enemies.overmind[surface_name]) then
    -- If it doesn't exist, generate it
    storage.more_enemies.overmind[surface_name] = return_val
    overmind_repository.save_overmind_data(surface_name)
  end

  return storage.more_enemies.overmind[surface_name]
end

overmind_repository.more_enemies = true

local _overmind_repository = overmind_repository

return overmind_repository