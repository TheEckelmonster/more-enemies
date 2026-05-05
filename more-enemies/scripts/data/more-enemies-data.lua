local Attack_Group_Data = require("scripts.data.attack-group-data")
local Data = require("scripts.data.data")
local Log = require("libs.log.log")
local Mod_Data = require("scripts.data.mod-data")
local Nth_Tick_Data = require("scripts.data.nth-tick-data")
local Version_Data = require("scripts.data.version-data")
-- local Version_Service = require("scripts.service.version-service")

-- local more_enemies_data = Data:new()
local more_enemies_data = {}
local More_Enemies_Data = {
    mt = more_enemies_data
}

more_enemies_data.name = "more_enemies_data"
more_enemies_data.type = "more_enemies_data"

more_enemies_data.attack_group = {}

more_enemies_data.clones = {}
more_enemies_data.clone = {}

more_enemies_data.difficulties = {}

more_enemies_data.do_nth_tick = false

more_enemies_data.groups = {}

more_enemies_data.mod = Mod_Data:new()

more_enemies_data.nth_tick_cleanup_complete = Nth_Tick_Data:new()
more_enemies_data.nth_tick_cleanup_complete.valid = true

more_enemies_data.nth_tick_complete = Nth_Tick_Data:new()
more_enemies_data.nth_tick_complete.valid = true

more_enemies_data.staged_clone = {}
more_enemies_data.staged_clones = {}

more_enemies_data.valid = false

more_enemies_data.version_data = Version_Data:new()

function more_enemies_data:new(o)
    Log.debug("more_enemies_data:new")
    -- Log.error("more_enemies_data:new", true)
    Log.info(o)

    -- obj = Data:new(obj) or Data:new()

    local defaults = {
        name = self.name,
        type = self.type,
        attack_group = {},
        clones = self.clones,
        clone = self.clone,
        difficulties = self.difficulties,
        do_nth_tick = self.do_nth_tick,
        groups = self.groups,
        nth_tick_cleanup_complete = self.nth_tick_cleanup_complete,
        nth_tick_complete = self.nth_tick_complete,
        mod = self.mod,
        staged_clone = self.staged_clone,
        staged_clones = self.staged_clones,
        version_data = self.version_data,
    }

    local obj = o or defaults

    for k, v in pairs(defaults) do if (obj[k] == nil and type(v) ~= "function") then obj[k] = v end end

    obj = Data:new(obj)

    setmetatable(more_enemies_data, Data)
    setmetatable(obj, self)
    self.__index = self

    obj.valid = obj:is_valid()

    return obj
end

function more_enemies_data:is_valid()
    Log.debug("more_enemies_data:is_valid")
    -- Log.error("more_enemies_data:is_valid")

    if (not self.valid) then return false end
    if (self.version_data:to_string() ~= (Version_Data:new()):to_string()) then return false end
    -- if (Version_Data.to_string(self.version_data) ~= (Version_Data:new()):to_string()) then return false end
    -- if (not Version_Service.validate_version().valid) then return false end

    return true
end

More_Enemies_Data = more_enemies_data:new(More_Enemies_Data)

-- return more_enemies_data
return More_Enemies_Data