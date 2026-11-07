require('spec/setup/busted')()

local Recipe, Raw, Rawtech
local table = require('__stdlib2__/stdlib/utils/table')

describe('Recipe', function()

    before_each(function()
        require('spec/setup/data_fixtures').reset()
        Recipe = require('__stdlib2__/stdlib/data/recipe')
        Raw = _G["data"].raw["recipe"]
        Rawtech = _G["data"].raw["technology"]["steel-processing"]
    end)

    after_each(function()
        package.remove_stdlib()
    end)

    describe(':get', function()

        it('should get a recipe', function()
            --assert.has_error(function() Recipe() end)
            assert.not_nil(Recipe("stone-furnace"))
            assert.not_nil(Recipe("fake"))
        end)
    end)

    describe(':is_valid', function()

        it('should return the recipe', function()
            assert.truthy(Recipe("stone-furnace"):is_valid())
            assert.truthy(Recipe("stone-furnace"):is_valid("recipe"))
            local recipe = Recipe("stone-furnace")
            assert.truthy(recipe:is_valid())
            assert.truthy(recipe:is_valid("recipe"))
        end)

        it('should return falsy if not a recipe', function()
            assert.not_truthy(Recipe("fake"):is_valid())
            assert.not_truthy(Recipe("fake"):is_valid("recipe"))
            local recipe = Recipe("fake")
            assert.not_truthy(recipe:is_valid())
            assert.not_truthy(recipe:is_valid("recipe"))
        end)
    end)

    describe(':copy', function()

        it('should error without a new name', function()
            assert.has_error(function() Recipe:get("stone-furnace"):copy() end)
        end)

        it('should extend a recipe copy and return it', function()
            assert.is_nil(Raw["fake"])
            local recipe = Recipe("stone-furnace"):copy("fake")
            assert.truthy(Raw["fake"])
            assert.same(Raw["fake"].name, recipe.name)
        end)
    end)

    describe(':make_difficult', function()
        it('is a no-op that logs a deprecation once', function()
            local Deprecate = require('__stdlib2__/stdlib/utils/deprecate')
            Deprecate.reset()
            local s = spy.on(_G, 'log')
            local raw = Raw["stone-furnace"]
            local before = table.deepcopy(raw)
            local recipe = Recipe("stone-furnace")
            assert.equals(recipe, recipe:make_difficult())
            recipe:make_difficult()
            assert.same(before, raw)
            assert.is_nil(raw.normal)
            assert.is_nil(raw.expensive)
            assert.spy(s).was_called(1)
            s:revert()
        end)
    end)

    describe(':change_category', function()
        it('should change the category if it exists', function()
            local raw = _G["data"].raw.recipe["stone-furnace"]
            Recipe("stone-furnace"):change_category("hand-held")
            assert.same({"hand-held"}, raw.categories)
            Recipe("stone-furnace"):change_category("advanced-crafting") -- does not exist
            assert.same({"hand-held"}, raw.categories)
            assert.is_nil(raw.category)
        end)

        it('clears the legacy category field', function()
            local raw = _G["data"].raw.recipe["iron-gear-wheel"]
            raw.category = "smelting"
            Recipe("iron-gear-wheel"):change_category("crafting")
            assert.is_nil(raw.category)
            assert.same({"crafting"}, raw.categories)
        end)
    end)

    describe(':add_category / :remove_category / :has_category', function()
        it('treats a recipe without categories as crafting', function()
            local r = Recipe("iron-gear-wheel")
            assert.is_true(r:has_category("crafting"))
            assert.is_false(r:has_category("smelting"))
        end)

        it('adds a category once', function()
            local raw = _G["data"].raw.recipe["iron-gear-wheel"]
            Recipe("iron-gear-wheel"):add_category("smelting"):add_category("smelting")
            assert.same({"crafting", "smelting"}, raw.categories)
            Recipe("iron-gear-wheel"):add_category("nope")
            assert.same({"crafting", "smelting"}, raw.categories)
        end)

        it('removes a category but keeps the last one', function()
            local raw = _G["data"].raw.recipe["iron-gear-wheel"]
            Recipe("iron-gear-wheel"):add_category("smelting"):remove_category("crafting")
            assert.same({"smelting"}, raw.categories)
            Recipe("iron-gear-wheel"):remove_category("smelting")
            assert.same({"smelting"}, raw.categories)
        end)
    end)

    describe('ingredients', function()
        local raw
        before_each(function() raw = _G["data"].raw.recipe["iron-gear-wheel"] end)

        it(':add_ingredient formats strings and short tables', function()
            Recipe("iron-gear-wheel"):add_ingredient("copper-plate"):add_ingredient({"stone", 3}):add_ingredient("water")
            assert.same({type = "item", name = "copper-plate", amount = 1}, raw.ingredients[2])
            assert.same({type = "item", name = "stone", amount = 3}, raw.ingredients[3])
            assert.same({type = "fluid", name = "water", amount = 1}, raw.ingredients[4])
        end)

        it(':add_ingredient keeps a full table and probabilities', function()
            Recipe("iron-gear-wheel"):add_ingredient({type = "item", name = "stone", amount_min = 1, amount_max = 2})
            assert.same({type = "item", name = "stone", amount_min = 1, amount_max = 2}, raw.ingredients[2])
            assert.has_error(function() Recipe("iron-gear-wheel"):add_ingredient({type = "item", name = "stone"}) end)
        end)

        it(':add_ingredient ignores unknown items', function()
            Recipe("iron-gear-wheel"):add_ingredient("does-not-exist")
            assert.same(1, #raw.ingredients)
        end)

        it('ignores the expensive argument and logs once', function()
            local Deprecate = require('__stdlib2__/stdlib/utils/deprecate')
            Deprecate.reset()
            local s = spy.on(_G, 'log')
            Recipe("iron-gear-wheel"):add_ingredient("stone", "copper-plate"):add_ingredient("stone", true)
            assert.same(3, #raw.ingredients)
            assert.is_nil(raw.expensive)
            assert.spy(s).was_called(1)
            s:revert()
        end)

        it(':remove_ingredient removes every match by string or table', function()
            Recipe("iron-gear-wheel"):add_ingredient("iron-plate"):add_ingredient("stone")
            Recipe("iron-gear-wheel"):remove_ingredient("iron-plate")
            assert.same({{type = "item", name = "stone", amount = 1}}, raw.ingredients)
            Recipe("iron-gear-wheel"):remove_ingredient({type = "item", name = "stone", amount = 1})
            assert.same({}, raw.ingredients)
        end)

        it(':replace_ingredient replaces and can keep the amount', function()
            Recipe("iron-gear-wheel"):replace_ingredient("iron-plate", "copper-plate")
            assert.same({type = "item", name = "copper-plate", amount = 2}, raw.ingredients[1])
            Recipe("iron-gear-wheel"):replace_ingredient("copper-plate", {type = "item", name = "stone", amount = 7})
            assert.same({type = "item", name = "stone", amount = 7}, raw.ingredients[1])
        end)

        it(':clear_ingredients', function()
            Recipe("iron-gear-wheel"):clear_ingredients()
            assert.same({}, raw.ingredients)
        end)
    end)

    describe('results', function()
        local raw
        before_each(function() raw = _G["data"].raw.recipe["iron-gear-wheel"] end)

        it(':add_result creates the results table when missing', function()
            raw.results = nil
            Recipe("iron-gear-wheel"):add_result("copper-plate")
            assert.same({{type = "item", name = "copper-plate", amount = 1}}, raw.results)
        end)

        it(':add_result sets main_product', function()
            Recipe("iron-gear-wheel"):add_result({type = "item", name = "stone", amount = 1, probability = 0.5}, nil, "iron-gear-wheel")
            assert.same(2, #raw.results)
            assert.same(0.5, raw.results[2].probability)
            assert.same("iron-gear-wheel", raw.main_product)
        end)

        it(':remove_result removes all matches', function()
            Recipe("iron-gear-wheel"):add_result("iron-gear-wheel")
            Recipe("iron-gear-wheel"):remove_result("iron-gear-wheel")
            assert.same({}, raw.results)
        end)

        it(':replace_result', function()
            Recipe("iron-gear-wheel"):replace_result("iron-gear-wheel", {type = "item", name = "stone", amount = 3})
            assert.same({{type = "item", name = "stone", amount = 3}}, raw.results)
        end)

        it(':set_main_product and :remove_main_product', function()
            Recipe("iron-gear-wheel"):set_main_product("iron-gear-wheel")
            assert.same("iron-gear-wheel", raw.main_product)
            Recipe("iron-gear-wheel"):remove_main_product()
            assert.is_nil(raw.main_product)
            Recipe("iron-gear-wheel"):set_main_product(true, "stone")
            assert.same("stone", raw.main_product)
        end)
    end)

    describe(':set_enabled', function()
        it('sets enabled', function()
            local raw = _G["data"].raw.recipe["stone-furnace"]
            Recipe("stone-furnace"):set_enabled(true)
            assert.is_true(raw.enabled)
            Recipe("stone-furnace"):set_enabled(false)
            assert.is_false(raw.enabled)
        end)
    end)

    describe(':convert_results', function()
        it('converts legacy result/result_count and short ingredients', function()
            local raw = {type = "recipe", name = "legacy", ingredients = {{"iron-plate", 2}, {name = "water", amount = 5}},
                result = "iron-gear-wheel", result_count = 2}
            _G.data:extend({raw})
            Recipe("legacy"):convert_results()
            assert.is_nil(raw.result)
            assert.is_nil(raw.result_count)
            assert.same({{type = "item", name = "iron-gear-wheel", amount = 2}}, raw.results)
            assert.same({type = "item", name = "iron-plate", amount = 2}, raw.ingredients[1])
            assert.same("water", raw.ingredients[2].name)
            assert.same("fluid", raw.ingredients[2].type)
        end)

        it('moves a left over normal version to the top level and drops expensive', function()
            local raw = {type = "recipe", name = "legacy2",
                normal = {enabled = false, energy_required = 1, ingredients = {{"iron-plate", 1}}, result = "iron-gear-wheel"},
                expensive = {enabled = false, energy_required = 2, ingredients = {{"iron-plate", 2}}, result = "iron-gear-wheel"}}
            _G.data:extend({raw})
            Recipe("legacy2"):convert_results()
            assert.is_nil(raw.normal)
            assert.is_nil(raw.expensive)
            assert.same(1, raw.energy_required)
            assert.same({{type = "item", name = "iron-plate", amount = 1}}, raw.ingredients)
            assert.same({{type = "item", name = "iron-gear-wheel", amount = 1}}, raw.results)
        end)
    end)

    describe(':copy (results)', function()
        it('renames a single result', function()
            local recipe = Recipe("stone-furnace"):copy("furnace-2")
            assert.same("furnace-2", _G.data.raw.recipe["furnace-2"].results[1].name)
            assert.same("stone-furnace", _G.data.raw.recipe["stone-furnace"].results[1].name)
            assert.is_not_nil(recipe)
        end)

        it('does not fail without results', function()
            _G.data:extend({{type = "recipe", name = "empty", ingredients = {}}})
            assert.has_no.errors(function() Recipe("empty"):copy("empty-2") end)
        end)
    end)

    describe(':pairs()', function()
        it('should classify everything', function()
            for _, class in Recipe:pairs('recipe') do
                assert.same('Recipe', class.__class)
            end
        end)

        -- it('should work without a paramater', function()
        --     for _, class in Recipe:pairs() do
        --         assert.same('Recipe', class.__class)
        --     end
        -- end)
        it('should work on a class', function()
            local r = Recipe('stone-furnace')
            local count = 0
            for _, class in r:pairs() do
                assert.same('Recipe', class.__class)
                count = count + 1
            end
            assert.same(table.size(_G["data"].raw.recipe), count)
        end)
    end)

    describe(':add_unlock', function()
        it('should add the unlock if the tech exists', function()
            Recipe("stone-furnace"):add_unlock("steel-processing")
            log(Rawtech.effects)
            assert.same("stone-furnace", Rawtech.effects[3].recipe)
            assert.not_truthy(_G["data"].raw.recipe["stone-furnace"].enabled)
        end)

        it('should not do anything if the tech doesnt exist', function()
            local s = spy.on(_G, "log")
            Recipe("stone-furnace"):add_unlock("fake")
            assert.spy(s).was_called(1)
        end)
    end)

    describe(':remove_unlock', function()
        it('should remove the unlock from the tech if it exists', function()
            Recipe("steel-plate"):remove_unlock("steel-processing")
            assert.same(1, #Rawtech.effects)
        end)

        -- it('should remove the unlock from all techs', function()
        --     Recipe("steel-plate"):remove_unlock()
        --     assert.same(2, #Rawtech.effects)
        --     assert.same(0, #_G.data.raw["technology"]["steel-processing-2"].effects)
        -- end)

    end)
end)
