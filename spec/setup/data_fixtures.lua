-- Minimal Factorio 2.x format `data.raw` for specs of the data-stage helpers.
-- Replaces faketorio/dataloader (which carried 1.x data).
local Fixtures = {}

local function item(name, extra)
    local t = { type = 'item', name = name, icon = '__base__/graphics/icons/' .. name .. '.png', icon_size = 64,
        stack_size = 100, subgroup = 'raw-material' }
    for k, v in pairs(extra or {}) do t[k] = v end
    return t
end

local function recipe(name, ingredients, results, extra)
    local t = { type = 'recipe', name = name, enabled = false, energy_required = 0.5,
        ingredients = ingredients, results = results }
    for k, v in pairs(extra or {}) do t[k] = v end
    return t
end

local function i(name, amount) return { type = 'item', name = name, amount = amount } end

local function tech(name, extra)
    local t = { type = 'technology', name = name, icon = '__base__/graphics/technology/' .. name .. '.png',
        icon_size = 256, effects = {}, unit = { count = 10, time = 15, ingredients = { { 'automation-science-pack', 1 } } } }
    for k, v in pairs(extra or {}) do t[k] = v end
    return t
end

--- Build a fresh data.raw and install `_G.data`, with the control-stage globals removed.
-- @treturn table data
function Fixtures.reset()
    -- stdlib detects the data stage by the absence of these
    _G.script, _G.remote, _G.game, _G.storage, _G.helpers = nil, nil, nil, nil, nil
    _G.mods = { base = '2.1.0', stdlib2 = '2.1.0' }

    local data = { raw = {} }
    function data:extend(protos)
        for _, proto in ipairs(protos) do
            self.raw[proto.type] = self.raw[proto.type] or {}
            self.raw[proto.type][proto.name] = proto
        end
    end
    _G.data = data

    data:extend {
        { type = 'item-group', name = 'intermediate-products', order = 'c' },
        { type = 'item-subgroup', name = 'raw-material', group = 'intermediate-products', order = 'a' },
        { type = 'item-subgroup', name = 'intermediate-product', group = 'intermediate-products', order = 'b' },
        { type = 'recipe-category', name = 'crafting' },
        { type = 'recipe-category', name = 'smelting' },
        { type = 'recipe-category', name = 'hand-held' },
        { type = 'fuel-category', name = 'chemical' },
        { type = 'fluid', name = 'water', default_temperature = 15, base_color = {0, 0, 1}, flow_color = {1, 1, 1},
            icon = '__base__/graphics/icons/fluid/water.png', icon_size = 64 },
        item('iron-plate'), item('copper-plate'), item('stone'), item('steel-plate'),
        item('iron-gear-wheel', { subgroup = 'intermediate-product' }),
        item('plastic-bar', { subgroup = 'intermediate-product' }),
        item('stone-furnace', { subgroup = 'intermediate-product', place_result = 'stone-furnace' }),
        item('coal', { fuel_value = '4MJ', fuel_categories = { 'chemical' } }),
        item('wood', { fuel_value = '2MJ', fuel_category = 'chemical' }), -- legacy field on purpose
        { type = 'capsule', name = 'cliff-explosives', flags = { 'hide-from-bonus-gui' }, stack_size = 20,
            icon = '__base__/graphics/icons/cliff-explosives.png', icon_size = 64 },
        recipe('stone-furnace', { i('stone', 5) }, { i('stone-furnace', 1) }, { categories = { 'crafting' } }),
        recipe('iron-gear-wheel', { i('iron-plate', 2) }, { i('iron-gear-wheel', 1) }),
        recipe('steel-plate', { i('iron-plate', 5) }, { i('steel-plate', 1) }, { energy_required = 16, categories = { 'smelting' } }),
        {
            type = 'lab', name = 'lab', inputs = { 'automation-science-pack' }, energy_usage = '60kW',
            icon = '__base__/graphics/icons/lab.png', icon_size = 64, minable = { mining_time = 0.2, result = 'lab' },
        },
        {
            type = 'assembling-machine', name = 'assembling-machine-1', crafting_speed = 0.5,
            crafting_categories = { 'crafting' }, energy_usage = '75kW',
            icon = '__base__/graphics/icons/assembling-machine-1.png', icon_size = 64,
            minable = { mining_time = 0.2, result = 'assembling-machine-1' },
        },
        tech('automation'),
        tech('plastics'),
        tech('advanced-electronics', { prerequisites = { 'plastics' } }),
        tech('steel-processing', { effects = {
            { type = 'unlock-recipe', recipe = 'steel-plate' },
            { type = 'mining-drill-productivity-bonus', modifier = 0.1 },
        } }),
        tech('steel-processing-2', { prerequisites = { 'steel-processing' } }),
        tech('steam-power', { unit = false, research_trigger = { type = 'craft-item', item = 'iron-gear-wheel', count = 1 } }),
    }
    data.raw.technology['steam-power'].unit = nil

    return data
end

return Fixtures
