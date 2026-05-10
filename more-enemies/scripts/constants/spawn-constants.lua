
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
spawn_constants.name_table = {}
spawn_constants.filter = {}

for _, v in pairs(Nauvis_Constants.nauvis.categories) do
  table.insert(spawn_constants.name, v.name .. "-biter")
  table.insert(spawn_constants.name, v.name .. "-spitter")

  spawn_constants.name_table[v.name .. "-biter"] = v.value
  spawn_constants.name_table[v.name .. "-spitter"] = v.value

  table.insert(spawn_constants.filter, { filter = "name",  name = v.name .. "-biter" })
  table.insert(spawn_constants.filter, { filter = "name",  name = v.name .. "-spitter" })
end

if ((mods and mods["ArmouredBiters"]) or (script and script.active_mods and script.active_mods["ArmouredBiters"])) then
    for _,v in pairs(Armoured_Biters_Constants.nauvis.categories) do
        table.insert(spawn_constants.name, v.name .. "-armoured-biter")

        spawn_constants.name_table[v.name .. "-armoured-biter"] = v.value

        table.insert(spawn_constants.filter, { filter = "name",  name = v.name .. "-armoured-biter" })
    end
end

if ((mods and mods["Cold_biters"]) or (script and script.active_mods and script.active_mods["Cold_biters"])) then
    for _,v in pairs(Cold_Biters_Constants.nauvis.categories) do
        table.insert(spawn_constants.name, v.name .. "-cold-biter")
        table.insert(spawn_constants.name, v.name .. "-cold-spitter")

        spawn_constants.name_table[v.name .. "-cold-biter"] = v.value
        spawn_constants.name_table[v.name .. "-cold-spitter"] = v.value

        table.insert(spawn_constants.filter, { filter = "name",  name = v.name .. "-cold-biter" })
        table.insert(spawn_constants.filter, { filter = "name",  name = v.name .. "-cold-spitter" })
    end
end

if ((mods and mods["Explosive_biters"]) or (script and script.active_mods and script.active_mods["Explosive_biters"])) then
    for _,v in pairs(Explosive_Biters_Constants.nauvis.categories) do
        if (v ~= Explosive_Biters_Constants.nauvis.categories.LEVIATHAN) then
            table.insert(spawn_constants.name, v.name .. "-explosive-biter")

            spawn_constants.name_table[v.name .. "-explosive-biter"] = v.value

            table.insert(spawn_constants.filter, { filter = "name",  name = v.name .. "-explosive-biter" })
        else
            table.insert(spawn_constants.name, "explosive-" .. v.name .. "-biter")

            spawn_constants.name_table["explosive-" .. v.name .. "-biter"] = v.value

            table.insert(spawn_constants.filter, { filter = "name",  name = "explosive-" .. v.name .. "-biter" })
        end

        table.insert(spawn_constants.name, v.name .. "-explosive-spitter")

        spawn_constants.name_table[v.name .. "-explosive-spitter"] = v.value

        table.insert(spawn_constants.filter, { filter = "name",  name = v.name .. "-explosive-spitter" })
    end
end

if ((mods and mods["Toxic_biters"]) or (script and script.active_mods and script.active_mods["Toxic_biters"])) then
    for _,v in pairs(Toxic_Biters_Constants.nauvis.categories) do
        table.insert(spawn_constants.name, v.name .. "-toxic-biter")
        table.insert(spawn_constants.name, v.name .. "-toxic-spitter")

        spawn_constants.name_table[v.name .. "-toxic-biter"] = v.value
        spawn_constants.name_table[v.name .. "-toxic-spitter"] = v.value

        table.insert(spawn_constants.filter, { filter = "name",  name = v.name .. "-toxic-biter" })
        table.insert(spawn_constants.filter, { filter = "name",  name = v.name .. "-toxic-spitter" })
    end
end

if ((mods and mods["old_biters_remastered"]) or (script and script.active_mods and script.active_mods["old_biters_remastered"])) then
    for _,v in pairs(Proto_Biters_Constants.nauvis.categories) do
        table.insert(spawn_constants.name, "old-" .. v.name .. "-biter")
        table.insert(spawn_constants.name, "old-" .. v.name .. "-spitter")

        spawn_constants.name_table["old-" .. v.name .. "-biter"] = v.value
        spawn_constants.name_table["old-" .. v.name .. "-spitter"] = v.value

        table.insert(spawn_constants.filter, { filter = "name",  name = "old-" .. v.name .. "-biter" })
        table.insert(spawn_constants.filter, { filter = "name",  name = "old-" .. v.name .. "-spitter" })
    end
end

if ((mods and mods["space-age"]) or (script and script.active_mods and script.active_mods["space-age"])) then
    for _,v in pairs(Gleba_Constants.gleba.categories) do
        table.insert(spawn_constants.name, v.name .. "-wriggler-pentapod")
        table.insert(spawn_constants.name, v.name .. "-strafer-pentapod")
        table.insert(spawn_constants.name, v.name .. "-stomper-pentapod")

        spawn_constants.name_table[v.name .. "-wriggler-pentapod"] = v.value
        spawn_constants.name_table[v.name .. "-strafer-pentapod"] = v.value
        spawn_constants.name_table[v.name .. "-stomper-pentapod"] = v.value

        table.insert(spawn_constants.filter, { filter = "name",  name = v.name .. "-wriggler-pentapod" })
        table.insert(spawn_constants.filter, { filter = "name",  name = v.name .. "-strafer-pentapod" })
        table.insert(spawn_constants.filter, { filter = "name",  name = v.name .. "-stomper-pentapod" })
    end
end

if ((mods and mods["space-age"] and mods["behemoth-enemies"]) or (script and script.active_mods and script.active_mods["space-age"] and script.active_mods["behemoth-enemies"])) then
    table.insert(spawn_constants.name, Behemoth_Enemies_Constants.prefix .. "-wriggler-pentapod")
    table.insert(spawn_constants.name, Behemoth_Enemies_Constants.prefix .. "-strafer-pentapod")
    table.insert(spawn_constants.name, Behemoth_Enemies_Constants.prefix .. "-stomper-pentapod")

    -- spawn_constants.name_table[Behemoth_Enemies_Constants.prefix .. "-wriggler-pentapod"] = v.value
    -- spawn_constants.name_table[Behemoth_Enemies_Constants.prefix .. "-strafer-pentapod"] = v.value
    -- spawn_constants.name_table[Behemoth_Enemies_Constants.prefix .. "-stomper-pentapod"] = v.value

    table.insert(spawn_constants.filter, { filter = "name",  name = Behemoth_Enemies_Constants.prefix .. "-wriggler-pentapod" })
    table.insert(spawn_constants.filter, { filter = "name",  name = Behemoth_Enemies_Constants.prefix .. "-strafer-pentapod" })
    table.insert(spawn_constants.filter, { filter = "name",  name = Behemoth_Enemies_Constants.prefix .. "-stomper-pentapod" })
end

return spawn_constants