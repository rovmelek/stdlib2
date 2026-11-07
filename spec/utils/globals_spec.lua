require('spec/setup/busted')()

local Env = require('spec/setup/factorio_env')

local names = { 'inspect', 'traceback', 'data_traceback', 'prequire', 'rawtostring', 'inline_if', 'concat', 'STDLIB' }

-- every stdlib module that does not need a stage specific global
local modules = {
    'core', 'game', 'area/area', 'area/position', 'area/direction', 'area/orientation', 'area/chunk', 'area/tile',
    'area/surface', 'entity/entity', 'entity/inventory', 'entity/resource', 'event/event', 'event/player',
    'event/force', 'event/surface', 'event/changes', 'event/gui', 'event/trains', 'misc/config', 'misc/logger',
    'misc/queue', 'utils/color', 'utils/table', 'utils/string', 'utils/math', 'utils/is', 'scripts/interface',
}

local function clear_globals()
    for _, name in pairs(names) do _G[name] = nil end
    for _, name in pairs { 'color', 'anticolor', 'lightcolor', 'time' } do defines[name] = nil end
end

describe('globals', function()
    before_each(function()
        Env.install()
        clear_globals()
    end)

    after_each(function()
        require('__stdlib2__/stdlib/config').no_globals = nil
    end)

    it('adds the helpers and defines by default', function()
        require('__stdlib2__/stdlib/core')
        for _, name in pairs(names) do
            assert.is_not_nil(_G[name], name)
        end
        assert.is_not_nil(defines.color)
        assert.is_not_nil(defines.time)
    end)

    it('adds nothing with config.no_globals', function()
        require('__stdlib2__/stdlib/config').no_globals = true
        require('__stdlib2__/stdlib/core')
        for _, name in pairs(names) do
            assert.is_nil(_G[name], name)
        end
        for _, name in pairs { 'color', 'anticolor', 'lightcolor', 'time' } do
            assert.is_nil(defines[name], name)
        end
    end)

    it('exposes the helpers and defines as module return values', function()
        require('__stdlib2__/stdlib/config').no_globals = true
        local G = require('__stdlib2__/stdlib/utils/globals')
        for _, name in pairs(names) do
            if name ~= 'STDLIB' then
                assert.is_not_nil(G[name], name)
            end
        end
        assert.is_function(G.install_math)
        assert.same({ r = 1, g = 0, b = 0, a = 1 }, require('__stdlib2__/stdlib/utils/defines/color').red)
        assert.is_not_nil(require('__stdlib2__/stdlib/utils/defines/time').second)
    end)

    it('lets every module load and work without globals', function()
        require('__stdlib2__/stdlib/config').no_globals = true
        for _, module in pairs(modules) do
            assert.has_no.errors(function() require('__stdlib2__/stdlib/' .. module) end, module)
        end
        for _, name in pairs(names) do
            assert.is_nil(_G[name], name)
        end
        local Position = require('__stdlib2__/stdlib/area/position')
        assert.same('x1y2', (Position(1, 2) .. ''):gsub('[^%w]', ''))
    end)

    it('lets data stage modules load without globals', function()
        require('__stdlib2__/stdlib/config').no_globals = true
        require('spec/setup/data_fixtures').reset()
        clear_globals()
        for _, module in pairs { 'data/data', 'data/recipe', 'data/item', 'data/technology', 'data/entity', 'data/category', 'data/fluid' } do
            assert.has_no.errors(function() require('__stdlib2__/stdlib/' .. module) end, module)
        end
        assert.is_nil(_G.inspect)
        assert.is_nil(_G.data_traceback)
        -- logging an invalid object uses data_traceback internally
        local Data = require('__stdlib2__/stdlib/data/data')
        assert.has_no.errors(function() Data('nope', 'item') end)
    end)
end)
