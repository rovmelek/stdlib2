require('spec/setup/busted')()

local Env = require('spec/setup/factorio_env')

describe('Deprecate', function()
    local Deprecate

    before_each(function()
        Env.install()
        Deprecate = require('__stdlib2__/stdlib/utils/deprecate')
    end)

    it('logs once per key', function()
        assert.is_true(Deprecate.warn('a', 'a is old'))
        assert.is_false(Deprecate.warn('a', 'a is old'))
        assert.is_true(Deprecate.warn('b', 'b is old'))
        assert.same({ 'stdlib2: DEPRECATED: a is old', 'stdlib2: DEPRECATED: b is old' }, Env.logs)
    end)

    it('can be reset', function()
        Deprecate.warn('a', 'a')
        Deprecate.reset()
        assert.is_true(Deprecate.warn('a', 'a'))
    end)

    it('requires a string key', function()
        assert.has_error(function() Deprecate.warn(nil, 'x') end)
    end)

    it('is used by STDLIB.reload_class', function()
        local STDLIB = require('__stdlib2__/stdlib/utils/globals')
        STDLIB.reload_class()
        STDLIB.reload_class()
        assert.same(1, #Env.logs)
    end)
end)
