--- Native event filter support for the Event module.
-- Factorio can filter some events before they reach Lua (`script.set_event_filter`). This module knows which
-- events support filters, builds the union of the filters of several handlers and can re-check a filter in Lua
-- for handlers that only want a part of the union.
-- @module Event.NativeFilters

local NativeFilters = {
    __class = 'NativeFilters'
}

-- The events that take an EventFilter (the `Lua*EventFilter` concepts of events.html).
-- TODO(2.1): verify against the events page of the 2.1 API, it lists the filter next to each event.
-- Other mods may add events with `NativeFilters.supported[defines.events.some_event] = true`.
NativeFilters.supported = {}
for _, name in pairs {
    'on_biter_base_built', 'on_built_entity', 'on_cancelled_deconstruction', 'on_cancelled_upgrade',
    'on_entity_cloned', 'on_entity_damaged', 'on_entity_died', 'on_marked_for_deconstruction',
    'on_marked_for_upgrade', 'on_player_mined_entity', 'on_post_entity_died', 'on_pre_ghost_deconstructed',
    'on_pre_ghost_upgraded', 'on_pre_player_mined_item', 'on_robot_built_entity', 'on_robot_mined_entity',
    'on_robot_pre_mined', 'on_script_trigger_effect', 'on_sector_scanned', 'on_segment_entity_created',
    'on_space_platform_built_entity', 'on_space_platform_mined_entity', 'on_space_platform_pre_mined',
    'on_trigger_created_entity', 'script_raised_built', 'script_raised_destroy', 'script_raised_revive'
} do
    local id = defines.events[name]
    if id then
        NativeFilters.supported[id] = true
    end
end

--- Can this event take a native filter?
-- @tparam number event_id
-- @treturn boolean
function NativeFilters.is_supported(event_id)
    return NativeFilters.supported[event_id] == true
end

--- Check the shape of an EventFilter.
-- @tparam table filter
function NativeFilters.validate(filter)
    assert(type(filter) == 'table' and #filter > 0, 'event_filter must be a non empty array of filters')
    for _, entry in ipairs(filter) do
        assert(type(entry) == 'table' and type(entry.filter) == 'string', 'every event_filter entry needs a `filter` string')
    end
end

--- Does the filter array combine entries with `mode = 'and'`? Those can not be merged into a union.
-- @tparam table filter
-- @treturn boolean
function NativeFilters.has_and(filter)
    for i, entry in ipairs(filter) do
        if i > 1 and entry.mode == 'and' then
            return true
        end
    end
    return false
end

--- Build the filter for an event from the filters of all its handlers.
-- Filters of one array are OR-ed by Factorio, so concatenating the arrays is the union.
-- @tparam {table,...} filters the filter array of each handler
-- @treturn table|nil the union, nil if it can not be expressed (an `and` mode is used) and filtering must be off
function NativeFilters.union(filters)
    local result, seen = {}, {}
    for _, filter in ipairs(filters) do
        if not seen[filter] then
            seen[filter] = true
            if NativeFilters.has_and(filter) then
                return nil
            end
            for i, entry in ipairs(filter) do
                if i == 1 and entry.mode and entry.mode ~= 'or' then
                    -- the mode of the first entry means nothing alone, but would combine it with the previous array
                    local copy = {}
                    for k, v in pairs(entry) do copy[k] = v end
                    copy.mode = nil
                    entry = copy
                end
                result[#result + 1] = entry
            end
        end
    end
    return result
end

local function entity_of(event)
    return event.entity or event.created_entity or event.destination
end

local function has_name(value, name)
    if type(value) == 'table' then
        for _, v in pairs(value) do
            if v == name then return true end
        end
        return false
    end
    return value == name
end

-- Evaluate one filter entry against an event. Returns nil if the key is not known.
local function evaluate(entry, event)
    local entity = entity_of(event)
    if not entity then
        return nil
    end
    local is_ghost = entity.type == 'entity-ghost' or entity.type == 'tile-ghost'
    local key = entry.filter
    if key == 'name' then
        return has_name(entry.name, entity.name)
    elseif key == 'type' then
        return has_name(entry.type, entity.type)
    elseif key == 'ghost' then
        return is_ghost
    elseif key == 'ghost_name' then
        return is_ghost and has_name(entry.name, entity.ghost_name)
    elseif key == 'ghost_type' then
        return is_ghost and has_name(entry.type, entity.ghost_type)
    end
    return nil
end

--- Re-check a native filter in Lua.
-- <p>Supports the common keys `name`, `type`, `ghost`, `ghost_name`, `ghost_type` and the `invert` and `mode`
-- fields. Entries with other keys can not be checked and count as a match, so a handler may still see events
-- that Factorio's own filter would have dropped when it shares an event with a differently filtered handler.
-- @tparam table event the event data
-- @tparam table filter the EventFilter array
-- @treturn boolean
function NativeFilters.matches(event, filter)
    local result
    for i, entry in ipairs(filter) do
        local value = evaluate(entry, event)
        if value == nil then
            value = true -- unknown key: skip the re-check
        elseif entry.invert then
            value = not value
        end
        if i == 1 then
            result = value
        elseif entry.mode == 'and' then
            result = result and value
        else
            result = result or value
        end
    end
    return result and true or false
end

return NativeFilters
