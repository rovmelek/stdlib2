require('spec/setup/busted')()

local Env = require('spec/setup/factorio_env')

describe('Entity data cleanup', function()
    local Entity, Event

    local function ent(unit_number, name)
        return { valid = true, unit_number = unit_number, name = name or 'chest' }
    end

    local function destroyed(entity)
        -- find the registration made for the entity
        for number, object in pairs(script.object_registrations) do
            if object == entity then
                script.raise_event(defines.events.on_object_destroyed, { registration_number = number, useful_id = entity.unit_number })
                return number
            end
        end
    end

    before_each(function()
        Env.install()
        Event = require('__stdlib2__/stdlib/event/event')
        Entity = require('__stdlib2__/stdlib/entity/entity')
    end)

    it('stores data per unit number and returns the previous value', function()
        local e = ent(1)
        assert.is_nil(Entity.set_data(e, { a = 1 }))
        assert.same({ a = 1 }, Entity.get_data(e))
        assert.same({ a = 1 }, Entity.set_data(e, { a = 2 }))
        assert.same({ a = 2 }, Entity.get_data(e))
        assert.same({ a = 2 }, Entity.set_data(e, nil))
        assert.is_nil(Entity.get_data(e))
    end)

    it('registers the entity for destruction and remembers the registration number', function()
        local e = ent(7)
        Entity.set_data(e, 'x')
        local reg = next(script.object_registrations)
        assert.equals(e, script.object_registrations[reg])
        assert.same(7, storage._entity_data_reg[reg])
        assert.is_function(script.handlers[defines.events.on_object_destroyed])
    end)

    it('removes the data when the entity is destroyed', function()
        local a, b = ent(1), ent(2)
        Entity.set_data(a, 'a')
        Entity.set_data(b, 'b')
        local reg = destroyed(a)
        assert.is_nil(storage._entity_data[1])
        assert.is_nil(storage._entity_data_reg[reg])
        assert.same('b', storage._entity_data[2])
    end)

    it('ignores destroyed objects that were not registered', function()
        Entity.set_data(ent(1), 'a')
        assert.has_no.errors(function()
            script.raise_event(defines.events.on_object_destroyed, { registration_number = 999 })
        end)
        assert.same('a', storage._entity_data[1])
    end)

    it('does not register anything when auto_cleanup is off', function()
        Entity.options.auto_cleanup = false
        Entity.set_data(ent(1), 'a')
        assert.is_nil(next(script.object_registrations))
        assert.is_nil(storage._entity_data_reg)
    end)

    it('registers the handler again in on_load when registrations exist', function()
        Entity.set_data(ent(1), 'a')
        -- simulate a load: fresh script, same storage
        local saved = storage
        package.remove_stdlib()
        Env.install()
        _G.storage = saved
        Event = require('__stdlib2__/stdlib/event/event')
        Entity = require('__stdlib2__/stdlib/entity/entity')
        assert.is_nil(script.handlers[defines.events.on_object_destroyed])
        script.raise_event('on_load')
        assert.is_function(script.handlers[defines.events.on_object_destroyed])
    end)

    it('does not register in on_load when there is nothing to clean up', function()
        script.raise_event('on_load')
        assert.is_nil(script.handlers[defines.events.on_object_destroyed])
    end)

    it('migrates existing data in on_configuration_changed', function()
        storage._entity_data = { [10] = 'found', [11] = 'unknown', chest = {} }
        local found = ent(10)
        game.entities_by_unit_number[10] = found
        script.raise_event('on_configuration_changed')
        local reg = next(script.object_registrations)
        assert.equals(found, script.object_registrations[reg])
        assert.same(10, storage._entity_data_reg[reg])
        assert.same('unknown', storage._entity_data[11]) -- kept: nil lookup does not prove it is gone
        assert.is_function(script.handlers[defines.events.on_object_destroyed])
    end)

    describe('entities without a unit number', function()
        local function plain(name)
            local e = { valid = true, name = name }
            return e
        end

        it('stores and finds data by identity', function()
            local a, b = plain('wall'), plain('wall')
            Entity.set_data(a, 'a')
            Entity.set_data(b, 'b')
            assert.same('a', Entity.get_data(a))
            assert.same('b', Entity.get_data(b))
            assert.same('a', Entity.set_data(a, nil))
            assert.is_nil(Entity.get_data(a))
            assert.same('b', Entity.get_data(b))
        end)

        it('prunes invalid entries on get_data as well as set_data', function()
            local a, b = plain('wall'), plain('wall')
            Entity.set_data(a, 'a')
            Entity.set_data(b, 'b')
            a.valid = false
            assert.is_nil(Entity.get_data(plain('wall')))
            assert.same(1, #storage._entity_data.wall)
            b.valid = false
            Entity.get_data(plain('wall'))
            assert.same(0, #storage._entity_data.wall)
        end)
    end)

    it('throws a clear error when writing storage in on_load', function()
        local Storage = require('__stdlib2__/stdlib/utils/storage')
        local failure
        Event.on_load(function()
            local ok, err = pcall(Entity.set_data, ent(1), 'x')
            failure = not ok and err
        end)
        script.raise_event('on_load')
        assert.is_truthy(tostring(failure):find('on_load'))
        assert.is_false(Storage.loading)
    end)
end)
