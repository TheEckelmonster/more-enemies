local storage

local Log = require("libs.log.log")
local More_Enemies_Data = require("scripts.data.more-enemies-data")
local Version_Data = require("scripts.data.version-data")

local more_enemies_repository = {}

function more_enemies_repository.save_more_enemies_data(optionals)
    Log.debug("more_enemies_repository.save_more_enemies_data")
    Log.info(optionals)

    local return_val = More_Enemies_Data:new()

    if (not game) then return return_val end

    optionals = optionals or {}

    if (not storage) then return return_val end
    if (not storage.more_enemies) then storage.more_enemies = return_val end

    return_val = storage.more_enemies
    return_val.created = return_val.created or game.tick
    return_val.updated = return_val.updated or game.tick

    return more_enemies_repository.update_more_enemies_data(return_val)
end

function more_enemies_repository.update_more_enemies_data(update_data, optionals)
    Log.debug("more_enemies_repository.update_more_enemies_data")
    Log.info(update_data)
    Log.info(optionals)

    local return_val = More_Enemies_Data:new()

    if (not game) then return return_val end
    if (not update_data) then return return_val end

    optionals = optionals or {}

    if (not storage) then return return_val end
    if (not storage.more_enemies) then
        -- If it doesn't exist, generate it
        storage.more_enemies = return_val
        more_enemies_repository.save_more_enemies_data()
    end

    local more_enemies_data = storage.more_enemies

    for k, v in pairs(update_data) do
        more_enemies_data[k] = v
    end

    more_enemies_data.updated = game.tick

    -- Don't think this is necessary, but oh well
    storage.more_enemies = more_enemies_data

    return more_enemies_data
end

function more_enemies_repository.get_more_enemies_data(optionals)
    Log.debug("more_enemies_repository.get_more_enemies_data")
    Log.info(optionals)

    local return_val = More_Enemies_Data:new()

    if (not game) then return return_val end

    optionals = optionals or {}

    if (not storage) then return return_val end
    if (not storage.more_enemies) then
        -- If it doesn't exist, generate it
        storage.more_enemies = return_val
        more_enemies_repository.save_more_enemies_data()
    end

    -- if (storage.more_enemies.version_data.string_val ~= Version_Data:to_string()) then
    --     storage.more_enemies.valid = false
    -- end

    return storage.more_enemies
end

function more_enemies_repository.init(__storage)
    storage = __storage
end

return more_enemies_repository