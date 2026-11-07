--- Settings of the library itself.
-- Set the options before requiring other stdlib2 modules.
-- @module Config
-- @usage
-- local config = require('__stdlib2__/stdlib/config')
-- config.no_globals = true -- must be set before any other stdlib2 module is required
-- @field[opt=false] boolean no_globals do not add `inspect`, `traceback`, `data_traceback`, `prequire`,
-- `rawtostring`, `inline_if`, `concat` and `STDLIB` to the global environment, and do not add `color`, `anticolor`,
-- `lightcolor` and `time` to `defines`. Require `stdlib/utils/globals` and `stdlib/utils/defines/*` for them instead.
return {}
