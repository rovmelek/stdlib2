--- Detect which Factorio stage the code is running in.
-- @module Utils.Stage
-- @usage
-- local Stage = require('__stdlib2__/stdlib/utils/stage')
-- Stage.assert('control', 'Event')

local Stage = {
    __class = 'Stage'
}

local from_helpers = {
    settings = 'settings',
    prototype = 'data',
    runtime = 'control'
}

--- The current stage.
-- Uses `helpers.stage` when the game provides it, otherwise falls back to checking the
-- stage specific globals.
-- @treturn string `'settings'`, `'data'` or `'control'`
function Stage.current()
    local helpers = rawget(_G, 'helpers')
    if type(helpers) == 'table' or type(helpers) == 'userdata' then
        local ok, stage = pcall(function() return helpers.stage end)
        if ok and from_helpers[stage] then
            return from_helpers[stage]
        end
    end
    if rawget(_G, 'remote') and rawget(_G, 'script') then
        return 'control'
    end
    if rawget(_G, 'settings') and rawget(_G, 'data') and not rawget(_G, 'mods') then
        return 'settings'
    end
    return 'data'
end

--- Raise an error if the current stage is not the expected one.
-- @tparam string expected `'settings'`, `'data'` or `'control'`
-- @tparam string module_name the name used in the error message
function Stage.assert(expected, module_name)
    if Stage.current() ~= expected then
        error(module_name .. ' can only be required in the ' .. expected .. ' stage', 3)
    end
end

return Stage
