-- If already defined, return
if _more_enemies_commands and _more_enemies_commands.more_enemies then
  return _more_enemies_commands
end

local Constants = require("libs.constants.constants")
local Initialization = require("scripts.initialization")
local More_Enemies_Repository = require("scripts.repositories.more-enemies-repository")
local Log = require("libs.log.log")
local Version_Data = require("scripts.data.version-data")

local depth = function ()
    local self = { depth = 0 }
    local get = function () return self.depth end
    local increment = function () self.depth = self.depth + 1 end
    local decrement = function () self.depth = self.depth - 1 end
    local reset = function () self.depth = 0 end

    return {
        get = get,
        increment = increment,
        decrement = decrement,
        reset = reset,
    }
end
depth = depth()

local locals = {}

local more_enemies_commands = {}

function more_enemies_commands.init(command)
  Log.debug("more_enemies_commands.init")
  locals.validate_command(command, function (player)
    Log.info("commands.init")
    player.print("Initializing anew")
    Initialization.init()
    player.print("Initialization complete")
  end)
end

function more_enemies_commands.reinit(command)
  Log.debug("more_enemies_commands.reinit")
  locals.validate_command(command, function (player)
    Log.info("commands.reinit")
    player.print("Reinitializing")
    Initialization.reinit()
    player.print("Reinitialization complete")
  end)
end

function more_enemies_commands.print_table(command)
    Log.debug("more_enemies_commands.print_storage")
    locals.validate_command(command, function (player)
        Log.info("commands.print_storage", true)

        if (command.parameter == nil or type(command.parameter) ~= "string" and #(string.gsub(command.parameter, " ", "")) > 0) then return end

        -- Find any passed parameters/flags
        --[[
            /more_enemies.print_table --depth=3 overmind.nauvis.chunks_1.queue
        ]]

        local parameter_string = command.parameter
        -- local max_depth = 2 ^ 8
        local max_depth = 1

        -- Should match, 2 dashes literals ('-'), 1 or more letters, '=', 1 or more digits, space character 0 or more times
        local i, j, param, param_val = parameter_string:find("%-%-(%a+)=(%d+)%s*", 1)

        while param ~= nil and param_val ~= nil do
            log(parameter_string:sub(i, j))
            log(param)
            log(param_val)

            if (param:lower() == "depth" or param:lower() == "d") then max_depth = type(tonumber(param_val)) == "number" and tonumber(param_val) or 1 end

            parameter_string = parameter_string:sub(j + 1, #parameter_string)
            log(parameter_string)

            -- i, j, param, param_val = parameter_string:find("--(%a+)=(%d+)%s*", j + 1)
            i, j, param, param_val = parameter_string:find("--(%a+)=(%d+)%s*", 1)
        end

        -- Get the table name(s)
        -- local t_name = command.parameter
        local t_name = parameter_string
        local t_parsed_name = { t = {}, a = {}, step = { t = {}, a = {}, }, reversed = { t = {}, a = {}, } }
        local i = 1
        local index = 0
        local s_index = 0
        local r_index = 0
        local name = t_name
        local remainder = t_name
        local storage_prefix = false
        log(t_name)
        repeat
            local _i = t_name:find("%.", (index > 0 and index + 1 or 1)) or 0
            local r_i = t_name:reverse():find("%.", (r_index > 0 and r_index + 1 or 1)) or 0
            index = index + _i
            r_index = r_index + r_i
            log(index)

            name = remainder:sub(1, remainder:find("%.") and remainder:find("%.") - 1 or #remainder)
            remainder = remainder:sub(remainder:find("%.") and remainder:find("%.") + 1 or 1, #remainder)
            log(name)
            log(remainder)

            local current_name = t_name:sub(1, (_i - 1))
            local step_name = name
            local reversed_name = t_name:reverse():sub(1, (r_i - 1)):reverse()
            log(reversed_name)

            -- if (i == 1 and step_name == "storage") then goto skip end
            if (i == 1 and step_name == "storage") then storage_prefix = true end
            if (t_parsed_name.t[current_name] or t_parsed_name.reversed.t[reversed_name]) then break end
            t_parsed_name.t[current_name] = i
            t_parsed_name.a[i] = current_name
            if (storage_prefix) then
                t_parsed_name.step.t[step_name] = i - 1
                t_parsed_name.step.a[i - 1] = step_name
            else
                t_parsed_name.step.t[step_name] = i
                t_parsed_name.step.a[i] = step_name
            end
            t_parsed_name.reversed.t[reversed_name] = i
            t_parsed_name.reversed.a[i] = reversed_name

            i = i + 1
        until i > 2 ^ 6

        local t = { data = nil, name = t_name }

        log(serpent.block(t_parsed_name))

        local func; func = function (data)
            if (t_parsed_name.step.a[data.i] and t_parsed_name.step.t[t_parsed_name.step.a[data.i]]) then
                log(serpent.block(data))
                local name = data.t.a[data.i]
                log(serpent.block(name))
                if (data.table[name]) then
                    t.data = data.table[name]
                    t.name = data.name .. "." .. name
                    if (next(data.t.a, data.i)) then
                        log("found another " .. next(data.t.a, data.i))
                        func({ t = data.t, i = next(data.t.a, data.i), name = t.name, table = data.table[name] })
                    end
                end
            end
        end

        local depth = 1

        if (t_parsed_name.step.a[depth] and t_parsed_name.step.t[t_parsed_name.step.a[depth]]) then
            local name = t_parsed_name.step.a[depth]
            -- log(serpent.block(name))
            if (storage[name]) then
                -- log(serpent.block(storage[name]))
                t.data = storage[name]
                t.name = "storage." .. name
                if (next(t_parsed_name.step.a, depth)) then
                    func({ t = t_parsed_name.step, i = next(t_parsed_name.step.a, depth), name = "storage." .. name, table = storage[name] })
                end
            end
        end

        if (t.data == nil) then
            if (storage[t_name]) then
                if (type(storage[t_name]) == "table") then
                    t.data = { storage[t_name] }
                else
                    t.data = storage[t_name]
                end
                t.name = "storage." .. t_name
            else
                t = Constants.table.traverse_find(t_name, _, _, path, { parsed_name = t_parsed_name, max_depth = max_depth })
            end
        end

        if (t ~= nil and type(t) == "table") then
            if (t.data and type(t.data) == "table") then
                local file_name = "more-enemies/" .. t.name .. "_" .. game.tick .. ".json"
                Constants.table.traverse_print(t.data, file_name, _, { max_depth = max_depth })
                player.print("Exported table to file: ../Factorio/script-output/" .. file_name)
            else
                player.print("Could not find table: " .. t.name)
            end
        else
            if (t) then
                player.print("Could not find table: " .. t.name)
            else
                player.print("Could not find table")
            end
        end
    end)
end

function more_enemies_commands.print_storage(command)
    Log.debug("more_enemies_commands.print_storage")
    locals.validate_command(command, function (player)
        Log.info("commands.print_storage", true)

        locals.traverse_print(storage, "more-enemies/storage_" .. game.tick .. ".json")
    end)
end

function more_enemies_commands.print_clone_counts(command)
  Log.debug("more_enemies_commands.print_clone_counts")
  locals.validate_command(command, function (player)
    Log.info("commands.print_clone_counts", true)
    local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()

    if (more_enemies_data.valid) then
      for _, planet in pairs(Constants.DEFAULTS.planets) do
        log("storage.more_enemies.clone[" .. planet.string_val .. "].count.unit: " .. tostring(storage.more_enemies.clone[planet.string_val].unit))
        player.print("storage.more_enemies.clone[" .. planet.string_val .. "].count.unit: " .. tostring(storage.more_enemies.clone[planet.string_val].unit))
        log("storage.more_enemies.clone[" .. planet.string_val .. "].count.unit_group: " .. tostring(storage.more_enemies.clone[planet.string_val].unit_group))
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

function more_enemies_commands.version(command)
  Log.debug("more_enemies_commands.version")
  locals.validate_command(command, function (player)
    Log.info("commands.version")
    local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()

    if (not more_enemies_data.valid) then
      log(serpent.block("storage.more_enemies is nil or invalid; could not obtain version"))
      player.print(serpent.block("storage.more_enemies is nil or invalid; could not obtain version"))
      return
    end

    if (not more_enemies_data.version_data.valid) then
      log(serpent.block("storage.more_enemies.version is nil or invalid; could not obtain version"))
      player.print(serpent.block("storage.more_enemies.version is nil or invalid; could not obtain version"))
      return
    end

    local version_data = more_enemies_data.version_data

    log(serpent.block("more_enemies mod version: " .. Version_Data.string_val))
    player.print(serpent.block("more_enemies mod version: " .. Version_Data.string_val))

    log(serpent.block("more_enemies storage version: " .. version_data.string_val))
    player.print(serpent.block("more_enemies storage version: " .. version_data.string_val))
  end)
end

function more_enemies_commands.set_do_nth_tick(command)
  Log.debug("more_enemies_commands.set_do_nth_tick")
  locals.validate_command(command, function (player)
    Log.info("commands.set_do_nth_tick", true)
    local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()

    if (more_enemies_data.valid) then
      if (command.parameter ~= nil and (command.parameter or command.parameter == "true" or command.parameter >= 1)) then
        log("Setting do_nth_tick to true")
        player.print("Setting do_nth_tick to true")
        more_enemies_data.do_nth_tick = true
      else
        log("Setting do_nth_tick to false")
        player.print("Setting do_nth_tick to false")
        more_enemies_data.do_nth_tick = false
      end
    else
      Log.error("storage is either nil or invalid")
      player.print(serpent.block("storage is either nil or invalid; command failed"))
    end
  end)
end

function more_enemies_commands.get_do_nth_tick(command)
  Log.debug("more_enemies_commands.get_do_nth_tick")
  locals.validate_command(command, function (player)
    Log.info("commands.get_do_nth_tick", true)
    local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()

    if (more_enemies_data.valid) then
        log("do_nth_tick = " .. serpent.block(more_enemies_data.do_nth_tick))
        player.print("do_nth_tick = " .. serpent.block(more_enemies_data.do_nth_tick))
    else
      Log.error("storage is either nil or invalid")
      player.print(serpent.block("storage is either nil or invalid; command failed"))
    end
  end)
end

function more_enemies_commands.purge_all(command)
  Log.debug("more_enemies_commands.purge_all")
  locals.validate_command(command, function (player)
    Log.info("commands.purge", true)
    local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()

    if (more_enemies_data.valid) then
      player.print("Purging all")
      Initialization.purge()
    else
      Log.error("storage is either nil or invalid")
      player.print(serpent.block("storage is either nil or invalid; command failed"))
    end
  end)
end

function more_enemies_commands.purge_clones(command)
  Log.debug("more_enemies_commands.purge_clones")
  locals.validate_command(command, function (player)
    Log.info("commands.purge", true)
    local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()

    if (more_enemies_data.valid) then
      player.print("Purging clones")
      Initialization.purge({ clones = true })
    else
      Log.error("storage is either nil or invalid")
      player.print(serpent.block("storage is either nil or invalid; command failed"))
    end
  end)
end

function more_enemies_commands.purge_modded_clones(command)
  Log.debug("more_enemies_commands.purge_modded_clones")
  locals.validate_command(command, function (player)
    Log.info("commands.purge", true)
    local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()

    if (more_enemies_data.valid) then
      player.print("Purging mod added clones")
      Initialization.purge({ mod_added_clones = true })
    else
      Log.error("storage is either nil or invalid")
      player.print(serpent.block("storage is either nil or invalid; command failed"))
    end
  end)
end

function more_enemies_commands.exterminatus(command)
  Log.debug("more_enemies_commands.exterminatus")
  locals.validate_command(command, function (player)
    Log.info("commands.purge", true)
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

locals.validate_command = function (command, fun)
    Log.debug("validate_command")
    Log.info(command)
    if (command) then
        local player_index = command.player_index

        local player = nil
        if (game and player_index > 0 and game.players) then
            player = game.players[player_index]
        end

        if (player) then
            fun(player)
        end
    end
end

commands.add_command("more_enemies.init", "Initialize from scratch. Will erase existing data.", more_enemies_commands.init)
commands.add_command("more_enemies.reinit", "Tries to reinitialize, attempting to preserve existing data.", more_enemies_commands.reinit)
commands.add_command("more_enemies.print_clone_counts", "Prints the clone counts.", more_enemies_commands.print_clone_counts)
commands.add_command("more_enemies.print_table", "", more_enemies_commands.print_table)
commands.add_command("more_enemies.print_storage", "Prints the underlying storage data.", more_enemies_commands.print_storage)
commands.add_command("more_enemies.version", "Prints the current mod version, and the underlying storage version.", more_enemies_commands.version)
commands.add_command("more_enemies.get_do_nth_tick", "Gets the value of the underlying variable for whether to process clones or not.", more_enemies_commands.get_do_nth_tick)
commands.add_command("more_enemies.set_do_nth_tick", "Sets whether to process clones or not depending on the parameter passed.", more_enemies_commands.set_do_nth_tick)
commands.add_command("more_enemies.purge_all", "Clears all of the cloned enemies, and enemies staged to be cloned", more_enemies_commands.purge_all)
commands.add_command("more_enemies.purge_clones", "Clears all of the vanilla cloned enemies, and vanilla enemies staged to be cloned", more_enemies_commands.purge_clones)
commands.add_command("more_enemies.purge_modded_clones", "Clears all of the mod added cloned enemies, and mod added enemies staged to be cloned", more_enemies_commands.purge_modded_clones)
commands.add_command("more_enemies.exterminatus", "Kills all enemy units and flushes the path finder", more_enemies_commands.exterminatus)

more_enemies_commands.more_enemies = true

local _more_enemies_commands = more_enemies_commands

return more_enemies_commands