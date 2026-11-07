--- The Core module loads some helper functions and globals useful in all stages
-- of a mods life cycle. All modules have an __index method into core.
-- @module Core
-- @usage local Core = require('__stdlib2__/stdlib/core')

-- require global helper functions.
require('__stdlib2__/stdlib/utils/globals')

-- Version of this library when the game does not tell: keep in sync with info.json (a spec compares them).
local FALLBACK_VERSION = '2.1.0'

--- The loaded version of stdlib2: the version of the mod in `script.active_mods` (control stage) or `mods` (data and
-- settings stages), a constant that matches info.json otherwise.
local function detect_version()
    local ok, version = pcall(function()
        local script = rawget(_G, 'script')
        local active_mods = script and script.active_mods
        if active_mods then
            return active_mods['stdlib2']
        end
        local mods = rawget(_G, 'mods')
        return mods and mods['stdlib2']
    end)
    return ok and version or FALLBACK_VERSION
end

local Core = {
    _VERSION = detect_version(),
    _FALLBACK_VERSION = FALLBACK_VERSION,
    _DESCRIPTION = 'Factorio Lua Standard Library Project',
    _URL = 'https://github.com/Afforess/Factorio-Stdlib',
    _LICENSE = [[
        MIT LICENSE

        Copyright (c) 2016, Afforess

        Permission to use, copy, modify, and/or distribute this software for any
        purpose with or without fee is hereby granted, provided that the above
        copyright notice and this permission notice appear in all copies.

        THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
        WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
        MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
        ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
        WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
        ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
        OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
    ]],
    __class = 'Core',
    __call = function(t, ...)
        return t:__call(...)
    end,
    __config = require('__stdlib2__/stdlib/config')
}

Core.Unique_Array = require('__stdlib2__/stdlib/utils/classes/unique_array')
Core.String_Array = Core.Unique_Array

local function compare_versions(a, b)
    local helpers = rawget(_G, 'helpers')
    if helpers and helpers.compare_versions then
        return helpers.compare_versions(a, b)
    end
    local pa, pb = {}, {}
    for n in tostring(a):gmatch('%d+') do pa[#pa + 1] = tonumber(n) end
    for n in tostring(b):gmatch('%d+') do pb[#pb + 1] = tonumber(n) end
    for i = 1, math.max(#pa, #pb) do
        local x, y = pa[i] or 0, pb[i] or 0
        if x ~= y then
            return x < y and -1 or 1
        end
    end
    return 0
end

--- Raise an error if the loaded stdlib2 is older than the version a mod needs.
-- @tparam string min_version the minimum version, for example `'2.1.0'`
-- @usage require('__stdlib2__/stdlib/core').require_version('2.1.0')
function Core.require_version(min_version)
    assert(type(min_version) == 'string', 'min_version must be a string')
    if compare_versions(Core._VERSION, min_version) < 0 then
        error('stdlib2 ' .. min_version .. ' or newer is required, but version ' .. Core._VERSION .. ' is loaded', 2)
    end
end

--- Prints and logs the msg
-- @tparam string msg
-- @treturn boolean true if the message was printed to someone
function Core.log_and_print(msg)
    if game and #game.connected_players > 0 then
        log(script.mod_name .. ':' .. msg)
        game.print(msg)
        return true
    else
        log(msg)
    end
end

if script then
    ---Simple valid check, only available in control stage.
    ---@deprecated
    function Core.VALID_FILTER(v)
        return v and v.valid
    end

    function Core.get_file_path(append)
        return script.mod_name .. '/' .. append
    end
end

local inspect = require('__stdlib2__/stdlib/vendor/inspect')

local function no_meta(item, path)
    if path[#path] == inspect.METATABLE then
        return { item.__class }
    end
    return item
end

--- Inspect the class
function Core.inspect(self)
    return inspect(self, { process = no_meta })
end

--- Help function available on everything.
function Core.help(self)
    local help_string = ''
    local tab = self
    local pat = '^%_%_%_'
    local function sort(a, b)
        if b:find(pat) then
            return false
        end
        return a:find(pat) or a < b
    end
    local function build_string()
        local keys = {}
        for key in pairs(tab) do
            if type(key) ~= 'number' and not key:find('^%_%w') then
                if key == '__class' then
                    key = '___' .. tab.__class
                end
                keys[#keys + 1] = key
            end
        end
        table.sort(keys, sort)
        help_string = help_string .. table.concat(keys, ', ') .. '\n\n'
    end

    while (type(tab) == 'table') do
        build_string()

        local old_meta = tab
        tab = getmetatable(tab)

        if tab then
            if tab ~= old_meta then
                build_string()
            end
            if type(tab.__index) == 'function' then
                tab = tab.__parent
            elseif type(tab.__index == 'table') then
                tab = tab.__index
            end
        end
    end

    return help_string
end

return Core
