local storage

local Attack_Group_Data = require("scripts.data.attack-group-data")
local Log = require("libs.log.log")
local More_Enemies_Data = require("scripts.data.more-enemies-data")

local attack_group_repository = {}

function attack_group_repository.save_attack_group_data(surface_name, optionals)
    Log.debug("attack_group_repository.save_attack_group_data")
    Log.info(optionals)

    local return_val = Attack_Group_Data:new()

    if (not game) then return return_val end
    if (not surface_name) then return return_val end

    optionals = optionals or {}

    if (not game.surfaces or not game.surfaces[surface_name]) then return return_val end
    local surface = game.surfaces[surface_name]
    if (not surface or not surface.valid) then return return_val end

    if (not storage) then return return_val end
    if (not storage.more_enemies) then storage.more_enemies = More_Enemies_Data:new() end
    if (not storage.more_enemies.attack_group) then storage.more_enemies.attack_group = {} end
    if (not storage.more_enemies.attack_group[surface_name]) then storage.more_enemies.attack_group[surface_name] = return_val end

    return_val = storage.more_enemies.attack_group[surface_name]
    return_val.created = return_val.created or game.tick

    return_val.surface = surface
    return_val.surface_name = surface_name

    return attack_group_repository.update_attack_group_data(return_val)
end

function attack_group_repository.update_attack_group_data(update_data, optionals)
  Log.debug("attack_group_repository.update_attack_group_data")
  Log.info(update_data)
  Log.info(optionals)

  local return_val = Attack_Group_Data:new()

  if (not game) then return return_val end
  if (not update_data) then return return_val end
  if (not update_data.surface or not update_data.surface.valid) then return return_val end

  optionals = optionals or {}

  local surface_name = update_data.surface.name
  if (not surface_name) then return return_val end

  if (not storage) then return return_val end
  if (not storage.more_enemies) then storage.more_enemies = More_Enemies_Data:new() end
  if (not storage.more_enemies.attack_group) then storage.more_enemies.attack_group = {} end
  if (not storage.more_enemies.attack_group[surface_name]) then
    -- If it doesn't exist, generate it
    storage.more_enemies.attack_group[surface_name] = return_val
    attack_group_repository.save_attack_group_data(surface_name)
  end

  local attack_group_data = storage.more_enemies.attack_group[surface_name]

  for k, v in pairs(update_data) do
    attack_group_data[k] = v
  end

  attack_group_data.updated = game.tick

  -- Don't think this is necessary, but oh well
  storage.more_enemies.attack_group[surface_name] = attack_group_data

  return attack_group_data
end

function attack_group_repository.get_attack_group_data(surface_name, optionals)
  Log.debug("attack_group_repository.get_attack_group_data")
  Log.info(optionals)

  local return_val = Attack_Group_Data:new()

  if (not game) then return return_val end

  optionals = optionals or {}

  if (not storage) then return return_val end
  if (not storage.more_enemies) then storage.more_enemies = More_Enemies_Data:new() end
  if (not storage.more_enemies.attack_group) then storage.more_enemies.attack_group = {} end
  if (not storage.more_enemies.attack_group[surface_name]) then
    -- If it doesn't exist, generate it
    storage.more_enemies.attack_group[surface_name] = return_val
    attack_group_repository.save_attack_group_data(surface_name)
  end

  return storage.more_enemies.attack_group[surface_name]
end

function attack_group_repository.init(__storage)
    storage = __storage
end

return attack_group_repository