local ipairs = ipairs
local pairs = pairs
local string_find = string.find

local PLATFROM_PATTERN = "platform%-[%d]*"

To_Set_Game = To_Set_Game or {}

function Set_Game_Funcs()
    local game = _ENV.game

    _ENV.Forces = _ENV.Forces or {}
    Forces = _ENV.Forces
    Forces.list = Forces.list or {}

    _ENV.Force_Funcs = _ENV.Force_Funcs or {}
    Force_Funcs = _ENV.Force_Funcs
    for name, force in pairs(game.forces) do
        if (force.valid) then
            Forces[name] = force
            Forces.list[force.index] = name
            Force_Funcs[name] = Force_Funcs[name] or {}
            Force_Funcs[name].get_evolution_factor = Force_Funcs[name].get_evolution_factor or force.get_evolution_factor
            Force_Funcs[name].get_friend = Force_Funcs[name].get_friend or force.get_friend
            Force_Funcs[name].is_enemy = Force_Funcs[name].is_enemy or force.is_enemy
        else
            Forces[name] = nil
        end
    end

    _ENV.Surfaces = _ENV.Surfaces or {}
    Surfaces = _ENV.Surfaces
    Surfaces.list = Surfaces.list or {}

    _ENV.Surface_Funcs = _ENV.Surface_Funcs or {}
    Surface_Funcs = _ENV.Surface_Funcs
    for name, surface in pairs(game.surfaces) do
        if (surface.valid and not string_find(surface.name, PLATFROM_PATTERN)) then
            Surfaces[name] = surface
            Surfaces.list[surface.index] = name

            Surface_Funcs[name] = Surface_Funcs[name] or {}
            Surface_Funcs[name].build_enemy_base = Surface_Funcs[name].build_enemy_base or surface.build_enemy_base
            Surface_Funcs[name].create_unit_group = Surface_Funcs[name].create_unit_group or surface.create_unit_group
            Surface_Funcs[name].count_entities_filtered = Surface_Funcs[name].count_entities_filtered or surface.count_entities_filtered
            Surface_Funcs[name].find_enemy_units = Surface_Funcs[name].find_enemy_units or surface.find_enemy_units
            Surface_Funcs[name].find_entities_filtered = Surface_Funcs[name].find_entities_filtered or surface.find_entities_filtered
            Surface_Funcs[name].find_non_colliding_position = Surface_Funcs[name].find_non_colliding_position or surface.find_non_colliding_position
            Surface_Funcs[name].request_path = Surface_Funcs[name].request_path or surface.request_path
        else
            Surfaces[name], Surface_Funcs[name] = nil, nil
        end
    end
end
To_Set_Game.set_game_funcs = Set_Game_Funcs

To_Set_Game.to_set = {
    require("scripts.controller.conductor-controller"),
    require("scripts.controller.custodian-controller"),
    require("scripts.controller.chunk-controller"),
    require("scripts.controller.decay-controller"),
    require("scripts.controller.entity-controller"),
    require("scripts.controller.metrics-controller"),
    require("scripts.controller.planet-controller"),
    require("scripts.controller.spawn-controller"),
    require("scripts.data.leaf-data"),
    require("scripts.data.target-registry-data"),
    require("scripts.service.attack-group-service"),
    require("scripts.service.planet-service"),
    require("scripts.service.spawn-service"),
    require("scripts.service.quadtree-service"),
    require("scripts.service.unit-group-service"),
    require("scripts.utils.attack-group-utils"),
    require("scripts.utils.settings-utils"),
    require("scripts.utils.spawn-utils"),
}

function Set_game_all(event)
    local __game, __storage = _ENV.game, _ENV.storage
    __storage.settings_map = __storage.settings_map or {}
    __storage.settings_map.runtime_global = __storage.settings_map.runtime_global or {}

    Forces = Forces or {}
    Surfaces = Surfaces or {}
    Surface_Funcs = Surface_Funcs or {}

    for name, force in pairs(__game.forces) do
        if (force.valid) then
            Forces[name] = force
        else
            Forces[name] = nil
        end
    end
    for name, surface in pairs(__game.surfaces) do
        if (surface.valid) then
            Surfaces[name] = surface
            Surface_Funcs[name] = Surface_Funcs[name] or {
                create_unit_group = surface.create_unit_group,
                request_path = surface.request_path
            }
        else
            Surfaces[name], Surface_Funcs[name] = nil, nil
        end
    end

    for _, v in ipairs(To_Set_Game.to_set or {}) do
        if (type(v.set_game) == "function") then
            v.set_game(event, __game, __storage)
        end
    end
end
To_Set_Game.set_game_all = Set_game_all
Event_Handler:register_events({
    {
        event_name = Custom_Events.me_on_init_complete.name,
        source_name = "To_Set_Game.set_game_all",
        func_name = "To_Set_Game.set_game_all",
        func = To_Set_Game.set_game_all,
    },
    {
        event_name = Custom_Events.me_migrations_applied.name,
        source_name = "To_Set_Game.set_game_all",
        func_name = "To_Set_Game.set_game_all",
        func = To_Set_Game.set_game_all,
    },
    {
        event_name = "on_configuration_changed",
        source_name = "To_Set_Game.set_game_all",
        func_name = "To_Set_Game.set_game_all",
        func = To_Set_Game.set_game_all,
    }
})

return To_Set_Game