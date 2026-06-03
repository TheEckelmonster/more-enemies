local ipairs = ipairs

To_Set_Game = To_Set_Game or {
    to_set = {
        require("scripts.controller.conductor-controller"),
        require("scripts.controller.chunk-controller"),
        require("scripts.controller.decay-controller"),
        require("scripts.controller.entity-controller"),
        require("scripts.controller.metrics-controller"),
        require("scripts.controller.planet-controller"),
        require("scripts.controller.spawn-controller"),
        require("scripts.data.leaf-data"),
        require("scripts.service.attack-group-service"),
        require("scripts.service.planet-service"),
        require("scripts.service.spawn-service"),
        require("scripts.service.quadtree-service"),
        require("scripts.service.unit-group-service"),
        require("scripts.utils.attack-group-utils"),
        require("scripts.utils.settings-utils"),
        require("scripts.utils.spawn-utils"),
    }
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