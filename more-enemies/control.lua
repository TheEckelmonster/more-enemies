-- Globals
Cache = {}
Cache_Attributes = {}
setmetatable(Cache_Attributes, { __mode = "k" })

S_Cache = nil
S_Cache_Attributes = nil

Random = nil

Log = require("__TheEckelmonster-core-library__.libs.log.log")
Event_Handler = require("__TheEckelmonster-core-library__.scripts.event-handler")

---

--[[ Data types and metatables ]]

-- structures
local Queue_Data = require("__TheEckelmonster-core-library__.libs.data.structures.queue-data")

script.register_metatable("Queue_Data", Queue_Data)

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
-- local Data = require("scripts.data.data")
local Cache_Data = require("scripts.data.cache-data")
local Event_Data = require("scripts.data.event-data")

script.register_metatable("Cache_Data", Cache_Data)
script.register_metatable("Data", Data)
script.register_metatable("Event_Data", Event_Data)

---

-- local Events = require("scripts.events")
-- local More_Enemies_Commands = require("libs.more-enemies-commands")
require("scripts.events")
require("scripts.commands")

--[[ This event is so that the current game.tick is always available in storage, even if the game object itself is not available
    -> namely for the "on_load" event, as the game object is not available, but storage is available to read from
]]
Event_Handler:register_event({
    event_name = "on_tick",
    source_name = "control.on_tick",
    func_name = "control.on_tick",
    func = function (event)
       if (storage and event and event.tick) then storage.tick = event.tick end
    end,
})

Event_Handler:set_event_position({
    event_name = "on_tick",
    source_name = "control.on_tick",
    new_position = 1,
})

Event_Handler:register_event({
    event_name = "on_configuration_changed",
    source_name = "control.on_configuration_changed",
    func_name = "control.on_configuration_changed",
    func = function (event)
        if (storage and game and game.tick) then storage.tick = game.tick end
    end,
})

Event_Handler:set_event_position({
    event_name = "on_configuration_changed",
    source_name = "control.on_configuration_changed",
    new_position = 1,
})