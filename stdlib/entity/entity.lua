--- Tools for working with entities.
-- @module Entity.Entity
-- @usage local Entity = require('__stdlib2__/stdlib/entity/entity')

local Entity = {
    __class = 'Entity',
    __index = require('__stdlib2__/stdlib/core')
}
setmetatable(Entity, Entity)

--- Tests whether an entity has access to a given field.
-- @tparam LuaEntity entity the entity to test the access to a field
-- @tparam string field_name the field name
-- @treturn boolean true if the entity has access to the field, false if the entity threw an exception when trying to access the field
function Entity.has(entity, field_name)
    assert(entity, 'missing entity argument')
    assert(field_name, 'missing field name argument')

    local status =
    pcall(
        function()
            return entity[field_name]
        end
    )
    return status
end

local Storage = require('__stdlib2__/stdlib/utils/storage')

--- Options of this module.
-- <ul>
-- <li>`auto_cleanup` (default `true`): data stored with @{set_data} for entities that have a `unit_number` is removed
-- when the entity is destroyed. This registers `on_object_destroyed` through the @{Event} module, so load
-- @{Event} before this module, otherwise the cleanup can not be restored in `on_load`.
-- </ul>
Entity.options = {
    auto_cleanup = true
}

local EVENT_PATH = '__stdlib2__/stdlib/event/event'

-- Remove entries of invalid entities from a name keyed list.
local function prune(entity_category)
    for i = #entity_category, 1, -1 do
        local entry_entity = entity_category[i].entity
        if entry_entity == nil or entry_entity.valid == false then
            table.remove(entity_category, i)
        end
    end
end

--- Handler of `on_object_destroyed`, removes the data of destroyed entities.
-- @tparam table event
function Entity._on_object_destroyed(event)
    local registrations = Storage.get(Storage.KEYS.entity_data_reg)
    local unit_number = registrations and registrations[event.registration_number]
    if unit_number then
        registrations[event.registration_number] = nil
        local entity_data = Storage.get(Storage.KEYS.entity_data)
        if entity_data then
            entity_data[unit_number] = nil
        end
    end
end

local cleanup_registered_with
local warned_no_event

--- Register the cleanup handler of destroyed entities with the Event module.
-- This is called automatically when data is stored. The @{Event} module has to be loaded (required) in the main
-- chunk, ideally before this module: `require` is not allowed once the game runs, and the `on_load` and
-- `on_configuration_changed` hooks of this module only exist when Event was loaded first.
-- If you load Event after this module, call `Entity.register_cleanup()` from your own `on_load` handler too.
-- @treturn boolean true if the handler is registered
function Entity.register_cleanup()
    local Event = package.loaded[EVENT_PATH]
    if not Event then
        if not warned_no_event then
            warned_no_event = true
            log('[stdlib2] Entity data cleanup is off: require the Event module in the main chunk of control.lua.')
        end
        return false
    end
    if cleanup_registered_with ~= Event then
        cleanup_registered_with = Event
        Event.register(defines.events.on_object_destroyed, Entity._on_object_destroyed)
    end
    return true
end

--- Restore the cleanup handler in `on_load`: it has to be registered identically for all players.
function Entity.restore_cleanup()
    -- The key is created together with the first registration and never removed, so it tells whether the handler
    -- was registered during the session that made the save, even if every registration was cleaned up since.
    local registrations = Storage.get(Storage.KEYS.entity_data_reg)
    if Entity.options.auto_cleanup and registrations ~= nil then
        Entity.register_cleanup()
    end
end

--- After a configuration change register the entities that already have data for destruction.
-- Entities that can not be found by unit number keep their data (the lookup does not work for all prototypes).
function Entity._migrate_cleanup()
    local entity_data = Storage.get(Storage.KEYS.entity_data)
    if not (Entity.options.auto_cleanup and entity_data and script.register_on_object_destroyed) then
        return
    end
    -- Collect first: the registrations table (the flag `restore_cleanup` looks at) may only be created together
    -- with the handler registration, otherwise on_load would register a handler the saving session did not have.
    local found_entities = {}
    for key in pairs(entity_data) do
        if type(key) == 'number' then
            local found = game.get_entity_by_unit_number(key)
            if found and found.valid then
                found_entities[key] = found
            end
        end
    end
    if next(found_entities) and Entity.register_cleanup() then
        local registrations = Storage.get(Storage.KEYS.entity_data_reg, Storage.new_table)
        for key, found in pairs(found_entities) do
            registrations[(script.register_on_object_destroyed(found))] = key
        end
    end
end

do
    -- Hook on_load and on_configuration_changed when the Event module is already loaded (its usual place is first).
    local Event = package.loaded[EVENT_PATH]
    if Event then
        Event.on_load(Entity.restore_cleanup)
        Event.on_configuration_changed(Entity._migrate_cleanup)
    end
end

--- Gets the user data that is associated with an entity.
-- The user data is stored in the storage object and it persists between loads.
--> The user data will be removed from an entity when the entity becomes invalid.
-- @tparam LuaEntity entity the entity to look up the user data for
-- @treturn ?|nil|Mixed the user data, or nil if the entity has no user data
function Entity.get_data(entity)
    assert(entity, 'missing entity argument')
    local entity_data = Storage.get(Storage.KEYS.entity_data)
    if not entity_data then
        return nil
    end

    local unit_number = entity.unit_number
    if unit_number then
        return entity_data[unit_number]
    else
        local entity_category = entity_data[entity.name]
        if not entity_category then
            return nil
        end

        prune(entity_category)
        for _, entry in pairs(entity_category) do
            if Entity._are_equal(entry.entity, entity) then
                return entry.data
            end
        end
        return nil
    end
end

--- Associates the user data to an entity.
-- The user data will be stored in the storage object and it will persist between loads.
--> The user data will be removed from an entity when the entity becomes invalid.
-- @tparam LuaEntity entity the entity with which to associate the user data
-- @tparam ?|nil|Mixed data the data to set, or nil to delete the data associated with the entity
-- @treturn ?|nil|Mixed the previous data associated with the entity, or nil if the entity had no previous data
function Entity.set_data(entity, data)
    assert(entity, 'missing entity argument')

    local entity_data = Storage.get(Storage.KEYS.entity_data, Storage.new_table)

    local unit_number = entity.unit_number
    if unit_number then
        local prev = entity_data[unit_number]
        entity_data[unit_number] = data
        if data ~= nil and prev == nil and Entity.options.auto_cleanup and script and script.register_on_object_destroyed
            and Entity.register_cleanup() then
            local registrations = Storage.get(Storage.KEYS.entity_data_reg, Storage.new_table)
            registrations[(script.register_on_object_destroyed(entity))] = unit_number
        end
        return prev
    else
        local entity_name = entity.name
        entity_data[entity_name] = entity_data[entity_name] or {}
        local entity_category = entity_data[entity_name]

        prune(entity_category)
        for i = #entity_category, 1, -1 do
            local entry = entity_category[i]
            if Entity._are_equal(entry.entity, entity) then
                local prev = entry.data
                if data then
                    entry.data = data
                else
                    table.remove(entity_category, i)
                end
                return prev
            end
        end
        if data ~= nil then
            table.insert(entity_category, { entity = entity, data = data })
        end
    end
    return nil
end

--- Freezes an entity, by making it inactive, inoperable, and non-rotatable, or unfreezes by doing the reverse.
-- @tparam LuaEntity entity the entity to freeze or unfreeze
-- @tparam[opt=true] boolean mode if true, freezes the entity, if false, unfreezes the entity. If not specified, it is set to true
-- @treturn LuaEntity the entity that has been frozen or unfrozen
function Entity.set_frozen(entity, mode)
    assert(entity, 'missing entity argument')
    assert(type(entity) == 'table' or type(entity) == 'userdata', 'entity must be a LuaEntity')
    mode = mode == false and true or false
    entity.active = mode
    entity.operable = mode
    entity.rotatable = mode
    return entity
end

--- Makes an entity indestructible so that it cannot be damaged or mined neither by the player nor by their enemy factions.
-- @tparam LuaEntity entity the entity to make indestructable
-- @tparam[opt=true] boolean mode if true, makes the entity indestructible, if false, makes the entity destructable
-- @treturn LuaEntity the entity that has been made indestructable or destructable
function Entity.set_indestructible(entity, mode)
    assert(entity, 'missing entity argument')
    assert(type(entity) == 'table' or type(entity) == 'userdata', 'entity must be a LuaEntity')
    mode = mode == false and true or false
    entity.minable = mode
    entity.destructible = mode
    return entity
end

--- Tests if two entities are equal.
-- If they don't have a reference equality and ***entity\_a*** has ***equals*** function, it will be called with ***entity\_b*** as its first argument.
-- @tparam LuaEntity entity_a
-- @tparam LuaEntity entity_b
-- @treturn boolean
function Entity._are_equal(entity_a, entity_b)
    if entity_a == nil then
        return entity_a == entity_b
    elseif entity_a == entity_b then
        return true
    elseif Entity.has(entity_a, 'equals') and entity_a.equals ~= nil then
        return entity_a.equals(entity_b)
    else
        return false
    end
end

function Entity.find_resources(entity, all)
    if entity.type == 'mining-drill' then
        local prototype = entity.prototype
        -- Reading a key a LuaObject does not have raises, so every lookup is guarded.
        -- TODO(2.1): verify which of the two exists in 2.1; the method takes the quality into account.
        local radius
        local ok, value = pcall(function() return prototype.get_mining_drill_radius(entity.quality) end)
        if ok and value then
            radius = value
        else
            ok, value = pcall(function() return prototype.mining_drill_radius end)
            radius = ok and value or nil
        end
        local name = (not all and (entity.mining_target and entity.mining_target.name)) or nil
        return entity.surface.count_entities_filtered {
            type = 'resource',
            name = name,
            position = entity.position,
            radius = radius,
        }
    end
    return 0
end

function Entity.is_damaged(entity)
    return entity.get_health_ratio() < 1
end
Entity.damaged = Entity.is_damaged

local circuit_ids = { 'circuit_red', 'circuit_green' }
local circuit_connector_ids = {
    'circuit_red', 'circuit_green', 'combinator_input_red', 'combinator_input_green',
    'combinator_output_red', 'combinator_output_green'
}

--- Is the entity connected to at least one other entity with a red or green circuit wire?
-- @tparam LuaEntity entity
-- @treturn boolean
function Entity.is_circuit_connected(entity)
    for _, id_name in pairs(circuit_ids) do
        local wire_id = defines.wire_connector_id[id_name]
        local ok, network = pcall(entity.get_circuit_network, wire_id)
        if ok and network then
            local count = network.connected_circuit_count
            if count == nil or count > 1 then
                return true
            end
        end
    end
    return false
end

--- Count the circuit wires (red and green) connected to the entity.
-- @tparam LuaEntity entity
-- @treturn uint
function Entity.count_circuit_connections(entity)
    local ok, connectors = pcall(entity.get_wire_connectors, false)
    local count = 0
    if ok and connectors then
        -- defines.wire_connector_id aliases values (circuit_red == combinator_input_red, ...), count each id once
        local seen = {}
        for _, id_name in pairs(circuit_connector_ids) do
            local id = defines.wire_connector_id[id_name]
            if id and not seen[id] then
                seen[id] = true
                local connector = connectors[id]
                if connector then
                    count = count + connector.connection_count
                end
            end
        end
    end
    return count
end

function Entity.has_fluidbox(entity)
    local box = entity.fluidbox
    return box and #box > 0
end

function Entity.can_deconstruct(entity)
    return entity.minable and entity.prototype.selectable_in_game and not entity.has_flag('not-deconstructable')
end

return Entity
