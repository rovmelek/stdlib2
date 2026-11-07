require('spec/setup/busted')()

local Env = require('spec/setup/factorio_env')

local function read_info_version()
    local f = assert(io.open('info.json'))
    local content = f:read('*a')
    f:close()
    return content:match('"version"%s*:%s*"([^"]+)"')
end

describe('Core', function()
    local function load_core()
        package.remove_stdlib()
        return require('__stdlib2__/stdlib/core')
    end

    it('keeps the fallback version in sync with info.json', function()
        local Core = load_core()
        assert.same(read_info_version(), Core._FALLBACK_VERSION)
    end)

    it('reads the version from script.active_mods in the control stage', function()
        Env.install()
        script.active_mods.stdlib2 = '2.5.7'
        assert.same('2.5.7', load_core()._VERSION)
    end)

    it('reads the version from mods in the data stage', function()
        require('spec/setup/data_fixtures').reset()
        _G.mods.stdlib2 = '2.4.0'
        assert.same('2.4.0', load_core()._VERSION)
    end)

    it('falls back to the constant when the mod is not listed', function()
        Env.install()
        script.active_mods.stdlib2 = nil
        local Core = load_core()
        assert.same(Core._FALLBACK_VERSION, Core._VERSION)
    end)

    describe('.require_version', function()
        local Core
        before_each(function()
            Env.install()
            script.active_mods.stdlib2 = '2.1.3'
            Core = load_core()
        end)

        it('accepts older or equal minimums', function()
            assert.has_no.errors(function() Core.require_version('2.1.3') end)
            assert.has_no.errors(function() Core.require_version('2.0.9') end)
            assert.has_no.errors(function() Core.require_version('1.9.9') end)
        end)

        it('errors with a clear message when stdlib2 is older', function()
            local ok, err = pcall(Core.require_version, '2.2.0')
            assert.is_false(ok)
            assert.is_truthy(err:find('2.2.0', 1, true))
            assert.is_truthy(err:find('2.1.3', 1, true))
        end)

        it('works without helpers.compare_versions', function()
            _G.helpers.compare_versions = nil
            assert.has_error(function() Core.require_version('3.0.0') end)
            assert.has_no.errors(function() Core.require_version('2.1.0') end)
        end)

        it('is available on modules through their __index', function()
            local Game = require('__stdlib2__/stdlib/game')
            assert.is_function(Game.require_version)
        end)
    end)
end)
