--- Deprecation notices.
-- Logs a deprecation message once per key per Lua state, so data-stage loops do not flood `factorio-current.log`.
-- @module Utils.Deprecate
-- @usage
-- local Deprecate = require('__stdlib2__/stdlib/utils/deprecate')
-- Deprecate.warn('my-key', 'foo() is deprecated, use bar()')

local Deprecate = {
    __class = 'Deprecate',
    warned = {}
}

--- Log a deprecation message once per key.
-- @tparam string key a unique key for this notice
-- @tparam string message what is deprecated and what to use instead
-- @treturn boolean true if the message was logged now, false if it had already been logged
function Deprecate.warn(key, message)
    assert(type(key) == 'string', 'key must be a string')
    if Deprecate.warned[key] then
        return false
    end
    Deprecate.warned[key] = true
    log('stdlib2: DEPRECATED: ' .. tostring(message))
    return true
end

--- Forget which notices were logged (used by specs).
function Deprecate.reset()
    Deprecate.warned = {}
end

return Deprecate
