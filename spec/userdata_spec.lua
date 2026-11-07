require('spec/setup/busted')()

local Env = require('spec/setup/factorio_env')

describe('LuaObjects as 2.x userdata', function()
    local Is, Game, Surface, Event, F

    before_each(function()
        Env.install()
        Is = require('__stdlib2__/stdlib/utils/is')
        Game = require('__stdlib2__/stdlib/game')
        Surface = require('__stdlib2__/stdlib/area/surface')
        Event = require('__stdlib2__/stdlib/event/event')
        F = Event.Filters.native
    end)

    it('the harness objects raise on unknown keys and when invalid, like the game', function()
        local obj, fields = Env.new_object({ name = 'nauvis' })
        assert.equals('userdata', type(obj))
        assert.equals('nauvis', obj.name)
        assert.has_error(function() return obj.__self end)
        fields.valid = false
        assert.is_false(obj.valid)
        assert.has_error(function() return obj.name end)
    end)

    it('Is.Object accepts userdata without indexing it', function()
        local obj = Env.new_object({ name = 'x' })
        assert.equals(obj, Is.Object(obj))
        assert.is_falsy(Is.Object({}))
        assert.is_falsy(Is.Object('str'))
        assert.is_falsy(Is.Object(nil))
    end)

    it('Surface.lookup handles LuaSurface userdata and arrays of them', function()
        local nauvis = Env.new_object({ name = 'nauvis', index = 1 })
        _G.game.surfaces = { nauvis = nauvis }
        assert.same({ nauvis }, Surface.lookup(nauvis))
        assert.same({ nauvis }, Surface.lookup({ nauvis }))
        assert.same({ nauvis }, Surface.lookup('nauvis'))
    end)

    it('Game.get_surface/get_force/get_player return valid userdata and nothing for invalid', function()
        local obj, fields = Env.new_object({ name = 'thing', index = 1 })
        assert.equals(obj, Game.get_surface(obj))
        assert.equals(obj, Game.get_force(obj))
        assert.equals(obj, Game.get_player(obj))
        fields.valid = false
        assert.is_falsy(Game.get_surface(obj))
        assert.is_falsy(Game.get_force(obj))
        assert.is_falsy(Game.get_player(obj))
    end)

    it('Table.deep_copy returns userdata as is', function()
        local table = require('__stdlib2__/stdlib/utils/table')
        local obj = Env.new_object({ name = 'x' })
        local copy = table.deep_copy({ entity = obj })
        assert.equals(obj, copy.entity)
    end)

    it('does not run later handlers once an entity became invalid, even with native re-check filters', function()
        local built = defines.events.on_built_entity
        local entity, fields = Env.new_object({ name = 'iron-chest', type = 'container' })
        local second = spy.new(function() end)
        Event.register(built, function() fields.valid = false end, nil, nil, { event_filter = F.name('iron-chest') })
        Event.register(built, second, nil, nil, { event_filter = F.name('steel-chest') })

        assert.has_no.errors(function()
            script.raise_event(built, { entity = entity })
        end)
        assert.spy(second).was_not.called()
    end)

    it('re-checks a native filter on a valid userdata entity', function()
        local built = defines.events.on_built_entity
        local entity = Env.new_object({ name = 'iron-chest', type = 'container' })
        local iron = spy.new(function() end)
        local steel = spy.new(function() end)
        Event.register(built, iron, nil, nil, { event_filter = F.name('iron-chest') })
        Event.register(built, steel, nil, nil, { event_filter = F.name('steel-chest') })

        script.raise_event(built, { entity = entity })
        assert.spy(iron).was.called(1)
        assert.spy(steel).was_not.called()
    end)
end)
