-- If already defined, return
if (_version_validations and _version_validations.more_enemies) then
  return _version_validations
end

local Initialization = require("scripts.initialization")
local Log = require("libs.log.log")
local Version_Data = require("scripts.data.version-data")
local Version_Service = require("scripts.service.version-service")
local Version_Repository = require("scripts.repositories.version-repository")

local version_validations = {}

function version_validations.validate_version()
  local return_val = true

  local version = Version_Service.validate_version()
  local validate_fun = function ()
    Log.error("more-enemies: Invalid version detected relative to version " .. Version_Data:to_string() .. "; reinitializing naively")
    Initialization.reinit()
    local return_val = true
    if (not Version_Service.validate_version().valid) then
      local version_data = Version_Repository.get_version_data()
      return_val = false
      Log.error("more-enemies: invalid version detected relative to version " .. Version_Data.string_val .. "; naive reinitialization failed")
      if (version_data.string_val) then
        game.print("more-enemies: Version (" .. Version_Data.string_val ..") is invalid relative to current installed version: (" .. version_data.string_val .. ")")
      else
        game.print("more-enemies: Version is invalid relative to current installed version: (" .. Version_Data.string_val .. ")")
      end
      game.print("more-enemies: If this error persists, recommend executing command /more_enemies.init")
    end
    return return_val
  end -- local validate_fun = function ()

  if ( not version.valid) then
    return_val = validate_fun()
  end

  return return_val
end

version_validations.more_enemies = true

local _version_validations = version_validations
return version_validations