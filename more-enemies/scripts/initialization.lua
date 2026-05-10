local log = log
local type = type

local defines = defines
local defines_events =  defines.events

local Constants = Constants
local Log = Log
local Mod_Settings = Mod_Settings

local TECL_Core_Utils = require("__TheEckelmonster-core-library__.libs.utils.core-utils")

local Custom_Events = require("prototypes.custom-events.custom-events")
local Migrations = require("scripts.migrations")
local Version_Data = require("scripts.data.version-data")
local Version_Service = require("scripts.service.version-service")

local initialization = {}

initialization.last_version_result = nil

local locals = {}

function initialization.init(params)
    log({ "initialization.me-init", Mod_Settings.mod_name })
    Log.debug("initialization.init")
    Log.info(params)

    if (not params or type(params) ~= "table") then params = { maintain_data = false} end

    if (params and params.maintain_data) then params.maintain_data = true -- Explicitly set maintain_data to be a boolean value of true
    else params.maintain_data = false
    end

    return locals.initialize(true, params.maintain_data) -- from_scratch
end

function initialization.reinit(params)
    log({ "initialization.me-reinit", Mod_Settings.mod_name })
    Log.debug("initialization.reinit")
    Log.info(params)

    if (not params or type(params) ~= "table") then params = { maintain_data = false} end

    if (params and params.maintain_data) then params.maintain_data = true -- Explicitly set maintain_data to be a boolean value of true
    else params.maintain_data = false
    end

    return locals.initialize(false, params.maintain_data) -- as is
end

function initialization.purge()
    -- Purge clones
    if (game and game.forces and game.forces["enemy"]) then
        game.forces["enemy"].kill_all_units()
    end
end

function locals.initialize(from_scratch, maintain_data, maintain_existing_peace)
    Log.debug("locals.initialize")
    Log.info(from_scratch)
    Log.info(maintain_data)
    Log.info(maintain_existing_peace)

    from_scratch = from_scratch or false
    maintain_existing_peace = maintain_existing_peace or false

    if (not from_scratch) then
        -- Version check
        local version_data = storage.version_data
        if (version_data and not version_data.valid) then
            local version = initialization.last_version_result
            if (not version) then goto initialize end
            if (not version.major or not version.minor or not version.bug_fix) then goto initialize end
            if (not version.major.valid) then goto initialize end
            if (not version.minor.valid or not version.bug_fix.valid) then
                return locals.initialize(true, true, true)
            end

            ::initialize::
            return locals.initialize(true, false, true)
        else
            local version = Version_Service.validate_version()
            initialization.last_version_result = version
            if (not version or not version.valid) then
                version_data.valid = false
            end
        end
    end

    if (from_scratch) then
        log({ "initialization.me-initialization-anew", Constants.mod_name })
        if (game) then game.print({ "initialization.me-initialization-anew", Constants.mod_name }) end

        local _storage = storage
        _storage.storage_old = nil

        storage = {}
        storage.storage_old = _storage

        local version_data = Version_Data:new()
        storage.version_data = version_data
        version_data.valid = true

        -- do migrations
        locals.migrate({ maintain_data = maintain_data, maintain_existing_peace = maintain_existing_peace, new_version_data = version_data })

        storage.storage_old = nil
    end

    if (storage) then
        local version_data = storage.version_data
        if (not version_data.valid) then
            return locals.initialize(true)
        else
            local version = Version_Service.validate_version()
            if (not version or not version.valid) then
                version_data.valid = false
            end
        end
    end

    script.raise_event(
        Custom_Events.me_on_init_complete.name,
        {
            name = defines.events[Custom_Events.me_on_init_complete.name],
            tick = game.tick,
        }
    )

    if (from_scratch) then log("more-enemies: Initialization complete") end
    if (from_scratch and game) then game.print("more-enemies: Initialization complete") end
    Log.info(storage)
end

function locals.migrate(params)
    Log.debug("migrate")
    Log.info(params)
    log("migrate")

    local storage_old = storage.storage_old
    if (type(storage_old) ~= "table") then return end

    TECL_Core_Utils.table.reassign(storage_old, storage, { field = "event_handlers" })
    TECL_Core_Utils.table.reassign(storage_old, storage, { field = "handles" })
    TECL_Core_Utils.table.reassign(storage_old, storage, { field = "tick" })
    TECL_Core_Utils.table.reassign(storage_old, storage, { field = "settings" })
    TECL_Core_Utils.table.reassign(storage_old, storage, { field = "attack_group_planets" })

    local migration_start_message_printed = false
    local version_data = (storage_old.more_enemies and storage_old.more_enemies.version_data or storage_old.version_data)
    if (version_data and version_data.created) then
        if (storage_old.version_data and storage_old.version_data.created >= 0) then
            if (   (type(storage.tick) == "number" and storage.tick > 0)
                or (type(storage_old.tick) == "number" and storage_old.tick > 0)
            ) then
                log(Constants.mod_name .. ": Migrating existing data")
                game.print({ "initialization.me-migrate-start", Constants.mod_name})
                migration_start_message_printed = true
            end
        end
    end

    if (storage_old.version_data or storage.version_data) then
        local prev_version_data = storage_old.version_data or storage.version_data
        local new_version_data = params.new_version_data or storage.version_data

        if (    locals.validate_version({ version_data = prev_version_data })
            and locals.validate_version({ version_data = new_version_data })
        ) then
            log("previous version")
            log(serpent.block(prev_version_data.string_val))

            log("new version")
            log(serpent.block(new_version_data.string_val))

            local do_apply = nil
            for version, migration in pairs(Migrations) do
                do_apply = false
                if (prev_version_data.major.value <= version.major) then
                    do_apply = true
                else
                    if (prev_version_data.minor.value <= version.minor) then
                        do_apply = true
                    else
                        if (prev_version_data.bug_fix.value <= version.bug_fix) then
                            do_apply = true
                        end
                    end
                end

                if (do_apply and type(migration) == "function") then
                    log(serpent.block("Applying version "
                        .. version.major.. "."
                        .. version.minor .. "."
                        .. version.bug_fix .. "."
                        .. " migration"
                    ))
                    migration()
                end
            end
        end
    end

    if (migration_start_message_printed) then
        Log.debug(Constants.mod_name .. ": Migration complete")
        game.print({ "initialization.me-migrate-finish", Constants.mod_name})
    end
end

function locals.validate_version(params)
    Log.debug("locals.validate_version")
    Log.info(params)

    local return_val = false

    if (not params or type(params) ~= "table") then return return_val end

    if (    type(params.version_data) == "table"
        and type(params.version_data.major) == "table"
        and type(params.version_data.major.value) == "number"
        and type(params.version_data.minor) == "table"
        and type(params.version_data.minor.value) == "number"
        and type(params.version_data.bug_fix) == "table"
        and type(params.version_data.bug_fix.value) == "number"
        and type(params.version_data.string_val) == "string"
    ) then
        return_val = true
    end

    return return_val
end

return initialization