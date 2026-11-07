require('spec/setup/busted')()

local Env = require('spec/setup/factorio_env')

describe('Event native filters', function()
    local Event, F
    local built

    local function entity(name, type)
        return { valid = true, name = name, type = type or 'container', __self = true }
    end

    local function last_filter_call()
        return script.filter_calls[#script.filter_calls]
    end

    before_each(function()
        Env.install()
        Event = require('__stdlib2__/stdlib/event/event')
        F = Event.Filters.native
        built = defines.events.on_built_entity
    end)

    it('F.* builders create EventFilter arrays', function()
        assert.same({ { filter = 'name', name = 'iron-chest' } }, F.name('iron-chest'))
        assert.same({ { filter = 'type', type = 'container' } }, F.type('container'))
        assert.same({ { filter = 'ghost' } }, F.ghost())
        assert.same({ { filter = 'ghost', invert = true } }, F.ghost(false))
        assert.same({ { filter = 'ghost_name', name = 'x' } }, F.ghost_name('x'))
        assert.same({ { filter = 'ghost_type', type = 'x' } }, F.ghost_type('x'))
    end)

    it('sets the filter for a single filtered handler', function()
        local filter = F.name('iron-chest')
        Event.register(built, function() end, nil, nil, { event_filter = filter })
        assert.same({ id = built, filter = { { filter = 'name', name = 'iron-chest' } } }, last_filter_call())
    end)

    it('sets the union for two filtered handlers', function()
        Event.register(built, function() end, nil, nil, { event_filter = F.name('iron-chest') })
        Event.register(built, function() end, nil, nil, { event_filter = F.type('furnace') })
        assert.same({ id = built, filter = { { filter = 'name', name = 'iron-chest' }, { filter = 'type', type = 'furnace' } } },
            last_filter_call())
    end)

    it('removes the filter when one handler has no native filter, and restores the union on removal', function()
        local h1, h2, plain = function() end, function() end, function() end
        Event.register(built, h1, nil, nil, { event_filter = F.name('iron-chest') })
        Event.register(built, h2, nil, nil, { event_filter = F.type('furnace') })
        Event.register(built, plain)
        assert.same({ id = built, filter = nil }, last_filter_call())
        assert.is_nil(script.filters[built])

        Event.remove(built, plain)
        assert.same(2, #last_filter_call().filter)
        assert.same(2, #script.filters[built])

        Event.remove(built, h2)
        assert.same({ { filter = 'name', name = 'iron-chest' } }, script.filters[built])
    end)

    it('only dispatches events matching the own filter when the union is wider', function()
        local chests, furnaces = spy.new(function() end), spy.new(function() end)
        Event.register(built, chests, nil, nil, { event_filter = F.name('iron-chest') })
        Event.register(built, furnaces, nil, nil, { event_filter = F.type('furnace') })

        script.raise_event(built, { entity = entity('iron-chest') })
        script.raise_event(built, { entity = entity('stone-furnace', 'furnace') })
        script.raise_event(built, { entity = entity('steel-chest') })

        assert.spy(chests).was.called(1)
        assert.spy(furnaces).was.called(1)
    end)

    it('also re-checks when a handler without native filter widened it', function()
        local chests = spy.new(function() end)
        Event.register(built, chests, nil, nil, { event_filter = F.name('iron-chest') })
        Event.register(built, function() end)
        script.raise_event(built, { entity = entity('steel-chest') })
        script.raise_event(built, { entity = entity('iron-chest') })
        assert.spy(chests).was.called(1)
    end)

    it('trusts Factorio when all handlers share one filter', function()
        local handler = spy.new(function() end)
        local filter = F.name('iron-chest')
        Event.register(built, handler, nil, nil, { event_filter = filter })
        Event.register(built, function() end, nil, nil, { event_filter = filter })
        -- an entity that does not match is not re-checked in Lua (Factorio would not have sent it)
        script.raise_event(built, { entity = entity('steel-chest') })
        assert.spy(handler).was.called(1)
    end)

    it('supports invert, ghost and mode in the Lua re-check', function()
        local seen = {}
        local ghost = { valid = true, name = 'entity-ghost', type = 'entity-ghost', ghost_name = 'iron-chest', ghost_type = 'container' }
        Event.register(built, function() seen[#seen + 1] = 'real' end, nil, nil, { event_filter = F.ghost(false) })
        Event.register(built, function() seen[#seen + 1] = 'ghost' end, nil, nil, { event_filter = F.ghost_name('iron-chest') })
        Event.register(built, function() seen[#seen + 1] = 'and' end, nil, nil,
            { event_filter = { { filter = 'type', type = 'container' }, { filter = 'name', name = 'iron-chest', mode = 'and' } } })
        script.raise_event(built, { entity = entity('iron-chest') })
        script.raise_event(built, { entity = ghost })
        assert.same({ 'real', 'and', 'ghost' }, seen)
    end)

    it('does not union filters that use mode and, filtering is switched off instead', function()
        local with_and = { { filter = 'type', type = 'container' }, { filter = 'name', name = 'iron-chest', mode = 'and' } }
        Event.register(built, function() end, nil, nil, { event_filter = with_and })
        Event.register(built, function() end, nil, nil, { event_filter = F.name('x') })
        assert.is_nil(script.filters[built])
    end)

    it('skips the Lua re-check for unknown filter keys', function()
        local handler = spy.new(function() end)
        Event.register(built, handler, nil, nil, { event_filter = { { filter = 'rail' } } })
        Event.register(built, function() end)
        script.raise_event(built, { entity = entity('anything') })
        assert.spy(handler).was.called(1)
    end)

    it('errors for events that do not support filters', function()
        assert.has_error(function()
            Event.register(defines.events.on_tick, function() end, nil, nil, { event_filter = F.name('x') })
        end)
        assert.has_error(function()
            Event.register(-60, function() end, nil, nil, { event_filter = F.name('x') })
        end)
    end)

    it('validates the shape of the filter', function()
        assert.has_error(function() Event.register(built, function() end, nil, nil, { event_filter = {} }) end)
        assert.has_error(function() Event.register(built, function() end, nil, nil, { event_filter = { 'name' } }) end)
    end)

    it('never calls set_event_filter for events without native filters', function()
        Event.register(defines.events.on_tick, function() end)
        assert.same(0, #script.filter_calls)
    end)
end)
