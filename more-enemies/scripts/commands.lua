local commands = commands

local Log = Log

local Core_Utils = require("__TheEckelmonster-core-library__.libs.utils.core-utils")

local Constants = require("scripts.constants.constants")
local Initialization = require("scripts.initialization")
local Version_Data = require("scripts.data.version-data")

local locals = {}

local more_enemies_commands = {}

local BOOLEAN = Types.BOOLEAN
local STRING = Types.STRING

local FALSE = FALSE

function more_enemies_commands.init(event)
    Log.debug("more_enemies_commands.init")
    locals.validate_command(event, function (player)
        Log.info("commands.init")
        player.print("Initializing anew")
        local maintain_data = true

        if (not (event.parameter == nil or type(event.parameter) ~= STRING and #(string.gsub(event.parameter, " ", "")) < 1)) then
            if (type(event.parameter) == BOOLEAN) then
                maintain_data = event.parameter
            elseif (type(event.parameter == STRING)) then
                if (event.parameter == FALSE) then
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

        if (not (event.parameter == nil or type(event.parameter) ~= STRING or #(string.gsub(event.parameter, " ", "")) < 1)) then
            if (type(event.parameter) == BOOLEAN) then
                maintain_data = event.parameter
            elseif (type(event.parameter == STRING)) then
                if (event.parameter == FALSE) then
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
        log(serpent.block(storage.num_clones))
        player.print({ "messages.num-clones", })
        player.print(serpent.block(storage.num_clones))
    end)
end

function more_enemies_commands.version(event)
    locals.validate_command(event, function (player)
        local version_data = storage.version_data or {}

        log(serpent.block("more_enemies mod version: " .. Version_Data.string_val))
        player.print(serpent.block("more_enemies mod version: " .. Version_Data.string_val))

        log(serpent.block("more_enemies storage version: " .. version_data.string_val))
        player.print(serpent.block("more_enemies storage version: " .. version_data.string_val))
    end)
end

function more_enemies_commands.exterminatus(event)
    locals.validate_command(event, function(player)
        player.print("Exterminatus: removing all enemies, this may take a moment")
        player.print("Cloning to resume in 15s")
        Initialization.purge({ exterminatus = true })
    end)
end

function more_enemies_commands.apply_migrations(event)
    locals.validate_command(event, function(player)
        player.print("Applying migrations")
        Initialization.apply_migrations()
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
commands.add_command("more_enemies.init", "Initialize from scratch. Accepts a single (boolean) parameter (maintain_data). If provided, and false, will erase existing data.", more_enemies_commands.init)
-- commands.add_command("more_enemies.reinit", "Tries to reinitialize, attempting to preserve existing data.", more_enemies_commands.reinit)
commands.add_command("more_enemies.print_clone_counts", "Prints the clone counts.", more_enemies_commands.print_clone_counts)
commands.add_command("more_enemies.print_table", "", more_enemies_commands.print_table)
commands.add_command("more_enemies.print_storage", "", more_enemies_commands.print_storage)
commands.add_command("more_enemies.print_event_handlers", "", more_enemies_commands.print_event_handlers)
commands.add_command("more_enemies.version", "Prints the current mod version, and the underlying storage version.", more_enemies_commands.version)
commands.add_command("more_enemies.exterminatus", "Kills all enemy units and flushes the path finder", more_enemies_commands.exterminatus)
commands.add_command("more_enemies.apply_migrations", "Reapply migration .lua files", more_enemies_commands.apply_migrations)

Core_Utils.table.traversal.set_prefix({ prefix = Constants.mod_name })

return more_enemies_commands