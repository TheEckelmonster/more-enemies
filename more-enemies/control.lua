local script = script

--[[
    Globals
]]

Util = require("__core__.lualib.util")
Deepcopy = Util.table.deepcopy

-- Constants
require("scripts.constants.strings")

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

-- static difficulties

Easy_Difficulty_Data = require("scripts.data.difficulties.easy-difficulty-data")
Vanilla_Difficulty_Data = require("scripts.data.difficulties.vanilla-difficulty-data")
Vanilla_Plus_Difficulty_Data = require("scripts.data.difficulties.vanilla-plus-difficulty-data")
Hard_Difficulty_Data = require("scripts.data.difficulties.hard-difficulty-data")
Insanity_Difficulty_Data = require("scripts.data.difficulties.insanity-difficulty-data")

script.register_metatable("Easy_Difficulty_Data", Easy_Difficulty_Data)
script.register_metatable("Vanilla_Difficulty_Data", Vanilla_Difficulty_Data)
script.register_metatable("Vanilla_Plus_Difficulty_Data", Vanilla_Plus_Difficulty_Data)
script.register_metatable("Hard_Difficulty_Data", Hard_Difficulty_Data)
script.register_metatable("Insanity_Difficulty_Data", Insanity_Difficulty_Data)

-- unsorted
Data = require("__TheEckelmonster-core-library__.libs.data.data")

script.register_metatable("Data", Data)

Attack_Group_Data = require("scripts.data.attack-group-data")
Leaf_Node_Data = require("scripts.data.leaf-data")
Quad_Meta_Data = require("scripts.data.quad-meta-data")
Quadnode = require("scripts.data.quadnode")
Quadtree = require("scripts.data.quadtree-data")
Requesting_Unit_Group = require("scripts.data.requesting-unit-group")
Scout_Group_Data = require("scripts.data.scout-group-data")
Simple_Queue = require("scripts.data.simple-queue")
Stats_Data = require("scripts.data.stats-data")

script.register_metatable("Attack_Group_Data", Attack_Group_Data)
script.register_metatable("Leaf_Node_Data", Leaf_Node_Data)
script.register_metatable("Quad_Meta_Data", Quad_Meta_Data)
script.register_metatable("Quadnode", Quadnode)
script.register_metatable("Quadtree", Quadtree)
script.register_metatable("Requesting_Unit_Group", Requesting_Unit_Group)
script.register_metatable("Scout_Group_Data", Scout_Group_Data)
script.register_metatable("Simple_Queue", Simple_Queue)
script.register_metatable("Stats_Data", Stats_Data)

---

require("scripts.events")
require("scripts.commands")