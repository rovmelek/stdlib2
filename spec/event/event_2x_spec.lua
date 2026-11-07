require('spec/setup/busted')()

local Env = require('spec/setup/factorio_env')
local genstub = require('spec/setup/stub_factory')

describe('Event (2.x)', function()
    local Event

    before_each(function()
        Env.install()
        Event = require('__stdlib2__/stdlib/event/event')
    end)

    local function entity(name, type)
        return { valid = true, name = name, type = type or 'container', __self = true }
    end

    describe('build events', function()
        local events = { 'on_built_entity', 'on_robot_built_entity', 'on_space_platform_built_entity',
            'script_raised_built', 'script_raised_revive' }

        for _, name in pairs(events) do
            it(name .. ' keeps event.entity and adds the deprecated created_entity', function()
                local seen
                Event.register(defines.events[name], function(e) seen = e end)
                local chest = entity('iron-chest')
                script.raise_event(defines.events[name], { entity = chest })
                assert.equals(chest, seen.entity)
                assert.equals(chest, seen.created_entity)
            end)
        end

        it('on_entity_cloned maps destination to entity', function()
            local seen
            Event.register(defines.events.on_entity_cloned, function(e) seen = e end)
            local chest = entity('iron-chest')
            script.raise_event(defines.events.on_entity_cloned, { destination = chest, source = entity('x') })
            assert.equals(chest, seen.entity)
            assert.equals(chest, seen.created_entity)
        end)

        it('omits created_entity when legacy_created_entity is disabled', function()
            Event.options.legacy_created_entity = false
            local seen
            Event.register(defines.events.on_built_entity, function(e) seen = e end)
            local chest = entity('iron-chest')
            script.raise_event(defines.events.on_built_entity, { entity = chest })
            assert.equals(chest, seen.entity)
            assert.is_nil(seen.created_entity)
        end)

        it('does not alias events that are not build events', function()
            local seen
            Event.register(defines.events.on_entity_died, function(e) seen = e end)
            script.raise_event(defines.events.on_entity_died, { entity = entity('x') })
            assert.is_nil(seen.created_entity)
        end)
    end)

    describe('.register with a table of ids', function()
        it('passes filter, pattern and options to every id', function()
            local handler = genstub()
            local filter = function(_, pattern) return pattern end
            Event.register({ 1, 2 }, handler, filter, 'pattern', { skip_valid = true })
            for _, id in pairs { 1, 2 } do
                local registered = Event.registry[id][1]
                assert.equals(filter, registered.filter)
                assert.equals('pattern', registered.pattern)
                assert.is_true(registered.options.skip_valid)
            end
        end)

        it('does not call the handler when the filter rejects', function()
            local handler = genstub()
            Event.register({ 1, 2 }, handler, function() return false end, 'x')
            script.raise_event(1)
            script.raise_event(2)
            assert.stub(handler).was_not.called()
        end)
    end)

    describe('.remove with a table of ids', function()
        it('only removes the matching filter and pattern', function()
            local handler = genstub()
            local filter = function() return true end
            Event.register({ 1, 2 }, handler, filter, 'a')
            Event.register({ 1, 2 }, handler, filter, 'b')
            Event.remove({ 1, 2 }, handler, filter, 'a')
            for _, id in pairs { 1, 2 } do
                assert.same(1, #Event.registry[id])
                assert.same('b', Event.registry[id][1].pattern)
            end
        end)
    end)

    describe('Filters.entity', function()
        it('read event.entity, created_entity and destination', function()
            local f = Event.Filters.entity
            local chest = entity('iron-chest', 'container')
            assert.truthy(f.name({ entity = chest }, 'chest'))
            assert.truthy(f.name({ created_entity = chest }, 'chest'))
            assert.truthy(f.type({ destination = chest }, 'container'))
            assert.falsy(f.name({ entity = chest }, 'wooden'))
        end)

        it('return nil instead of erroring without a valid entity', function()
            local f = Event.Filters.entity
            assert.is_nil(f.name({}, 'chest'))
            assert.is_nil(f.type(nil, 'chest'))
            assert.is_nil(f.name({ entity = { valid = false, name = 'iron-chest' } }, 'chest'))
        end)
    end)

    describe('dump_data', function()
        it('writes through helpers', function()
            Event.register(1, genstub())
            assert.has_no.errors(Event.dump_data)
            assert.is_truthy(Env.files[Event.get_file_path('Event/Event.lua')])
        end)

        it('is also used by Player, Force, Surface and Changes', function()
            for _, name in pairs { 'player', 'force', 'surface', 'changes' } do
                local module = require('__stdlib2__/stdlib/event/' .. name)
                _G.game.players = {}
                assert.has_no.errors(function() module.dump_data() end, name)
            end
        end)
    end)
end)
