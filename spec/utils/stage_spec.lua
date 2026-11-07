require('spec/setup/busted')()

local Env = require('spec/setup/factorio_env')

describe('Stage', function()
    local Stage

    before_each(function()
        Env.install()
        Stage = require('__stdlib2__/stdlib/utils/stage')
    end)

    it('maps helpers.stage to stdlib stages', function()
        helpers.stage = 'runtime'
        assert.same('control', Stage.current())
        helpers.stage = 'prototype'
        assert.same('data', Stage.current())
        helpers.stage = 'settings'
        assert.same('settings', Stage.current())
    end)

    it('falls back to the stage specific globals without helpers.stage', function()
        helpers.stage = nil
        assert.same('control', Stage.current())
        require('spec/setup/data_fixtures').reset()
        assert.same('data', Stage.current())
    end)

    it('.assert passes in the expected stage', function()
        helpers.stage = 'runtime'
        assert.has_no.errors(function() Stage.assert('control', 'Event') end)
    end)

    it('.assert raises a clear error in another stage', function()
        helpers.stage = 'prototype'
        local ok, err = pcall(Stage.assert, 'control', 'Event')
        assert.is_false(ok)
        assert.is_truthy(err:find('Event can only be required in the control stage', 1, true))
    end)

    it('is used by Event', function()
        helpers.stage = 'prototype'
        package.remove_stdlib()
        assert.has_error(function() require('__stdlib2__/stdlib/event/event') end)
    end)
end)
