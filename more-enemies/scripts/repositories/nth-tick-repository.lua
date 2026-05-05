local storage

local Log = require("libs.log.log")
local More_Enemies_Data = require("scripts.data.more-enemies-data")
local Nth_Tick_Data = require("scripts.data.nth-tick-data")

local nth_tick_repository = {}

function nth_tick_repository.save_nth_tick_cleanup_complete_data(optionals)
    Log.debug("nth_tick_repository.save_nth_tick_cleanup_complete_data")
    Log.info(optionals)

    local return_val = Nth_Tick_Data:new()

    if (not game) then return return_val end

    optionals = optionals or {}

    if (not storage) then return return_val end
    if (not storage.more_enemies) then storage.more_enemies = More_Enemies_Data:new() end
    if (not storage.more_enemies.nth_tick_cleanup_complete) then storage.more_enemies.nth_tick_cleanup_complete = return_val end

    return_val = storage.more_enemies.nth_tick_cleanup_complete
    return_val.created = return_val.created or game.tick

    return nth_tick_repository.update_nth_tick_cleanup_complete_data(return_val)
end

function nth_tick_repository.update_nth_tick_cleanup_complete_data(update_data, optionals)
    Log.debug("nth_tick_repository.update_nth_tick_cleanup_complete_data")
    Log.info(update_data)
    Log.info(optionals)

    local return_val = Nth_Tick_Data:new()

    if (not game) then return return_val end
    if (not update_data) then return return_val end

    optionals = optionals or {}

    if (not storage) then return return_val end
    if (not storage.more_enemies) then storage.more_enemies = More_Enemies_Data:new() end
    if (not storage.more_enemies.nth_tick_cleanup_complete) then
        -- If it doesn't exist, generate it
        storage.more_enemies.nth_tick_cleanup_complete = return_val
        nth_tick_repository.save_nth_tick_cleanup_complete_data()
    end

    local nth_tick_data = storage.more_enemies.nth_tick_cleanup_complete

    for k, v in pairs(update_data) do
        nth_tick_data[k] = v
    end

    nth_tick_data.updated = game.tick

    -- Don't think this is necessary, but oh well
    storage.more_enemies.nth_tick_cleanup_complete = nth_tick_data

    return nth_tick_data
end

function nth_tick_repository.get_nth_tick_cleanup_complete_data(optionals)
    Log.debug("nth_tick_repository.get_nth_tick_cleanup_complete_data")
    Log.info(optionals)

    local return_val = Nth_Tick_Data:new()

    if (not game) then return return_val end

    optionals = optionals or {}

    if (not storage) then return return_val end
    if (not storage.more_enemies) then storage.more_enemies = More_Enemies_Data:new() end
    if (not storage.more_enemies.nth_tick_cleanup_complete) then
        -- If it doesn't exist, generate it
        storage.more_enemies.nth_tick_cleanup_complete = return_val
        nth_tick_repository.save_nth_tick_cleanup_complete_data()
    end

    return storage.more_enemies.nth_tick_cleanup_complete
end

function nth_tick_repository.save_nth_tick_complete_data(optionals)
    Log.debug("nth_tick_repository.save_nth_tick_complete_data")
    Log.info(optionals)

    local return_val = Nth_Tick_Data:new()

    if (not game) then return return_val end

    optionals = optionals or {}

    if (not storage) then return return_val end
    if (not storage.more_enemies) then storage.more_enemies = More_Enemies_Data:new() end
    if (not storage.more_enemies.nth_tick_complete) then storage.more_enemies.nth_tick_complete = return_val end

    return_val = storage.more_enemies.nth_tick_complete
    return_val.created = return_val.created or game.tick

    return nth_tick_repository.update_nth_tick_complete_data(return_val)
end

function nth_tick_repository.update_nth_tick_complete_data(update_data, optionals)
    Log.debug("nth_tick_repository.update_nth_tick_complete_data")
    Log.info(update_data)
    Log.info(optionals)

    local return_val = Nth_Tick_Data:new()

    if (not game) then return return_val end
    if (not update_data) then return return_val end

    optionals = optionals or {}

    if (not storage) then return return_val end
    if (not storage.more_enemies) then storage.more_enemies = More_Enemies_Data:new() end
    if (not storage.more_enemies.nth_tick_complete) then
        -- If it doesn't exist, generate it
        storage.more_enemies.nth_tick_complete = return_val
        nth_tick_repository.save_nth_tick_complete_data()
    end

    local nth_tick_data = storage.more_enemies.nth_tick_complete

    for k, v in pairs(update_data) do
        nth_tick_data[k] = v
    end

    nth_tick_data.updated = game.tick

    -- Don't think this is necessary, but oh well
    storage.more_enemies.nth_tick_complete = nth_tick_data

    return nth_tick_data
end

function nth_tick_repository.get_nth_tick_complete_data(optionals)
    Log.debug("nth_tick_repository.get_nth_tick_complete_data")
    Log.info(optionals)

    local return_val = Nth_Tick_Data:new()

    if (not game) then return return_val end

    optionals = optionals or {}

    if (not storage) then return return_val end
    if (not storage.more_enemies) then storage.more_enemies = More_Enemies_Data:new() end
    if (not storage.more_enemies.nth_tick_complete) then
        -- If it doesn't exist, generate it
        storage.more_enemies.nth_tick_complete = return_val
        nth_tick_repository.save_nth_tick_complete_data()
    end

    return storage.more_enemies.nth_tick_complete
end

function nth_tick_repository.init(__storage)
    storage = __storage
end

return nth_tick_repository