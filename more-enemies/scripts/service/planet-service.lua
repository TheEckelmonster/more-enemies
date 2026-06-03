local storage
local surface_creation

local game
local get_surface
local surface_funcs

local Surfaces = Surfaces

local pairs = pairs

local string_find = string.find

local function set_game(event, __game, __storage)
    storage = __storage or _ENV.storage
    storage.surface_creation = storage.surface_creation or {}
    surface_creation = storage.surface_creation

    game = __game or _ENV.game
    get_surface = game.get_surface

    _ENV.Surface_Funcs = _ENV.Surface_Funcs or {}
    Surface_Funcs = _ENV.Surface_Funcs

    _ENV.Surfaces = _ENV.Surfaces or {}
    Surfaces = _ENV.Surfaces
    Surfaces.list = Surfaces.list or {}
    for name, surface in pairs(game.surfaces) do
        if (surface.valid and not string_find(surface.name, "platform%-[%d]*")) then
            Surfaces[name] = surface
            Surfaces.list[surface.index] = name

            Surface_Funcs[name] = Surface_Funcs[name] or {}
            Surface_Funcs[name].create_unit_group = Surface_Funcs[name].create_unit_group or surface.create_unit_group
            Surface_Funcs[name].count_entities_filtered = Surface_Funcs[name].count_entities_filtered or surface.count_entities_filtered
            Surface_Funcs[name].find_entities_filtered = Surface_Funcs[name].find_entities_filtered or surface.find_entities_filtered
            Surface_Funcs[name].find_non_colliding_position = Surface_Funcs[name].find_non_colliding_position or surface.find_non_colliding_position
            Surface_Funcs[name].request_path = Surface_Funcs[name].request_path or surface.request_path
        else
            Surfaces[name], Surface_Funcs[name] = nil, nil
        end
    end
    surface_funcs = Surface_Funcs

    return game
end

local Log = Log

local planet_service = {}
planet_service.name = "planet_service"
planet_service.set_game = set_game

function planet_service.on_surface_created(event)
    -- Log.debug("planet_service.on_surface_created")
    -- Log.info(event)

    if (not event) then return end
    if (not event.surface_index or event.surface_index < 1) then return end

    local surface = game and get_surface(event.surface_index) or set_game().get_surface(event.surface_index)
    if (not surface or not surface.valid) then return end

    local surface_name = surface.name

    Surfaces[surface_name] = surface
    Surfaces.list[surface.index] = name

    surface_funcs = surface_funcs or set_game() and surface_funcs
    surface_funcs[surface_name] = surface_funcs[surface_name] or {}
    surface_funcs[surface_name].create_unit_group = surface.create_unit_group
    surface_funcs[surface_name].request_path = surface.request_path

    surface_creation = surface_creation or set_game() and surface_creation
    surface_creation[surface_name] = event.tick
end

function planet_service.on_surface_deleted(event)
    -- Log.debug("planet_service.on_surface_deleted")
    -- Log.info(event)

    if (not event) then return end
    if (not event.surface_index or event.surface_index < 1) then return end

    Surfaces = Surfaces or set_game() and Surfaces
    Surfaces.list = Surfaces.list or {}
    local surface_name = Surfaces.list[event.surface_index]

    if (surface_name) then
        if (surface_funcs) then surface_funcs[surface_name] = nil end
        if (surface_creation) then surface_creation[surface_name] = nil end
    end
end

function planet_service.on_surface_renamed(event)
    -- Log.debug("planet_service.on_surface_renamed")
    -- Log.info(event)

    if (not event) then return end
    if (not event.surface_index or event.surface_index < 1) then return end

    local new_name = event.new_name
    local old_name = event.old_name

    Surfaces[new_name] = Surfaces[old_name]
    Surfaces[old_name] = nil
    Surfaces.list[event.surface_index] = new_name

    surface_funcs = surface_funcs or set_game() and surface_funcs
    surface_funcs[new_name] = surface_funcs[old_name]
    surface_funcs[old_name] = nil

    surface_creation = surface_creation or set_game() and surface_creation
    surface_creation[new_name] = surface_creation[old_name]
    surface_creation[old_name] = nil
end

function planet_service.init(__storage) storage = __storage or _ENV.storage end

return planet_service