local Log = Log

local commands = commands

local Core_Utils = require("__TheEckelmonster-core-library__.libs.utils.core-utils")

local Constants = require("scripts.constants.constants")
local Initialization = require("scripts.initialization")
local More_Enemies_Repository = require("scripts.repositories.more-enemies-repository")
local Version_Data = require("scripts.data.version-data")

local locals = {}

local more_enemies_commands = {}

function more_enemies_commands.init(event)
    Log.debug("more_enemies_commands.init")
    locals.validate_command(event, function (player)
        Log.info("commands.init")
        player.print("Initializing anew")
        local maintain_data = true

        if (not (event.parameter == nil or type(event.parameter) ~= "string" and #(string.gsub(event.parameter, " ", "")) < 1)) then
            if (type(event.parameter) == "boolean") then
                maintain_data = event.parameter
            elseif (type(event.parameter == "string")) then
                if (event.parameter == "false") then
                    maintain_data = false
                else
                    maintain_data = true
                end
            end
        end

        Initialization.init({ maintain_data = maintain_data})
        player.print("Initialization complete")
    end)
end

function more_enemies_commands.reinit(event)
    Log.debug("more_enemies_commands.reinit")
    locals.validate_command(event, function (player)
        Log.info("commands.reinit")
        player.print("Reinitializing")
        local maintain_data = true

        if (not (event.parameter == nil or type(event.parameter) ~= "string" or #(string.gsub(event.parameter, " ", "")) < 1)) then
            if (type(event.parameter) == "boolean") then
                maintain_data = event.parameter
            elseif (type(event.parameter == "string")) then
                if (event.parameter == "false") then
                    maintain_data = false
                else
                    maintain_data = true
                end
            end
        end

        Initialization.reinit({ maintain_data = maintain_data})
        player.print("Reinitialization complete")
    end)
end

function more_enemies_commands.print_table(event)
    Log.debug("more_enemies_commands.print_table")
    locals.validate_command(event, function (player)
        Log.info("commands.print_table")

        Core_Utils.commands.print_table({ player = player, event = event })
    end)
end

function more_enemies_commands.print_storage(event)
    Log.debug("more_enemies_commands.print_storage")
    locals.validate_command(event, function (player)
        Log.info("commands.print_storage")

        local file_name = "storage_" .. game.tick
        local exported_file_name = Core_Utils.table.traversal.traverse_print(storage, file_name, _, { max_depth = 4,  })
        player.print("Exported table to: ../Factorio/script-output/" .. tostring(exported_file_name))
    end)
end

function more_enemies_commands.print_clone_counts(event)
    Log.debug("more_enemies_commands.print_clone_counts")
    locals.validate_command(event, function(player)
        Log.info("commands.print_clone_counts", true)
        local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()

        if (more_enemies_data.valid) then
            for _, planet in pairs(Constants.DEFAULTS.planets) do
                log("storage.more_enemies.clone[" ..
                planet.string_val .. "].count.unit: " .. tostring(storage.more_enemies.clone[planet.string_val].unit))
                player.print("storage.more_enemies.clone[" ..
                planet.string_val .. "].count.unit: " .. tostring(storage.more_enemies.clone[planet.string_val].unit))
                log("storage.more_enemies.clone[" ..
                planet.string_val .. "].count.unit_group: " .. tostring(storage.more_enemies.clone[planet.string_val].unit_group))
                player.print("storage.more_enemies.clone[" .. planet.string_val .. "].count.unit_group: " .. tostring(storage.more_enemies.clone[planet.string_val].unit_group))
                log("storage.more_enemies.staged_clone[" .. planet.string_val .. "].count.unit: " .. tostring(storage.more_enemies.staged_clone[planet.string_val].unit))
                player.print("storage.more_enemies.staged_clone[" .. planet.string_val .. "].count.unit: " .. tostring(storage.more_enemies.staged_clone[planet.string_val].unit))
                log("storage.more_enemies.staged_clone[" .. planet.string_val .. "].count.unit_group: " .. tostring(storage.more_enemies.staged_clone[planet.string_val].unit_group))
                player.print("storage.more_enemies.staged_clone[" .. planet.string_val .. "].count.unit_group: " .. tostring(storage.more_enemies.staged_clone[planet.string_val].unit_group))
                if (script and script.active_mods and script.active_mods["BREAM"]) then
                    if (more_enemies_data.mod
                            and more_enemies_data.mod.clone
                            and more_enemies_data.mod.clone[planet.string_val]
                            and more_enemies_data.mod.clone[planet.string_val].count ~= nil)
                    then
                        log("storage.more_enemies.mod.clone[" .. planet.string_val .. "].count: " .. tostring(storage.more_enemies.mod.clone[planet.string_val].count))
                        player.print("storage.more_enemies.mod.clone[" .. planet.string_val .. "].count: " .. tostring(storage.more_enemies.mod.clone[planet.string_val].count))
                    end
                end
            end
        else
            Log.error("storage is either nil or invalid")
            player.print(serpent.block("storage is either nil or invalid; command failed"))
        end
    end)
end

function more_enemies_commands.version(event)
    locals.validate_command(event, function (player)
        -- local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()
        local more_enemies_data = storage.more_enemies or More_Enemies_Repository.get_more_enemies_data()

        -- if (not more_enemies_data.valid) then
        --     log(serpent.block("storage.more_enemies is nil or invalid; could not obtain version"))
        --     player.print(serpent.block("storage.more_enemies is nil or invalid; could not obtain version"))
        --     return
        -- end

        -- if (not more_enemies_data.version_data.valid) then
        --     log(serpent.block("storage.more_enemies.version is nil or invalid; could not obtain version"))
        --     player.print(serpent.block("storage.more_enemies.version is nil or invalid; could not obtain version"))
        --     return
        -- end

        local version_data = more_enemies_data.version_data

        log(serpent.block("more_enemies mod version: " .. Version_Data.string_val))
        player.print(serpent.block("more_enemies mod version: " .. Version_Data.string_val))

        log(serpent.block("more_enemies storage version: " .. version_data.string_val))
        player.print(serpent.block("more_enemies storage version: " .. version_data.string_val))
    end)
end

function more_enemies_commands.exterminatus(event)
    locals.validate_command(event, function(player)
        local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()

        if (more_enemies_data.valid) then
            player.print("Exterminatus: removing all enemies, this may take a moment")
            Initialization.purge({ exterminatus = true })
        else
            Log.error("storage is either nil or invalid")
            player.print("storage is either nil or invalid; command failed")
        end
    end)
end

function more_enemies_commands.print_event_handlers(event)
    locals.validate_command(event, function (player)

        if (Event_Handler) then
            local file_name = "Event_Handler.event_names_" .. game.tick
            local exported_file_name = Core_Utils.table.traversal.traverse_print(Event_Handler.event_names, file_name, _, { full = true  })
            player.print("Exported table to: ../Factorio/script-output/" .. tostring(exported_file_name))

            file_name = "Event_Handler.events_" .. game.tick
            exported_file_name = Core_Utils.table.traversal.traverse_print(Event_Handler.events, file_name, _, { full = true  })
            player.print("Exported table to: ../Factorio/script-output/" .. tostring(exported_file_name))
        end
    end)
end

function locals.validate_command(event, fun)
    if (event) then
        local player = nil

        if (game and event.player_index > 0 and game.players) then player = game.players[event.player_index] end
        if (player and player.valid) then fun(player) end
    end
end

--[[ TODO: Localise the command descriptions ]]
commands.add_command("more_enemies.init", "Initialize from scratch. Will erase existing data.", more_enemies_commands.init)
commands.add_command("more_enemies.reinit", "Tries to reinitialize, attempting to preserve existing data.", more_enemies_commands.reinit)
commands.add_command("more_enemies.print_clone_counts", "Prints the clone counts.", more_enemies_commands.print_clone_counts)
commands.add_command("more_enemies.print_table", "", more_enemies_commands.print_table)
commands.add_command("more_enemies.print_storage", "", more_enemies_commands.print_storage)
commands.add_command("more_enemies.print_event_handlers", "", more_enemies_commands.print_event_handlers)
commands.add_command("more_enemies.version", "Prints the current mod version, and the underlying storage version.", more_enemies_commands.version)
commands.add_command("more_enemies.exterminatus", "Kills all enemy units and flushes the path finder", more_enemies_commands.exterminatus)

Core_Utils.table.traversal.set_prefix({ prefix = Constants.mod_name })

return more_enemies_commands