require('spec/setup/busted')()

local Orientation = require('__stdlib2__/stdlib/area/orientation')

describe('Orientation', function()
    local d = defines.direction

    it('has orientations for the primary directions', function()
        assert.same(0, Orientation.north)
        assert.same(0.25, Orientation.east)
        assert.same(0.5, Orientation.south)
        assert.same(0.75, Orientation.west)
        assert.same(0.125, Orientation.northeast)
    end)

    describe('.to_direction', function()
        it('converts to 4-way directions', function()
            assert.same(d.north, Orientation.to_direction(0))
            assert.same(d.east, Orientation.to_direction(0.25))
            assert.same(d.south, Orientation.to_direction(0.5))
            assert.same(d.west, Orientation.to_direction(0.75))
            assert.same(d.north, Orientation.to_direction(0.99))
            assert.same(d.east, Orientation.to_direction(0.13))
        end)

        it('converts to 8-way directions', function()
            local names = { 'north', 'northeast', 'east', 'southeast', 'south', 'southwest', 'west', 'northwest' }
            for i, name in ipairs(names) do
                assert.same(d[name], Orientation.to_direction((i - 1) / 8, true), name)
            end
        end)

        it('converts to 16-way directions', function()
            for _, value in pairs(d) do
                assert.same(value, Orientation.to_direction(value / 16, 'sixteen_way'))
            end
        end)
    end)

    it('.opposite and .add wrap around', function()
        assert.same(0.5, Orientation.opposite(0))
        assert.same(0.25, Orientation.opposite(0.75))
        assert.same(0.25, Orientation.add(0.75, 0.5))
    end)
end)
