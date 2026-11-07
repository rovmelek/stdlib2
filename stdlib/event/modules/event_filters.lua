--- Event Filters
-- Predefined event filter functions
-- @module Event.Filters

local Filters = {
    entity = {},
    player = {},
}

--- Builders for native event filters, to be passed as `options.event_filter` of @{Event.register}.
-- @usage
-- Event.register(defines.events.on_built_entity, handler, nil, nil, { event_filter = Event.Filters.native.name('iron-chest') })
Filters.native = {}

--- Filter on the entity name.
-- @tparam string|{string,...} name
-- @treturn table an EventFilter array
function Filters.native.name(name)
    return { { filter = 'name', name = name } }
end

--- Filter on the entity type.
-- @tparam string|{string,...} type
-- @treturn table an EventFilter array
function Filters.native.type(type)
    return { { filter = 'type', type = type } }
end

--- Filter on ghosts.
-- @tparam[opt=true] boolean ghost false for entities that are not ghosts
-- @treturn table an EventFilter array
function Filters.native.ghost(ghost)
    return { { filter = 'ghost', invert = ghost == false or nil } }
end

--- Filter on the name of the entity a ghost represents.
-- @tparam string|{string,...} name
-- @treturn table an EventFilter array
function Filters.native.ghost_name(name)
    return { { filter = 'ghost_name', name = name } }
end

--- Filter on the type of the entity a ghost represents.
-- @tparam string|{string,...} type
-- @treturn table an EventFilter array
function Filters.native.ghost_type(type)
    return { { filter = 'ghost_type', type = type } }
end

function Filters.on_key(event_key, pattern)
    return function(event)
        local key = event and event[event_key]
        return key and key:match(pattern)
    end
end

-- Find the entity of an event: `entity` (2.x), then the deprecated `created_entity`, then `destination` (on_entity_cloned).
local function get_entity(event)
    local entity = event and (event.entity or event.created_entity or event.destination)
    if entity and entity.valid then
        return entity
    end
end

function Filters.entity.name(event, pattern)
    local entity = get_entity(event)
    return entity and entity.name:match(pattern)
end

function Filters.entity.type(event, pattern)
    local entity = get_entity(event)
    return entity and entity.type:match(pattern)
end

function Filters.player.cursor_stack(event, pattern)
    local player = game.get_player(event.player_index)
    local stack = player.cursor_stack
    return stack and stack.valid_for_read and stack.name:match(pattern)
end

function Filters.gui(event, pattern)
    if event.element and event.element.valid then
        local match_str = event.element.name:match(pattern)
        if match_str then
            event.match = match_str
            event.state = event.name == defines.events.on_gui_checked_state_changed and event.element.state or nil
            event.text = event.name == defines.events.on_gui_text_changed and event.element.text or nil
            return match_str
        end
    end
end

return Filters
