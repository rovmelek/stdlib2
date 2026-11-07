--- Tools for working with trains.
-- When this module is loaded into a mod, it automatically registers a number of new events in order to keep track of
-- the trains as their locomotives and wagons are moved around.
-- <p>To handle the events, you should use the @{Event} module.
-- @module Event.Trains

local Trains = {
    __class = 'Trains',
    __index = require('__stdlib2__/stdlib/core')
}
setmetatable(Trains, Trains)

local Event = require('__stdlib2__/stdlib/event/event')
local Storage = require('__stdlib2__/stdlib/utils/storage')
local Surface = require('__stdlib2__/stdlib/area/surface')
local Entity = require('__stdlib2__/stdlib/entity/entity')
local table = require('__stdlib2__/stdlib/utils/table')

--- This event fires when a train's ID changes.
-- <p>The train ID is `LuaTrain.id`. Factorio creates a new train (with a new id) when trains are coupled, split or
-- otherwise rebuilt; this event is raised from `on_train_created` for every old train id that was known to the registry.
-- @event on_train_id_changed
-- @tparam uint old_id the ID of the train before the change
-- @tparam uint new_id the ID of the train after the change
-- @usage
---- Event.register(Trains.on_train_id_changed, my_handler)
Trains.on_train_id_changed = Event.generate_event_name('on_train_id_changed')

--- Given a @{criteria|search criteria}, search for trains that match the criteria.
-- If ***criteria.surface*** is not supplied, this function searches through all existing surfaces.
-- If ***criteria.force*** is not supplied, this function searches through all existing forces.
-- If ***criteria.state*** is not supplied, this function gets trains in any @{defines.train_state|state}.
-- @tparam criteria criteria a table used to search for trains
-- @return (<span class="types">{@{train_details},...}</span>) an array of train IDs and LuaTrain instances
-- @usage
-- Trains.find_filtered({ surface = "nauvis", state = defines.train_state.wait_station })
function Trains.find_filtered(criteria)
    criteria = criteria or {}

    local results = {}
    local function collect(filter)
        for _, train in pairs(game.train_manager.get_trains(filter)) do
            results[#results + 1] = train
        end
    end

    if criteria.surface == nil then
        collect({ force = criteria.force })
    else
        for _, surface in pairs(Surface.lookup(criteria.surface)) do
            collect({ surface = surface, force = criteria.force })
        end
    end

    -- Apply state filters
    if criteria.state then
        results = table.filter(results, function(train)
            return train.state == criteria.state
        end)
    end

    -- Lastly, look up the train ids
    return table.map(results, function(train)
        return { train = train, id = train.id }
    end)
end

---
-- This table should be passed into @{find_filtered} to find trains that match the criteria.
-- @tfield[opt] ?|nil|string|{string,...}|LuaSurface|{LuaSurface,...} surface the surfaces to look up for the trains
-- @tfield[opt] ?|nil|string|LuaForce force the force of the trains to search
-- @tfield[opt] ?|nil|defines.train_state state the state of the trains to search
-- @table criteria

---
-- @{find_filtered} returns an array with one or more of ***this*** table based on the @{criteria|search criteria}.
-- @tfield LuaTrain train an instance of the train
-- @tfield uint id the ID of the train
-- @table train_details

--- Find the ID of a LuaTrain instance.
-- Since Factorio 2.x this is the stable `LuaTrain.id`.
-- @tparam LuaTrain train
-- @treturn uint the ID of the train
function Trains.get_train_id(train)
    return train and train.valid and train.id or nil
end

--- Remove invalid trains from the registry.
-- Train ids are renamed by `on_train_created`; this drops the entries of trains that were removed completely and is
-- called when rolling stock dies or is mined.
-- @lfunction
function Trains._on_locomotive_changed()
    local registry = Storage.get(Storage.KEYS.train_registry) or {}
    for id, train in pairs(registry) do
        if not train.valid then
            registry[id] = nil
        end
    end
end

--- Get the main locomotive of a train.
-- @tparam LuaTrain train
-- @treturn LuaEntity the main locomotive
function Trains.get_main_locomotive(train)
    if train and train.valid and train.locomotives and (#train.locomotives.front_movers > 0 or #train.locomotives.back_movers > 0) then
        return train.locomotives.front_movers and train.locomotives.front_movers[1] or train.locomotives.back_movers[1]
    end
end

--- Creates an entity from a train that is compatible with the @{Entity.Entity} module.
-- @tparam LuaTrain train
-- @return (<span class="types">@{train_entity}</span>)
function Trains.to_entity(train)
    local name = 'train-' .. tostring(Trains.get_train_id(train))
    return {
        name = name,
        valid = train.valid,
        equals = function(entity)
            return name == entity.name
        end
    }
end

------
-- @{to_entity} returns ***this*** table.
-- @tfield string name the name of the train entity with the train ID as its suffix
-- @tfield boolean valid whether or not if the train is in a valid state in the game
-- @tfield function equals &mdash; *function(entity)* &mdash; a function to check if another entity is equal to the train that ***this*** table represents
-- @table train_entity

--- Associates the user data to a train.
-- This is a helper around @{Entity.Entity.set_data}.
-- <p>The user data will be stored in the global object and it will persist between loads.
--> The user data will be removed from a train when the train becomes invalid.
-- @tparam LuaTrain train the train to set the user data for
-- @tparam ?|nil|Mixed data the user data to set, or nil to delete the user data associated with the train
-- @treturn ?|nil|Mixed the previous user data or nil if the train had no previous user data
function Trains.set_data(train, data)
    return Entity.set_data(Trains.to_entity(train), data)
end

--- Gets the user data that is associated with a train.
-- This is a helper around @{Entity.Entity.get_data}.
-- <p>The user data is stored in the global object and it persists between loads.
--> The user data will be removed from a train when the train becomes invalid.
-- @tparam LuaTrain train the train to look up user data for
-- @treturn ?|nil|Mixed the user data, or nil if no user data exists for the train
function Trains.get_data(train)
    return Entity.get_data(Trains.to_entity(train))
end

-- Trains.set_data of stdlib2 2.0.x was keyed by the unit number of the main locomotive ('train-<unit_number>').
-- Move that data to the 'train-<LuaTrain.id>' keys, once: both are plain numbers, running it twice would mix them up.
local function migrate_train_data(registry)
    if Storage.get(Storage.KEYS.train_data_migrated) then
        return
    end
    local entity_data = Storage.get(Storage.KEYS.entity_data)
    if entity_data then
        local moved = {}
        for id, train in pairs(registry) do
            local locomotive = Trains.get_main_locomotive(train)
            local old_name = locomotive and locomotive.unit_number and ('train-' .. locomotive.unit_number)
            local new_name = 'train-' .. id
            if old_name and old_name ~= new_name and entity_data[old_name] then
                moved[new_name] = entity_data[old_name]
                entity_data[old_name] = nil
            end
        end
        for new_name, entries in pairs(moved) do
            for _, entry in pairs(entries) do
                entry.entity = Trains.to_entity(registry[tonumber(new_name:sub(7))])
            end
            entity_data[new_name] = entries
        end
    end
    Storage.set(Storage.KEYS.train_data_migrated, true)
end

-- Creates a registry of known trains.
-- The registry is rebuilt from scratch, so registries saved with the 1.x keys (the unit number of the main
-- locomotive) are migrated to the `LuaTrain.id` keys.
-- @return table a mapping of train id to LuaTrain object
function Trains.create_train_registry()
    local registry = Storage.set(Storage.KEYS.train_registry, {})

    for _, info in pairs(Trains.find_filtered()) do
        if info.train.valid then
            registry[info.id] = info.train
        end
    end

    migrate_train_data(registry)
    return registry
end

--- Handles `on_train_created`: renames the registry entries of the old trains and registers the new one.
function Trains.on_train_created(event)
    local registry = Storage.get(Storage.KEYS.train_registry, Storage.new_table)
    local new_id = event.train.id

    for _, old_id in pairs { event.old_train_id_1, event.old_train_id_2 } do
        if old_id and registry[old_id] and old_id ~= new_id then
            registry[old_id] = nil
            Event.dispatch {
                old_id = old_id,
                new_id = new_id,
                name = Trains.on_train_id_changed
            }
        end
    end

    registry[new_id] = event.train
end

--- This needs to be called to register events for this module
-- @treturn Trains
function Trains.register_events()
    -- Train ids (and renames) are driven by on_train_created
    Event.register(defines.events.on_train_created, Trains.on_train_created)

    -- A train that is removed completely (last rolling stock mined or destroyed) gets no on_train_created
    local rolling_stock = {}
    for _, type_name in pairs { 'locomotive', 'cargo-wagon', 'fluid-wagon', 'artillery-wagon' } do
        rolling_stock[#rolling_stock + 1] = { filter = 'type', type = type_name }
    end
    for _, name in pairs { 'on_entity_died', 'on_player_mined_entity', 'on_robot_mined_entity' } do
        Event.register(defines.events[name], Trains._on_locomotive_changed, nil, nil, { event_filter = rolling_stock })
    end

    -- When the mod is initialized the first time
    Event.register(Event.core_events.init_and_config, Trains.create_train_registry)
    return Trains
end

return Trains
