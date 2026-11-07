-- luacheck configuration for Factorio 2.x.
-- This replaces the downloaded Nexela/Factorio-luacheckrc, which is generated for Factorio 0.18 and does not know
-- `storage`, `helpers`, `prototypes` and the 2.x fields. The Factorio globals are listed without fields, so
-- luacheck accepts any field on them.
std = 'lua52'
quiet = 1
codes = true
max_line_length = false
max_code_line_length = false
max_string_line_length = false
max_comment_line_length = false
max_cyclomatic_complexity = false

ignore = { '111/__', '21./%w+_$', '21./^_[_%w]+$', '213/^%a$', '213/index', '213/key', '11[12]/[Tt]est[%w_]+' }
not_globals = { 'coroutine', 'io', 'socket', 'dofile', 'loadfile' }

exclude_files = { '.lua/', '.luarocks/', '.install/', 'stdlib/vendor/', 'wiki/', 'doc/', '**/.trash/', '**/.history/', '**/.vscode/' }

globals = {
    'script', 'game', 'defines', 'data', 'mods', 'settings', 'remote', 'commands', 'rcon', 'rendering',
    'prototypes', 'helpers', 'storage', 'log', 'localised_print', 'serpent', 'table_size', 'feature_flags',
}

-- The specs replace the Factorio environment (spec/setup/factorio_env.lua) and use busted
files['spec/'] = {
    std = 'lua52+busted',
    globals = { 'io', 'loadfile', 'package' },
    ignore = { '11.', '12.', '14.', '21.', '43.' },
}
