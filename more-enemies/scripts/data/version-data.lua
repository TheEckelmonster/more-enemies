local Data = require("__TheEckelmonster-core-library__.libs.data.data")
local Bug_Fix_Data = require("__TheEckelmonster-core-library__.libs.data.versions.bug-fix-data")
local Major_Data = require("__TheEckelmonster-core-library__.libs.data.versions.major-data")
local Minor_Data = require("__TheEckelmonster-core-library__.libs.data.versions.minor-data")

local version_data = {}

version_data.type = "version-data"

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

    local defaults = {
        type = self.type,
        major = self.major,
        minor = self.minor,
        bug_fix = self.bug_fix,
        string_val = self.string_val,
    }

    local obj = o or defaults

    for k, v in pairs(defaults) do if (obj[k] == nil and type(v) ~= "function") then obj[k] = v end end

    obj = Data:new(obj)

    setmetatable(obj, self)
    self.__index = self

    obj.valid = false

    return obj
end

function version_data.__concat(self) return self.string_val end

function version_data:to_string() return self.string_val end

setmetatable(version_data, Data)
version_data.__index = version_data
return version_data