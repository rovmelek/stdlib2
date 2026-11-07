--- Accessor for the `storage` table (called `global` before Factorio 2.0).
-- <p>Every key that stdlib2 stores in `storage` is listed in @{Storage.KEYS}. Keys keep the names they have
-- always had so saves stay compatible; never rename them.
-- <p>`storage` is read only in `on_load`, writing to it there desyncs multiplayer games. @{Storage.get}
-- (when it has to create the table) and @{Storage.set} raise a clear error in that case.
-- @module Utils.Storage
-- @usage
-- local Storage = require('__stdlib2__/stdlib/utils/storage')
-- local registry = Storage.get(Storage.KEYS.train_registry, function() return {} end)

local Storage = {
    __class = 'Storage',
    --- Is stdlib2 currently dispatching `on_load`? Set by the Event module.
    loading = false
}

--- Every `storage` key used by stdlib2.
-- @table KEYS
Storage.KEYS = {
    players = 'players', -- Player data, indexed by player index
    forces = 'forces', -- Force data, indexed by force name
    surfaces = 'surfaces', -- Surface data, indexed by surface index
    train_registry = '_train_registry', -- LuaTrain objects indexed by LuaTrain.id
    entity_data = '_entity_data', -- Entity.set_data, indexed by unit number or by entity name
    entity_data_reg = '_entity_data_reg', -- registration number of register_on_object_destroyed -> unit number
    chunk_data = '_chunk_data', -- Chunk.set_data
    tile_data = '_tile_data', -- Tile.set_data
    print_queue = '_print_queue', -- Game.print_all messages for when no players exist yet
    changes = '_changes' -- versions that already ran their Changes migration
}

local function assert_writable(key)
    if Storage.loading then
        error('stdlib2: storage.' .. tostring(key) .. ' can not be written in on_load, it is read only there', 3)
    end
end

--- Get the value stored under a key.
-- @tparam string key
-- @tparam[opt] function default_factory when the key is empty, the value this function returns is stored and returned
-- @return the stored value
function Storage.get(key, default_factory)
    local value = storage[key]
    if value == nil and default_factory then
        assert_writable(key)
        value = default_factory()
        storage[key] = value
    end
    return value
end

--- Store a value under a key.
-- @tparam string key
-- @param value
-- @return value
function Storage.set(key, value)
    assert_writable(key)
    storage[key] = value
    return value
end

--- A default factory that creates an empty table.
-- @treturn table
function Storage.new_table()
    return {}
end

return Storage
