require('spec/setup/busted')()

local Env = require('spec/setup/factorio_env')

describe('Storage', function()
    local Storage

    before_each(function()
        Env.install()
        Storage = require('__stdlib2__/stdlib/utils/storage')
    end)

    it('.get reads without creating', function()
        assert.is_nil(Storage.get('players'))
        assert.is_nil(storage.players)
        storage.players = { 1 }
        assert.same({ 1 }, Storage.get('players'))
    end)

    it('.get creates through the default factory once', function()
        local calls = 0
        local factory = function() calls = calls + 1 return { n = calls } end
        assert.same({ n = 1 }, Storage.get('forces', factory))
        assert.same({ n = 1 }, Storage.get('forces', factory))
        assert.same(1, calls)
        assert.same({ n = 1 }, storage.forces)
    end)

    it('.set stores a value', function()
        assert.same('x', Storage.set('surfaces', 'x'))
        assert.same('x', storage.surfaces)
    end)

    it('raises a clear error when writing in on_load but still reads', function()
        storage.players = { 1 }
        Storage.loading = true
        assert.same({ 1 }, Storage.get('players', Storage.new_table))
        assert.same({ 1 }, Storage.get('players'))
        local ok, err = pcall(Storage.get, 'forces', Storage.new_table)
        assert.is_false(ok)
        assert.is_truthy(err:find('on_load', 1, true))
        assert.is_false(pcall(Storage.set, 'forces', {}))
        assert.is_nil(storage.forces)
        Storage.loading = false
    end)

    it('lists every storage key used by stdlib2', function()
        local listed = {}
        for _, key in pairs(Storage.KEYS) do listed[key] = true end

        -- find `storage.<key>` and `storage._key` usages in the sources
        local used = {}
        local p = io.popen('find stdlib -name "*.lua" -not -path "stdlib/vendor/*"')
        for file in p:lines() do
            local f = io.open(file)
            for line in f:lines() do
                if not line:match('^%s*%-%-') then
                    for key in line:gmatch('storage%.([%w_]+)') do
                        used[key] = file
                    end
                end
            end
            f:close()
        end
        p:close()
        used['lua'] = nil -- the file name storage.lua inside strings
        for key, file in pairs(used) do
            assert.is_true(listed[key] == true, 'storage.' .. key .. ' (' .. file .. ') is not listed in Storage.KEYS')
        end
    end)

    it('does not rename the keys of earlier releases', function()
        local keys = Storage.KEYS
        assert.same('players', keys.players)
        assert.same('forces', keys.forces)
        assert.same('surfaces', keys.surfaces)
        assert.same('_train_registry', keys.train_registry)
        assert.same('_entity_data', keys.entity_data)
        assert.same('_chunk_data', keys.chunk_data)
        assert.same('_tile_data', keys.tile_data)
        assert.same('_print_queue', keys.print_queue)
        assert.same('_changes', keys.changes)
    end)
end)
