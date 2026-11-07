require('spec/setup/busted')()

local Technology

describe(
    'Technology',
    function()
        before_each(
            function()
                require('spec/setup/data_fixtures').reset()
                Technology = require('__stdlib2__/stdlib/data/technology')
            end
        )

        after_each(
            function()
                package.remove_stdlib()
            end
        )

        describe(
            ':get',
            function()
                it(
                    'should get a Technology',
                    function()
                        assert.not_nil(Technology('steel-processing-2'))
                        assert.not_nil(Technology('fake'))
                    end
                )
            end
        )

        describe(
            ':add_prereq',
            function()
                it(
                    'should add a prereq',
                    function()
                        local t = Technology('advanced-electronics')
                        assert.same(1, #t.prerequisites)
                        t:add_prereq('automation')
                        assert.same(2, #t.prerequisites)
                    end
                )
                it(
                    "should not add a prereq that doesn't exist",
                    function()
                        local t = Technology('advanced-electronics')
                        assert.same(1, #t.prerequisites)
                        t:add_prereq('fake')
                        assert.same(1, #t.prerequisites)
                    end
                )
                it(
                    'should not duplicate prereqs',
                    function()
                        local t = Technology('advanced-electronics')
                        assert.same(1, #t.prerequisites)
                        t:add_prereq('automation')
                        assert.same(2, #t.prerequisites)
                        t:add_prereq('automation')
                        assert.same(2, #t.prerequisites)
                    end
                )
            end
        )
        describe(
            ':remove_prereq',
            function()
                it(
                    'should remove a prereq',
                    function()
                        local t = Technology('advanced-electronics')
                        assert.same(1, #t.prerequisites)
                        t:remove_prereq('plastics')
                        assert.is_nil(t.prerequisites)
                    end
                )
                it(
                    'should not error if there are no prequisites',
                    function()
                    end
                )
            end
        )
        describe(':add_effect', function()
            it('adds a recipe unlock and creates effects when nil', function()
                _G.data.raw.technology.automation.effects = nil
                Technology('automation'):add_effect('stone-furnace')
                assert.same({ { type = 'unlock-recipe', recipe = 'stone-furnace' } }, _G.data.raw.technology.automation.effects)
            end)

            it('appends non recipe effects as is', function()
                local effect = { type = 'mining-drill-productivity-bonus', modifier = 0.2 }
                Technology('automation'):add_effect(effect)
                assert.same({ effect }, _G.data.raw.technology.automation.effects)
            end)

            it('ignores unknown recipes', function()
                Technology('automation'):add_effect('fake')
                assert.same(0, #_G.data.raw.technology.automation.effects)
            end)
        end)

        describe(':remove_effect', function()
            it('removes every matching unlock from a technology', function()
                local raw = _G.data.raw.technology['steel-processing']
                table.insert(raw.effects, { type = 'unlock-recipe', recipe = 'steel-plate' })
                Technology('steel-processing'):remove_effect(nil, 'unlock-recipe', 'steel-plate')
                assert.same(1, #raw.effects)
                assert.same('mining-drill-productivity-bonus', raw.effects[1].type)
            end)

            it('removes all effects of a type when name is nil', function()
                local raw = _G.data.raw.technology['steel-processing']
                Technology('steel-processing'):remove_effect(nil, 'mining-drill-productivity-bonus')
                assert.same(1, #raw.effects)
                assert.same('unlock-recipe', raw.effects[1].type)
            end)
        end)

        describe('science packs', function()
            it(':add_pack accepts both shapes', function()
                local t = Technology('automation')
                t:add_pack('iron-plate', 2)
                t:add_pack({ 'copper-plate', 3 })
                t:add_pack({ type = 'item', name = 'stone', amount = 4 })
                local ings = _G.data.raw.technology.automation.unit.ingredients
                assert.same({ 'iron-plate', 2 }, ings[2])
                assert.same({ 'copper-plate', 3 }, ings[3])
                assert.same({ 'stone', 4 }, ings[4])
            end)

            it(':remove_pack and :replace_pack', function()
                local t = Technology('automation')
                t:replace_pack('automation-science-pack', 'iron-plate', 5)
                local ings = _G.data.raw.technology.automation.unit.ingredients
                assert.same({ 'iron-plate', 5 }, ings[1])
                t:remove_pack('iron-plate')
                assert.same(0, #ings)
            end)

            it('does nothing when the technology uses a research_trigger', function()
                local raw = _G.data.raw.technology['steam-power']
                local t = Technology('steam-power')
                assert.has_no.errors(function()
                    t:add_pack('iron-plate'):remove_pack('iron-plate'):replace_pack('a', 'b')
                end)
                assert.is_nil(raw.unit)
            end)
        end)

        describe(':set_research_trigger / :set_unit', function()
            it('switches between unit and research_trigger', function()
                local raw = _G.data.raw.technology.automation
                local trigger = { type = 'craft-item', item = 'iron-plate', count = 1 }
                Technology('automation'):set_research_trigger(trigger)
                assert.same(trigger, raw.research_trigger)
                assert.is_nil(raw.unit)
                local unit = { count = 1, time = 1, ingredients = {} }
                Technology('automation'):set_unit(unit)
                assert.same(unit, raw.unit)
                assert.is_nil(raw.research_trigger)
            end)
        end)
    end
)
