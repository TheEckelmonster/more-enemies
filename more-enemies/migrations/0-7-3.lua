local pairs = pairs
local table_insert = table.insert


local Attack_Group_Constants = require("libs.constants.attack-group-constants")
local Attack_Group_Data = require("scripts.data.attack-group-data")

local Constants = require("scripts.constants.constants")

local Settings_Service = require("scripts.service.settings-service")
local Settings_Utils = require("scripts.utils.settings-utils")

local Version_Data = require("scripts.data.version-data")

local blacklist_names = Settings_Utils.get_attack_group_blacklist_names()

local names = {}

if (blacklist_names) then
    for _, v in pairs(blacklist_names) do
        table_insert(names, v)
    end
end

if (next(names, nil) == nil) then names = nil end

local function migrate(params)
    storage = {}

    local version_data = Version_Data:new()
    storage.version_data = version_data
    version_data.valid = true

    storage.settings = storage.settings or {}
    storage.settings.startup = storage.settings.startup or {}
    storage.settings.runtime_global = storage.settings.runtime_global or {}

    storage.surface_creation = storage.surface_creation or {}

    storage.settings = storage.settings or {}

    storage.planet_chunks = storage.planet_chunks or {}

    local get_surface = game.get_surface
    local tick =  game.tick
    for name, _ in pairs(Constants.DEFAULTS.planets or {}) do
        local surface = get_surface(name)

        if (surface and surface.valid) then
            storage.surface_creation = storage.surface_creation or {}
            storage.surface_creation[name] = storage.surface_creation[name] or surface.index == 1 and 0 or tick

            storage.surfaces = storage.surfaces or {}
            storage.surfaces[name] = storage.surfaces[name] or {}
            storage.surfaces[name].iterator = storage.surfaces[name].iterator or surface.get_chunks()

            local iterator = storage.surfaces[name].iterator
            if (iterator and iterator.valid) then
                storage.surfaces[name].chunks = storage.surfaces[name].chunks or {}
                local chunks = storage.surfaces[name].chunks

                storage.surfaces[name].spawner_map = storage.surfaces[name].spawner_map or {}
                local spawner_map = storage.surfaces[name].spawner_map

                storage.surfaces[name].chunk_map = storage.surfaces[name].chunk_map or {}
                local chunk_map = storage.surfaces[name].chunk_map

                local is_chunk_generated = surface.is_chunk_generated
                local count_entities_filtered = surface.count_entities_filtered

                for chunk in iterator do
                    if (is_chunk_generated(chunk)) then

                        chunk.xy = chunk.x .. "/" .. chunk.y

                        local area = {
                            { x = chunk.x * Constants.CHUNK_SIZE, y = chunk.y * Constants.CHUNK_SIZE, },
                            { x = chunk.x * Constants.CHUNK_SIZE + Constants.CHUNK_SIZE, y = chunk.y * Constants.CHUNK_SIZE + Constants.CHUNK_SIZE, },
                        }

                        chunk.spawner_count = count_entities_filtered({
                            area = area,
                            type = { "unit-spawner", },
                            force = { "enemy", },
                        })

                        if (chunk.spawner_count > 0) then
                            spawner_map[chunk.xy] = chunk
                        end

                        chunk.entity_count = count_entities_filtered({
                            area = area,
                            name = names,
                            type = Attack_Group_Constants.type_blacklist,
                            force = { "enemy", "neutral" },
                            invert = true,
                        })

                        if (chunk.entity_count > 0) then
                            chunk_map[chunk.xy] = chunk
                            chunks[#chunks+1] = chunk
                        end
                    end
                end
            end
        end
    end

    local get_do_attack_group = Settings_Service.get_do_attack_group
    for k, c_planet in pairs(Constants.DEFAULTS.planets) do
        if (c_planet and get_do_attack_group(c_planet.string_val)) then
            local surface = get_surface(c_planet.string_val)
            if (not surface or not surface.valid) then goto continue end

            storage.attack_groups = storage.attack_groups or {}
            storage.attack_groups[c_planet.string_val] = storage.attack_groups[c_planet.string_val] or Attack_Group_Data:new({ surface_name = c_planet.string_val, })
        end

        ::continue::
    end
end

return migrate