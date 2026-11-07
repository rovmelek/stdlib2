require('spec/setup/busted')()

local Env = require('spec/setup/factorio_env')

local function new_train(id, extra)
    local train = { id = id, valid = true, state = defines.train_state.on_the_path, surface = 'nauvis', force = 'player' }
    for k, v in pairs(extra or {}) do train[k] = v end
    return train
end

describe('Trains', function()
    local Trains, Event

    before_each(function()
        Env.install { game = { trains = {} } }
        Trains = require('__stdlib2__/stdlib/event/trains')
        Event = require('__stdlib2__/stdlib/event/event')
    end)

    describe('.find_filtered', function()
        it('uses the train manager with a TrainFilter and returns LuaTrain.id', function()
            local a, b = new_train(10), new_train(11, { state = defines.train_state.wait_station })
            game.train_manager.trains = { a, b }
            local all = Trains.find_filtered()
            assert.same(2, #all)
            assert.same({ { force = nil } }, game.train_manager.calls)
            assert.same(10, all[1].id)
            assert.equals(a, all[1].train)

            local waiting = Trains.find_filtered { state = defines.train_state.wait_station }
            assert.same(1, #waiting)
            assert.same(11, waiting[1].id)
        end)

        it('filters by surface and force', function()
            local nauvis = { name = 'nauvis', __self = true, valid = true }
            game.surfaces.nauvis = nauvis
            game.train_manager.trains = { new_train(1, { surface = nauvis, force = 'player' }), new_train(2, { surface = nauvis, force = 'enemy' }) }
            local found = Trains.find_filtered { surface = 'nauvis', force = 'player' }
            assert.same(1, #found)
            assert.same(nauvis, game.train_manager.calls[1].surface)
            assert.same('player', game.train_manager.calls[1].force)
            assert.same(1, found[1].id)
        end)
    end)

    describe('train identity', function()
        it('.get_train_id returns train.id', function()
            assert.same(5, Trains.get_train_id(new_train(5)))
            assert.is_nil(Trains.get_train_id(nil))
            assert.is_nil(Trains.get_train_id({ id = 5, valid = false }))
        end)

        it('.to_entity uses train.id', function()
            assert.same('train-7', Trains.to_entity(new_train(7)).name)
        end)

        it('.set_data / .get_data are keyed by train id', function()
            local train = new_train(8)
            Trains.set_data(train, { x = 1 })
            assert.same({ x = 1 }, Trains.get_data(train))
            assert.same({ x = 1 }, Trains.get_data(new_train(8)))
            assert.is_nil(Trains.get_data(new_train(9)))
        end)
    end)

    describe('registry', function()
        it('is rebuilt from scratch with train ids and drops invalid trains', function()
            storage._train_registry = { [999] = new_train(999, { valid = false }), [55] = new_train(55) }
            game.train_manager.trains = { new_train(1), new_train(2) }
            local registry = Trains.create_train_registry()
            assert.is_nil(registry[999])
            assert.is_nil(registry[55])
            assert.is_not_nil(registry[1])
            assert.is_not_nil(registry[2])
        end)

        it('_on_locomotive_changed drops stale entries', function()
            local dead = new_train(3, { valid = false })
            storage._train_registry = { [3] = dead, [4] = new_train(4) }
            Trains._on_locomotive_changed()
            assert.is_nil(storage._train_registry[3])
            assert.is_not_nil(storage._train_registry[4])
        end)
    end)

    describe('on_train_created', function()
        it('renames the old ids and dispatches on_train_id_changed', function()
            Trains.register_events()
            storage._train_registry = { [1] = new_train(1), [2] = new_train(2) }
            local handler = spy.new(function() end)
            Event.register(Trains.on_train_id_changed, handler)

            local new = new_train(3)
            script.raise_event(defines.events.on_train_created, { train = new, old_train_id_1 = 1, old_train_id_2 = 2 })

            assert.is_nil(storage._train_registry[1])
            assert.is_nil(storage._train_registry[2])
            assert.equals(new, storage._train_registry[3])
            assert.spy(handler).was.called(2)
            local first = handler.calls[1].vals[1]
            assert.same(1, first.old_id)
            assert.same(3, first.new_id)
            assert.same(2, handler.calls[2].vals[1].old_id)
        end)

        it('ignores old ids that were never registered', function()
            Trains.register_events()
            storage._train_registry = {}
            local handler = spy.new(function() end)
            Event.register(Trains.on_train_id_changed, handler)
            script.raise_event(defines.events.on_train_created, { train = new_train(3), old_train_id_1 = 1 })
            assert.spy(handler).was_not.called()
            assert.is_not_nil(storage._train_registry[3])
        end)

        it('does not register the removed locomotive listeners', function()
            Trains.register_events()
            assert.is_nil(script.handlers[defines.events.on_pre_player_mined_item])
            assert.is_nil(script.handlers[defines.events.on_robot_pre_mined])
        end)

        it('registers trains for destruction and drops them (and their data) when destroyed', function()
            Trains.register_events()
            local a, b = new_train(5), new_train(6)
            game.train_manager.trains = { a, b }
            Trains.create_train_registry()
            Trains.set_data(a, 'keep me not')
            local registered = {}
            for number, object in pairs(script.object_registrations) do registered[object] = number end
            assert.is_not_nil(registered[a])
            assert.is_not_nil(registered[b])

            -- the train is still valid when the event is raised, only the destruction notification counts
            script.raise_event(defines.events.on_object_destroyed, {
                registration_number = registered[a], type = defines.target_type.train, useful_id = 5 })
            assert.is_nil(storage._train_registry[5])
            assert.is_not_nil(storage._train_registry[6])
            assert.is_nil(storage._entity_data['train-5'])
        end)

        it('ignores destroyed objects that are not trains', function()
            Trains.register_events()
            storage._train_registry = { [5] = new_train(5) }
            script.raise_event(defines.events.on_object_destroyed, {
                registration_number = 1, type = defines.target_type.entity, useful_id = 5 })
            assert.is_not_nil(storage._train_registry[5])
        end)

        it('registers a train created by on_train_created for destruction', function()
            Trains.register_events()
            local new = new_train(9)
            script.raise_event(defines.events.on_train_created, { train = new })
            local found
            for _, object in pairs(script.object_registrations) do found = found or object == new end
            assert.is_true(found)
        end)
    end)

    describe('train data of stdlib2 2.0.x', function()
        local function train_with_loco(id, unit_number)
            return new_train(id, { locomotives = { front_movers = { { unit_number = unit_number } }, back_movers = {} } })
        end

        it('is moved from the locomotive unit number to the train id once', function()
            local entry = { entity = { name = 'train-42' }, data = { stops = 3 } }
            storage._entity_data = { ['train-42'] = { entry } }
            game.train_manager.trains = { train_with_loco(7, 42) }

            Trains.create_train_registry()
            assert.is_nil(storage._entity_data['train-42'])
            assert.same({ stops = 3 }, Trains.get_data(game.train_manager.trains[1]))
            assert.is_true(storage._train_data_migrated)

            -- a later rebuild must not move data again: 'train-7' now belongs to the train with id 7
            storage._entity_data['train-9'] = { { entity = { name = 'train-9' }, data = 'other' } }
            game.train_manager.trains = { train_with_loco(7, 9) }
            Trains.create_train_registry()
            assert.same('other', storage._entity_data['train-9'][1].data)
        end)
    end)
end)
