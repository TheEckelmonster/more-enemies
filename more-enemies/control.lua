-- Globals
Log = require("__TheEckelmonster-core-library__.libs.log.log")
Event_Handler = require("__TheEckelmonster-core-library__.scripts.event-handler")

---

--[[ Data types and metatables ]]

-- versions
local Bug_Fix_Data = require("__TheEckelmonster-core-library__.libs.data.versions.bug-fix-data")
local Major_Data = require("__TheEckelmonster-core-library__.libs.data.versions.major-data")
local Minor_Data = require("__TheEckelmonster-core-library__.libs.data.versions.minor-data")

script.register_metatable("Bug_Fix_Data", Bug_Fix_Data)
script.register_metatable("Major_Data", Major_Data)
script.register_metatable("Minor_Data", Minor_Data)

local Version_Data = require("scripts.data.version-data")

script.register_metatable("Version_Data", Version_Data)

-- unsorted
local Data = require("__TheEckelmonster-core-library__.libs.data.data")

script.register_metatable("Data", Data)

---
require("scripts.events")
require("scripts.commands")