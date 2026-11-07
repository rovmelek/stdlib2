require('spec/setup/busted')()

describe('Data helpers (2.x)', function()
    local Data, Item, Entity, Category

    before_each(function()
        require('spec/setup/data_fixtures').reset()
        Data = require('__stdlib2__/stdlib/data/data')
        Item = require('__stdlib2__/stdlib/data/item')
        Entity = require('__stdlib2__/stdlib/data/entity')
        Category = require('__stdlib2__/stdlib/data/category')
    end)

    after_each(function()
        package.remove_stdlib()
    end)

    describe('stage detection', function()
        it('refuses to load in the control stage', function()
            package.remove_stdlib()
            require('spec/setup/factorio_env').install()
            assert.has_error(function() require('__stdlib2__/stdlib/data/data') end)
        end)
    end)

    describe(':copy', function()
        it('renames minable.results with a single entry', function()
            _G.data:extend({ { type = 'simple-entity', name = 'rock', minable = { mining_time = 1, results = { { type = 'item', name = 'stone', amount = 1 } } } } })
            Data('rock', 'simple-entity'):copy('rock-2', 'stone-2')
            assert.same('stone-2', _G.data.raw['simple-entity']['rock-2'].minable.results[1].name)
            assert.same('stone', _G.data.raw['simple-entity'].rock.minable.results[1].name)
        end)
    end)

    describe('flags', function()
        it(':any_flag is true when any flag matches', function()
            local obj = Data('cliff-explosives', 'capsule')
            assert.is_true(obj:any_flag('hide-from-bonus-gui'))
            assert.is_false(obj:any_flag('mighty'))
        end)
    end)

    describe('icons', function()
        it(':replace_icon defaults the icon size to 64 and does not error', function()
            _G.data:extend({ { type = 'item', name = 'no-size', stack_size = 1 } })
            local obj
            assert.has_no.errors(function() obj = Data('no-size', 'item'):replace_icon('__base__/x.png') end)
            assert.same(64, _G.data.raw.item['no-size'].icon_size)
            assert.same('__base__/x.png', _G.data.raw.item['no-size'].icon)
            assert.is_not_nil(obj)
        end)

        it(':replace_icon does not error for invalid objects', function()
            assert.has_no.errors(function() Data('fake', 'item'):replace_icon('__base__/x.png') end)
        end)

        it(':make_icons defaults icon_size', function()
            _G.data:extend({ { type = 'item', name = 'no-size', icon = '__base__/x.png', stack_size = 1 } })
            Data('no-size', 'item'):make_icons({ icon = '__base__/y.png', icon_size = 32 })
            local icons = _G.data.raw.item['no-size'].icons
            assert.same(64, icons[1].icon_size)
            assert.same(32, icons[2].icon_size)
        end)

        it(':set_icon_at sets the given fields', function()
            _G.data:extend({ { type = 'item', name = 'icons', stack_size = 1, icons = { { icon = 'a.png', icon_size = 64 } } } })
            Data('icons', 'item'):set_icon_at(1, { scale = 0.5, tint = { r = 1 } })
            local icon = _G.data.raw.item.icons.icons[1]
            assert.same(0.5, icon.scale)
            assert.same({ r = 1 }, icon.tint)
        end)
    end)

    describe('Item fuel', function()
        it(':set_fuel writes fuel_categories', function()
            Item('stone'):set_fuel('1MJ', 'chemical', 'iron-plate')
            local raw = _G.data.raw.item.stone
            assert.same('1MJ', raw.fuel_value)
            assert.same({ 'chemical' }, raw.fuel_categories)
            assert.same('iron-plate', raw.burnt_result)
            Item('stone'):set_fuel('2MJ', { 'chemical', 'x' })
            assert.same({ 'chemical', 'x' }, raw.fuel_categories)
        end)

        it(':set_fuel removes the legacy field', function()
            _G.data.raw.item.stone.fuel_category = 'chemical'
            Item('stone'):set_fuel('2MJ', 'chemical')
            assert.is_nil(_G.data.raw.item.stone.fuel_category)
        end)

        it(':add_fuel_category moves a legacy fuel_category', function()
            Item('wood'):add_fuel_category('nuclear')
            local raw = _G.data.raw.item.wood
            assert.is_nil(raw.fuel_category)
            assert.same({ 'chemical', 'nuclear' }, raw.fuel_categories)
            Item('wood'):add_fuel_category('nuclear')
            assert.same(2, #raw.fuel_categories)
        end)
    end)

    describe('Category', function()
        it('does not list rail-category', function()
            assert.is_nil(Category.category_types['rail-category'])
        end)

        it(':replace does not error', function()
            assert.has_no.errors(function() Category('crafting', 'recipe-category'):replace('a', 'b') end)
        end)
    end)

    describe('Entity:get_minable_item', function()
        it('prefers minable.results[1]', function()
            _G.data:extend({ { type = 'simple-entity', name = 'rock', minable = { mining_time = 1, results = { { type = 'item', name = 'stone', amount = 1 } } } } })
            assert.same('stone', Entity('rock', 'simple-entity'):get_minable_item().name)
        end)

        it('falls back to minable.result', function()
            assert.same('lab', Entity('lab', 'lab').minable.result)
            _G.data:extend({ { type = 'item', name = 'lab', stack_size = 1 } })
            assert.same('lab', Entity('lab', 'lab'):get_minable_item().name)
        end)
    end)

    describe('groups', function()
        local groups = require('__stdlib2__/stdlib/data/modules/groups')
        it('only lists 2.x prototype types', function()
            local removed = { 'rail-category', 'noise-layer', 'combat-robot-count', 'curved-rail', 'player', 'decorative',
                'flying-text', 'smoke', 'leaf-particle', 'particle', 'flame-thrower-explosion' }
            for _, list in pairs(groups) do
                for _, type_name in pairs(list) do
                    for _, bad in pairs(removed) do
                        assert.not_equal(bad, type_name)
                    end
                end
            end
        end)

        it('lists the new 2.x types', function()
            local function has(list, name)
                for _, v in pairs(list) do if v == name then return true end end
            end
            assert.is_true(has(groups.other, 'quality'))
            assert.is_true(has(groups.other, 'surface'))
            assert.is_true(has(groups.other, 'planet'))
            assert.is_true(has(groups.equipment, 'inventory-bonus-equipment'))
            assert.is_true(has(groups.item, 'space-platform-starter-pack'))
            assert.is_true(has(groups.item, 'spidertron-remote'))
        end)
    end)

    describe('Util.duplicate', function()
        it('renames mining results and the single recipe result', function()
            _G.data:extend({ { type = 'simple-entity', name = 'rock', minable = { mining_time = 1, results = { { type = 'item', name = 'rock', amount = 1 } } } } })
            local proto = Data.Util.duplicate('simple-entity', 'rock', 'rock-2', true)
            assert.same('rock-2', proto.minable.results[1].name)
            local recipe = Data.Util.duplicate('recipe', 'stone-furnace', 'furnace-2')
            assert.same('furnace-2', recipe.results[1].name)
            assert.same('stone-furnace', _G.data.raw.recipe['stone-furnace'].results[1].name)
        end)
    end)

    describe('Pipes.covers', function()
        it('no longer returns hr_version tables', function()
            local covers = Data.Pipes.covers()
            for _, cover in pairs(covers) do
                for _, layer in pairs(cover.layers) do
                    assert.is_nil(layer.hr_version)
                    assert.same(0.5, layer.scale)
                    assert.same(128, layer.width)
                    assert.is_nil(layer.filename:find('/hr%-'), layer.filename)
                end
            end
            assert.same('__base__/graphics/entity/pipe-covers/pipe-cover-north.png', covers.north.layers[1].filename)
        end)

        it('Pipes.pictures uses the 2.x sizes with scale 0.5', function()
            local pictures = Data.Pipes.pictures('assembling-machine-2', {x = 0, y = 1}, nil, nil, nil)
            assert.same(70, pictures.north.width)
            assert.same(36, pictures.north.height)
            assert.same(0.5, pictures.north.scale)
            assert.same('__core__/graphics/empty.png', pictures.south.filename)
        end)
    end)

    describe('Recipe quality fields', function()
        it(':allow_quality and :set_can_set_quality write the 2.x fields', function()
            local Recipe = require('__stdlib2__/stdlib/data/recipe')
            local raw = _G.data.raw.recipe['stone-furnace']
            local recipe = Recipe('stone-furnace')
            assert.equals(recipe, recipe:allow_quality(false))
            assert.is_false(raw.allow_quality)
            -- works when the field is already true (the field does not shadow the method)
            Recipe('stone-furnace'):allow_quality(true)
            assert.is_true(raw.allow_quality)
            Recipe('stone-furnace'):allow_quality(false)
            assert.is_false(raw.allow_quality)
            Recipe('stone-furnace'):set_can_set_quality(true)
            assert.is_true(raw.can_set_quality)
            Recipe('stone-furnace'):set_can_set_quality(false)
            assert.is_false(raw.can_set_quality)
        end)

        it('does nothing for invalid recipes', function()
            local Recipe = require('__stdlib2__/stdlib/data/recipe')
            assert.has_no.errors(function() Recipe('fake'):allow_quality(true):set_can_set_quality(true) end)
        end)
    end)
end)
