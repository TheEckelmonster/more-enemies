local Data = require("scripts.data.data")
local Bug_Fix_Data = require("scripts.data.versions.bug-fix-data")
local Major_Data = require("scripts.data.versions.major-data")
local Minor_Data = require("scripts.data.versions.minor-data")
local Log = require("libs.log.log")

-- local version_data = Data:new()
local version_data = {}
-- version_data.__concat = version_data.to_string
local Version_Data = {}

version_data.major = Major_Data:new()
version_data.major.value = 0
version_data.major.valid = true
version_data.minor = Minor_Data:new()
version_data.minor.value = 7
version_data.minor.valid = true
version_data.bug_fix = Bug_Fix_Data:new()
version_data.bug_fix.value = 3
version_data.bug_fix.valid = true

version_data.string_val = version_data.major.value .. "." .. version_data.minor.value .. "." .. version_data.bug_fix.value

function version_data:new(o)
    Log.debug("version_data:new")
    Log.info(o)

    local defaults = {
        major = self.major,
        minor = self.minor,
        bug_fix = self.bug_fix,
        string_val = self.string_val,
    }

    local obj = o or defaults

    for k, v in pairs(defaults) do if (obj[k] == nil and type(v) ~= "function") then obj[k] = v end end

    obj = Data:new(obj)

    setmetatable(version_data, Data)
    setmetatable(obj, self)
    self.__index = self

    obj.valid = false

    return obj
end

function version_data:get_major()
    return self.major
end

function version_data:set_major(obj)
    self.major = obj
end

function version_data:get_minor()
    return self.minor
end

function version_data:set_minor(obj)
    self.minor = obj
end

function version_data:get_bug_fix()
    return self.bug_fix
end

function version_data:set_bug_fix(obj)
    self.bug_fix = obj
end

function version_data.__concat()
    Log.debug("__concat:to_string")
    -- Log.error(self.string_val)
    return self.string_val
    -- return self.major.value .. "." .. self.minor.value .. "." .. self.bug_fix.value
end

function version_data:to_string()
    Log.debug("version_data:to_string")
    -- Log.error(self.string_val)
    return self.string_val
    -- return self.major.value .. "." .. self.minor.value .. "." .. self.bug_fix.value
end

-- version_data = version_data:new(version_data)
Version_Data = version_data:new(Version_Data)

-- return version_data
return Version_Data