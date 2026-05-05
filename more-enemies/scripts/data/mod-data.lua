local Data = require("scripts.data.data")
local Log = require("libs.log.log")

-- local mod_data = Data:new()
local mod_data = {}
local Mod_Data = {
    mt = mod_data
}

mod_data.clone = {}
mod_data.clones = {}
mod_data.staged_clone = {}
mod_data.staged_clones = {}

function mod_data:new(o)
    Log.debug("mod_data:new")
    Log.info(o)

    local defaults = {
        clone = self.clone,
        clones = self.clones,
        staged_clone = self.staged_clone,
        staged_clones = self.staged_clones,
    }

    local obj = o or defaults

    for k, v in pairs(defaults) do if (obj[k] == nil and type(v) ~= "function") then obj[k] = v end end

    obj = Data:new(obj)

    setmetatable(mod_data, Data)
    setmetatable(obj, self)
    self.__index = self

    return obj
end

Mod_Data = mod_data:new(Mod_Data)

return mod_data