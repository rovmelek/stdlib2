require('spec/setup/busted')()

local Env = require('spec/setup/factorio_env')

describe('scripts/interface', function()
    local interface

    before_each(function()
        Env.install()
        _G.storage = { players = { 'x' } }
        interface = require('__stdlib2__/stdlib/scripts/interface')
    end)

    it('write_storage writes storage.lua through helpers', function()
        interface.write_storage()
        assert.is_truthy(Env.files['stdlib2/storage.lua'])
        assert.is_truthy(Env.files['stdlib2/storage.lua']:find('storage'))
        assert.is_truthy(Env.files['stdlib2/storage.lua']:find('players', 1, true))
        assert.is_nil(Env.files['stdlib2/global.lua'])
    end)

    it('keeps write_global as an alias', function()
        assert.equals(interface.write_storage, interface.write_global)
        interface.write_global()
        assert.is_truthy(Env.files['stdlib2/storage.lua'])
    end)

    it('dump_all prefers write_storage when calling other interfaces', function()
        local called = {}
        _G.remote.interfaces.other = { write_storage = true }
        _G.remote.call = function(name, fn) called[#called + 1] = name .. '.' .. fn end
        game.forces = {}
        interface.dump_all()
        assert.is_truthy(Env.files['defines.lua'])
        assert.same({ 'other.write_storage' }, called)
    end)
end)
