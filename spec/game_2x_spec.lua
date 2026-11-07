require('spec/setup/busted')()

local Env = require('spec/setup/factorio_env')

describe('Game (2.x)', function()
    local Game

    local function stats(tag)
        return { input_counts = { [tag] = 1 }, output_counts = { [tag] = 2 } }
    end

    before_each(function()
        Env.install()
        Game = require('__stdlib2__/stdlib/game')
    end)

    it('does not use removed game functions', function()
        local source = io.open('stdlib/game.lua'):read('*a')
        assert.is_nil(source:find('game%.write_file'))
        assert.is_nil(source:find('game%.table_to_json'))
        assert.is_nil(source:find('game%.remove_path'))
        assert.is_nil(source:find('pollution_statistics%['))
    end)

    describe('.write_mods', function()
        it('writes through helpers.write_file', function()
            Game.write_mods()
            assert.is_string(Env.files['Mods.lua'])
            assert.is_truthy(Env.files['Mods.lua']:find('stdlib2'))
        end)
    end)

    describe('.write_surfaces', function()
        it('removes the old files and writes each surface', function()
            Env.files['surfaces/old.lua'] = 'x'
            game.surfaces = { nauvis = { name = 'nauvis', map_gen_settings = { width = 0 } } }
            Game.write_surfaces()
            assert.is_nil(Env.files['surfaces/old.lua'])
            assert.is_truthy(Env.files['surfaces/nauvis.lua']:find('width'))
        end)
    end)

    describe('.write_statistics', function()
        it('writes statistics per surface and force with the 2.x API', function()
            game.tick = 77
            local nauvis = { name = 'nauvis' }
            game.surfaces = { nauvis }
            game.pollution[nauvis] = stats('pollution')
            local force = { name = 'player' }
            for kind, getter in pairs { item = 'get_item_production_statistics', fluid = 'get_fluid_production_statistics',
                kill = 'get_kill_count_statistics', build = 'get_entity_build_count_statistics' } do
                force[getter] = function(surface)
                    assert.equals(nauvis, surface)
                    return stats(kind)
                end
            end
            game.forces = { player = force }

            Game.write_statistics()

            local base = 'Statistics/77/nauvis/'
            for _, kind in pairs { 'item', 'fluid', 'kill', 'build' } do
                assert.same('{"' .. kind .. '":1}', Env.files[base .. 'player/' .. kind .. '-input_counts.json'])
                assert.same('{"' .. kind .. '":2}', Env.files[base .. 'player/' .. kind .. '-output_counts.json'])
            end
            assert.same('{"pollution":1}', Env.files[base .. 'pollution-input_counts.json'])
            assert.same('{"pollution":2}', Env.files[base .. 'pollution-output_counts.json'])
        end)

        it('copes with surfaces that have no pollution statistics', function()
            local nauvis = { name = 'nauvis' }
            game.surfaces = { nauvis }
            game.get_pollution_statistics = function() return nil end
            game.forces = {}
            assert.has_no.errors(Game.write_statistics)
        end)
    end)
end)
