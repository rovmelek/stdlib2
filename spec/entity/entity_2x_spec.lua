require('spec/setup/busted')()

describe('Entity (2.x)', function()
    local Entity

    before_each(function()
        require('spec/setup/factorio_env').install()
        Entity = require('__stdlib2__/stdlib/entity/entity')
    end)

    local function circuit_entity(networks, connectors)
        return {
            get_circuit_network = function(id) return networks[id] end,
            get_wire_connectors = function() return connectors or {} end,
        }
    end

    describe('.is_circuit_connected', function()
        it('is true with a red network of more than one circuit', function()
            local e = circuit_entity { [defines.wire_connector_id.circuit_red] = { connected_circuit_count = 2 } }
            assert.is_true(Entity.is_circuit_connected(e))
        end)

        it('is true with a green network', function()
            local e = circuit_entity { [defines.wire_connector_id.circuit_green] = { connected_circuit_count = 3 } }
            assert.is_true(Entity.is_circuit_connected(e))
        end)

        it('is true when the network does not report a count', function()
            local e = circuit_entity { [defines.wire_connector_id.circuit_red] = {} }
            assert.is_true(Entity.is_circuit_connected(e))
        end)

        it('is false when alone on the network or without networks', function()
            assert.is_false(Entity.is_circuit_connected(circuit_entity { [defines.wire_connector_id.circuit_red] = { connected_circuit_count = 1 } }))
            assert.is_false(Entity.is_circuit_connected(circuit_entity {}))
        end)

        it('is false for entities without circuit connectors', function()
            local e = { get_circuit_network = function() error('no circuit connector') end }
            assert.is_false(Entity.is_circuit_connected(e))
            assert.is_false(Entity.is_circuit_connected({}))
        end)
    end)

    describe('.count_circuit_connections', function()
        it('sums the connection counts of the red and green connectors', function()
            local ids = defines.wire_connector_id
            local e = circuit_entity({}, {
                [ids.circuit_red] = { connection_count = 2 },
                [ids.circuit_green] = { connection_count = 3 },
                [ids.pole_copper] = { connection_count = 10 },
            })
            assert.same(5, Entity.count_circuit_connections(e))
        end)

        it('is 0 without connectors', function()
            assert.same(0, Entity.count_circuit_connections(circuit_entity({})))
            assert.same(0, Entity.count_circuit_connections({}))
        end)
    end)

    describe('.find_resources', function()
        local function drill(prototype)
            local args
            return {
                type = 'mining-drill', quality = 'normal', position = { x = 0, y = 0 }, prototype = prototype,
                surface = { count_entities_filtered = function(a) args = a return 4 end },
                get_args = function() return args end,
            }
        end

        it('uses get_mining_drill_radius(quality) when available', function()
            local d = drill { mining_drill_radius = 1, get_mining_drill_radius = function(q) return q == 'normal' and 2.49 or 0 end }
            assert.same(4, Entity.find_resources(d, true))
            assert.same(2.49, d.get_args().radius)
        end)

        it('falls back to mining_drill_radius', function()
            local d = drill { mining_drill_radius = 1.5 }
            Entity.find_resources(d, true)
            assert.same(1.5, d.get_args().radius)
        end)
    end)

    describe('frozen / indestructible guards', function()
        it('raise a clear error for non entities', function()
            assert.has_error(function() Entity.set_frozen(5) end)
            assert.has_error(function() Entity.set_indestructible('x') end)
            assert.has_error(function() Entity.set_frozen(nil) end)
        end)
    end)
end)
