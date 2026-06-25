-- local storage = storage
if (not storage) then return end

storage.num_clones = nil

local Leaf_Data = require("scripts.data.leaf-data")
local new_Leaf_Data = Leaf_Data.new
local Quadtree_Service = require("scripts.service.quadtree-service")
local add_node = Quadtree_Service.add_node
local Simple_Queue = require("scripts.data.simple-queue")
local new_Simple_Queue = Simple_Queue.new
local Stats_Data = require("scripts.data.stats-data")
local game = game

local function init_stats(__game)
    __game = __game or game or _ENV.game
    storage.stats = Stats_Data:new({ tick = __game and __game.tick or 0, })
end

local pairs = pairs
local table_insert = table.insert

local To_Set_Game = To_Set_Game

local Attack_Group_Constants = require("settings.startup.attack-group-constants")
local Coordinate_Utils = require("scripts.utils.coordinate-utils")
local pack_coordinates = Coordinate_Utils.pack
local Quad_Meta_Data = Quad_Meta_Data or require("scripts.data.quad-meta-data")
local new_template = Quad_Meta_Data.new_template

local Constants = require("scripts.constants.constants")

local Settings_Utils = require("scripts.utils.settings-utils")

local prototypes = prototypes
local mod_data = prototypes.mod_data
local planets = mod_data[Constants.mod_name .. "-planet-data"]

local blacklist_names = Settings_Utils.get_attack_group_blacklist_names()

local names = {}

if (blacklist_names) then
    for _, v in pairs(blacklist_names) do
        table_insert(names, v)
    end
end

if (next(names, nil) == nil) then names = nil end

local unit_spawner_type_tbl = { "unit-spawner", }
local enemy_force_tbl = { "enemy", }
local player_force_inverse_tbl = { "enemy", "neutral" }

local function migrate(params)
    params = params or {}

    local storage = _ENV.storage

    game = game or _ENV.game

    storage.settings_map = storage.settings_map or {}
    storage.settings_map.startup = storage.settings_map.startup or {}
    storage.settings_map.runtime_global = storage.settings_map.runtime_global or {}

    storage.surface_creation = storage.surface_creation or {}
    storage.surfaces = storage.surfaces or {}
    storage.quadtrees = storage.quadtrees or {}

    local get_surface = game.get_surface
    local tick =  game.tick
    for name, _ in pairs(planets.data or {}) do
        storage.quadtrees[name] = nil
        local surface = get_surface(name)

        if (surface and surface.valid) then
            storage.surface_creation[name] = storage.surface_creation[name] or surface.index == 1 and 0 or tick

            storage.surfaces[name] = storage.surfaces[name] or {}

            local iterator = surface.get_chunks()
            if (iterator and iterator.valid) then
                storage.surfaces[name].chunks = {}
                local chunks = storage.surfaces[name].chunks

                storage.surfaces[name].entity_chunks = {}
                local entity_chunks = storage.surfaces[name].entity_chunks

                storage.surfaces[name].spawner_chunks = {}
                local local_spawner_chunks = storage.surfaces[name].spawner_chunks

                storage.surfaces[name].spawner_maps = {}
                local spawner_map = storage.surfaces[name].spawner_maps

                storage.surfaces[name].chunk_map = {}
                local chunk_map = storage.surfaces[name].chunk_map

                storage.surfaces[name].entity_maps = {}
                local entity_map = storage.surfaces[name].entity_maps

                local is_chunk_generated = surface.is_chunk_generated
                local count_entities_filtered = surface.count_entities_filtered

                for chunk in iterator do
                    if (is_chunk_generated(chunk)) then
                        chunk.xy = pack_coordinates(chunk.x, chunk.y)

                        local area = {
                            { x = chunk.x * Constants.CHUNK_SIZE, y = chunk.y * Constants.CHUNK_SIZE, },
                            { x = chunk.x * Constants.CHUNK_SIZE + Constants.CHUNK_SIZE, y = chunk.y * Constants.CHUNK_SIZE + Constants.CHUNK_SIZE, },
                        }

                        chunk.meta = chunk.meta or new_template(Quad_Meta_Data, tick)
                        local c_meta = chunk.meta

                        c_meta.spawner_count = count_entities_filtered({
                            area = area,
                            type = unit_spawner_type_tbl,
                            force = enemy_force_tbl,
                        })

                        c_meta.entity_count = count_entities_filtered({
                            area = area,
                            name = names,
                            type = Attack_Group_Constants.type_blacklist,
                            force = player_force_inverse_tbl,
                            invert = true,
                        })

                        if (    c_meta.spawner_count > 0
                            or  c_meta.entity_count > 0
                        ) then
                            chunk = new_Leaf_Data(Leaf_Data, chunk, tick)

                            local node, ret_chunk = add_node({
                                tick = tick or 0,
                                source_chunk = chunk,
                                surface_name = name,
                            })

                            chunk_map[chunk.xy] = ret_chunk
                            chunks[#chunks+1] = ret_chunk

                            if (c_meta.spawner_count > 0) then
                                spawner_map[chunk.xy] = ret_chunk
                                local_spawner_chunks[#local_spawner_chunks+1] = ret_chunk
                            end
                            if (c_meta.entity_count > 0) then
                                entity_map[chunk.xy] = ret_chunk
                                entity_chunks[#entity_chunks+1] = ret_chunk
                            end
                        end
                    end
                end
            end
        end
    end

    To_Set_Game.set_game_all()
    init_stats(game or _ENV.game)
end

return migrate