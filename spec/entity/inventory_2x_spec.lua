require('spec/setup/busted')()

describe('Inventory (2.x)', function()
    local Inventory

    before_each(function()
        require('spec/setup/factorio_env').install()
        Inventory = require('__stdlib2__/stdlib/entity/inventory')
    end)

    local function stack(name, count, extra)
        local s = { valid = true, valid_for_read = true, name = name, count = count, health = 1,
            quality = { name = 'normal' }, prototype = { spoil_ticks = 0 } }
        for k, v in pairs(extra or {}) do s[k] = v end
        return s
    end

    local function inventory(stacks)
        local inv = {}
        for i, s in ipairs(stacks) do inv[i] = s end
        inv.inserted = {}
        inv.insert = function(simple)
            inv.inserted[#inv.inserted + 1] = { name = simple.name, count = simple.count, quality = simple.quality,
                spoil_percent = simple.spoil_percent }
            return simple.count
        end
        inv.clear = function() inv.cleared = true end
        return inv
    end

    describe('.copy_as_simple_stacks', function()
        it('keeps the quality', function()
            local src = inventory { stack('iron-plate', 5, { quality = { name = 'rare' } }) }
            local dest = inventory {}
            local left = Inventory.copy_as_simple_stacks(src, dest)
            assert.same({}, left)
            assert.same('rare', dest.inserted[1].quality)
            assert.same(5, dest.inserted[1].count)
            assert.is_nil(dest.inserted[1].spoil_percent)
        end)

        it('copies spoil_percent only for items that spoil', function()
            local src = inventory {
                stack('meat', 1, { prototype = { spoil_ticks = 600 }, spoil_percent = 0.25 }),
                stack('plate', 1, { spoil_percent = 0.5 }),
            }
            local dest = inventory {}
            Inventory.copy_as_simple_stacks(src, dest, true)
            assert.same(0.25, dest.inserted[1].spoil_percent)
            assert.is_nil(dest.inserted[2].spoil_percent)
            assert.is_true(src.cleared)
        end)

        it('returns what could not be inserted', function()
            local src = inventory { stack('iron-plate', 5) }
            local dest = inventory {}
            dest.insert = function() return 2 end
            local left = Inventory.copy_as_simple_stacks(src, dest)
            assert.same(3, left[1].count)
        end)
    end)

    describe('.swap_inventory', function()
        it('swaps every slot with the matching source slot', function()
            local calls = {}
            local function slot(name)
                return { name = name, swap_stack = function(self, other) calls[#calls + 1] = { self.name, other.name } end }
            end
            local source = { slot('s1'), slot('s2'), slot('s3') }
            local destination = { slot('d1'), slot('d2') }
            -- swap_stack is called with `.` syntax in the library, adapt
            for _, d in ipairs(destination) do
                d.swap_stack = function(other) calls[#calls + 1] = { d.name, other.name } end
            end
            Inventory.swap_inventory(source, destination)
            assert.same({ { 'd1', 's1' }, { 'd2', 's2' } }, calls)
        end)
    end)

    describe('.get_item_or_filter', function()
        it('returns the name of an ItemFilter table', function()
            local inv = { get_filter = function() return { name = 'iron-plate', quality = 'normal' } end }
            assert.same('iron-plate', Inventory.get_item_or_filter(inv, 1))
        end)

        it('returns the stack name when there is no filter', function()
            local inv = { get_filter = function() return nil end, [1] = { valid_for_read = true, name = 'coal' } }
            assert.same('coal', Inventory.get_item_or_filter(inv, 1))
        end)
    end)

    describe('quality aware contents', function()
        local inv = {
            get_contents = function()
                return {
                    { name = 'iron-plate', quality = 'normal', count = 10 },
                    { name = 'iron-plate', quality = 'rare', count = 5 },
                    { name = 'coal', quality = 'normal', count = 3 },
                }
            end
        }

        it('.get_contents_by_name sums all qualities', function()
            assert.same({ ['iron-plate'] = 15, coal = 3 }, Inventory.get_contents_by_name(inv))
        end)

        it('.get_contents_by_quality keeps qualities apart', function()
            assert.same({ ['iron-plate'] = { normal = 10, rare = 5 }, coal = { normal = 3 } }, Inventory.get_contents_by_quality(inv))
        end)

        it('handles empty inventories', function()
            local empty = { get_contents = function() return {} end }
            assert.same({}, Inventory.get_contents_by_name(empty))
            assert.same({}, Inventory.get_contents_by_quality(empty))
        end)
    end)
end)
