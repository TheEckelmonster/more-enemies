local mods = mods

local Armoured_Biters_Constants = require("libs.constants.mods.armoured-biters-constants")
local Cold_Biters_Constants = require("libs.constants.mods.cold-biters-constants")
local Explosive_Biters_Constants = require("libs.constants.mods.explosive-biters-constants")
local Proto_Biters_Constants = require("libs.constants.mods.proto-biters-constants")
local Toxic_Biters_Constants = require("libs.constants.mods.toxic-biters-constants")
local Behemoth_Enemies_Constants = require("libs.constants.mods.behemoth-enemies-constants")
local Gleba_Constants = require("libs.constants.gleba-constants")
local Nauvis_Constants = require("libs.constants.nauvis-constants")

local spawn_constants = {}

spawn_constants.name = {}

for _, v in pairs(Nauvis_Constants.nauvis.categories) do
    table.insert(spawn_constants.name, v.name .. "-biter")
    table.insert(spawn_constants.name, v.name .. "-spitter")
end

if ((mods and mods["ArmouredBiters"]) or (script and script.active_mods and script.active_mods["ArmouredBiters"])) then
    for _, v in pairs(Armoured_Biters_Constants.nauvis.categories) do
        table.insert(spawn_constants.name, v .. "-armoured-biter")
    end
end

if ((mods and mods["Cold_biters"]) or (script and script.active_mods and script.active_mods["Cold_biters"])) then
    for _, v in pairs(Cold_Biters_Constants.nauvis.categories) do
        table.insert(spawn_constants.name, v .. "-cold-biter")
        table.insert(spawn_constants.name, v .. "-cold-spitter")
    end
end

if ((mods and mods["Explosive_biters"]) or (script and script.active_mods and script.active_mods["Explosive_biters"])) then
    for _, v in pairs(Explosive_Biters_Constants.nauvis.categories) do
        if (v ~= Explosive_Biters_Constants.nauvis.categories.LEVIATHAN) then
            table.insert(spawn_constants.name, v .. "-explosive-biter")
        else
            table.insert(spawn_constants.name, "explosive-" .. v .. "-biter")
        end
        table.insert(spawn_constants.name, v .. "-explosive-spitter")
    end
end

if ((mods and mods["Toxic_biters"]) or (script and script.active_mods and script.active_mods["Toxic_biters"])) then
    for _, v in pairs(Toxic_Biters_Constants.nauvis.categories) do
        table.insert(spawn_constants.name, v .. "-toxic-biter")
        table.insert(spawn_constants.name, v .. "-toxic-spitter")
    end
end

if ((mods and mods["old_biters_remastered"]) or (script and script.active_mods and script.active_mods["old_biters_remastered"])) then
    for _, v in pairs(Proto_Biters_Constants.nauvis.categories) do
        table.insert(spawn_constants.name, "old-" .. v .. "-biter")
        table.insert(spawn_constants.name, "old-" .. v .. "-spitter")
    end
end

if ((mods and mods["space-age"]) or (script and script.active_mods and script.active_mods["space-age"])) then
    for _, v in pairs(Gleba_Constants.gleba.categories) do
        table.insert(spawn_constants.name, v.name .. "-wriggler-pentapod")
        table.insert(spawn_constants.name, v.name .. "-strafer-pentapod")
        table.insert(spawn_constants.name, v.name .. "-stomper-pentapod")
    end
end

if ((mods and mods["space-age"] and mods["behemoth-enemies"]) or (script and script.active_mods and script.active_mods["space-age"] and script.active_mods["behemoth-enemies"])) then
    table.insert(spawn_constants.name, Behemoth_Enemies_Constants.prefix .. "-wriggler-pentapod")
    table.insert(spawn_constants.name, Behemoth_Enemies_Constants.prefix .. "-strafer-pentapod")
    table.insert(spawn_constants.name, Behemoth_Enemies_Constants.prefix .. "-stomper-pentapod")
end

return spawn_constants