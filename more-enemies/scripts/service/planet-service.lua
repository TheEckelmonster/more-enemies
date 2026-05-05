local storage

local Attack_Group_Repository = require("scripts.repositories.attack-group-repository")
local Constants = require("libs.constants.constants")
local Log = require("libs.log.log")
local Settings_Service = require("scripts.service.settings-service")

local planet_service = {}

function planet_service.on_surface_created(event)
  Log.debug("planet_service.on_surface_created")
  Log.info(event)

  if (not game) then return end
  if (not event) then return end
  if (not event.surface_index or event.surface_index < 1) then return end

  local surface = game.get_surface(event.surface_index)
  if (not surface or not surface.valid) then return end

  local planets = Constants.DEFAULTS.planets
  local valid_planet = false
  for _, v in pairs(planets) do
    if (type(v) == "table" and type(v.string_val) == "string" and v.string_val == surface.name) then
        valid_planet = true
        break
    end
  end

  if (valid_planet) then
    local attack_group_data = Attack_Group_Repository.get_attack_group_data(surface.name)
    if (type(attack_group_data) == "table") then
        local peace_time_tick = Settings_Service.get_attack_group_peace_time(surface.name) * Constants.time.TICKS_PER_MINUTE
        attack_group_data.peace_time_tick = peace_time_tick
        attack_group_data.tick = game.tick + peace_time_tick
    end
  end
end

function planet_service.init(__storage)
    storage = __storage
end

return planet_service