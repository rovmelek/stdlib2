# Lua API auxiliary pages (lifecycle, storage, mod structure, libraries, migrations)

Condensed from https://lua-api.factorio.com/latest/index-auxiliary.html and its pages
(docs version 2.1.24; instrument page showed 2.1.16, prototype-tree 2.1.23). None of these
pages contains a 2.1-specific changelog.

## Data lifecycle
**Mod order:** by dependency-chain depth (shorter first), ties by natural sort of name. Same order
is used for event dispatch.

**Settings stage** then **prototype (data) stage**, each one shared Lua state, three rounds over
all mods: `settings.lua` / `settings-updates.lua` / `settings-final-fixes.lua`, then
`data.lua` / `data-updates.lua` / `data-final-fixes.lua`.
- Globals here: `data` (collects prototypes; unknown properties are discarded, missing ones
  default or error), `mods` (name -> version), `settings` (data stage only, startup settings).
  No game instance; no `io`/`os`.
- At end of settings stage, values are read from `mod-settings.dat`.

**Control stage** (per save load), each step completes for all mods before the next:
1. `control.lua` runs in the mod's own Lua state. May use `script`, `remote`, `commands`.
   **`game` and `rendering` are not available.** `storage` is not restored yet.
2. `on_init()` if mod is new to the save (new game, mod added, or control.lua added). Full access.
3. Migrations (JSON first, then Lua; each runs once per save).
4. `on_load()` if mod was already in the save (also on MP join). **No `game`; `storage` read-only
   (writing errors).** Only legit uses: restore unregistered metatables, re-register conditional
   handlers, make local references into `storage`. Anything else desyncs.
5. `on_configuration_changed(ConfigurationChangedData)` if game/mod versions changed, mods
   added/removed, startup setting changed, prototypes added/removed, or a migration ran. Fires
   for all mods or none.
- New mod: control.lua -> on_init -> migrations (no on_load). Existing: control.lua ->
  migrations -> on_load -> (on_configuration_changed).
- MP join: only control.lua and on_load run; registrations must match the host.

## Storage
- `storage` (named `global` before 2.0) is the per-mod persisted table; circular refs OK.
- Allowed: nil, string, number, boolean, tables, LuaObject references. **Functions error on save.**
- Metatables are not saved; those registered with `script.register_metatable(name, mt)` are
  relinked on load; others are dropped.
- `info.json` `migrates_from` moves a removed mod's storage into `storage._migrated["mod-name"]`.

## Mod structure
- Folder `{name}_{version}` or `{name}`; zip must be named `{name}_{version}.zip`, single folder inside.
- Root files: `info.json` (only mandatory file), `changelog.txt`, `thumbnail.png` (144x144),
  settings*.lua, data*.lua, `control.lua`. Folders: `locale/<lang>/*.cfg`, `scenarios`,
  `campaigns`, `tutorials`, `migrations`.
- Instrument mode extra files: `instrument-settings.lua`, `instrument-data.lua`,
  `instrument-after-data.lua`, `instrument-control.lua` (stdlib2 ships `instrument-after-data.lua`).

### info.json
| field | notes |
|---|---|
| `name` (req) | <=100 chars; portal: 4-49 chars, alnum/`-`/`_` |
| `version` (req) | `"a.b.c"`, each 0-65535 |
| `title` (req) | <=100 chars; overridable by `[mod-name]` locale |
| `author` (req) | |
| `contact`, `homepage`, `description` | optional; description overridable by `[mod-description]` |
| `factorio_version` | `"major.minor"` e.g. `"2.0"` / `"2.1"`; default `"0.12"`; a 3rd number makes the portal reject |
| `dependencies` | default `["base"]`; e.g. `["mod-a", "? mod-c > 0.4.3", "! mod-g"]` |
| `migrates_from` | array of mod names |
| feature flags (bool, default false, need Space Age) | `quality_required`, `rail_bridges_required`, `spoiling_required`, `freezing_required`, `segmented_units_required`, `expansion_shaders_required`, `expansion_required`, `space_travel_required` |

Dependency prefixes: none = required, `!` incompatible (version ignored), `?` optional,
`(?)` hidden optional, `+` recommended, `~` required but does not affect load order.
Operators `< <= = >= >`. An optional dep present with an unmet version disables the mod.

## changelog.txt format
- Each section starts with a line of exactly **99 dashes**, next line must be `Version: a.b.c`
  (0.0.0 invalid, versions unique). Optional `Date: <anything>` once.
- Category: two spaces + name + `:`. Entry: four spaces + `- ` + text; continuation lines six spaces.
- No tabs, no trailing spaces, no duplicate entries within a category.
- Known categories (sorted first): Major Features, Features, Minor Features, Graphics, Sounds,
  Optimizations, Balancing, Combat Balancing, Circuit Network, Changes, Bugfixes, Modding,
  Scripting, Gui, Control, Translation, Debug, Ease of use, Info, Locale, Compatibility.
- Note: stdlib2's current `Date: 2024-00-00` is accepted (any format), but the entry under 2.0.2
  is placeholder text.

## Libraries and functions (Lua 5.2.1 based)
- Added: `serpent` (comments off by default; `refcomment`, `tablecomment` options; can't print
  LuaObjects), `string.pack/packsize/unpack` (from 5.4.6), `log(LocalisedString)`,
  `localised_print(LocalisedString)` (stdout), `table_size(t)` (not for LuaCustomTable; use `#`).
- `pairs`/`next`: deterministic insertion order; first 1024 numeric keys iterate 1..1024.
- `require`: paths from mod root, no `.`/`..`; core `lualib` on path (`require("util")`);
  other mods via `require("__mod-name__.file")`; **not usable from console, event handlers or
  during `remote.call`**.
- `print`: stdout only. Prefer `log` or `game.print`.
- `math.random`: deterministic; constant seed in data stage; at runtime uses the map RNG; not
  usable outside events or during loading; non-integer args floored. `math.randomseed` is a no-op;
  use `game.create_random_generator()` (LuaRandomGenerator).
- `load`: no binary chunks. `debug`: only `getinfo`/`traceback` by default.
- **Removed:** `loadfile`, `dofile`, `coroutine`, `io`, `os`.

## Migrations
- Files in `migrations/`, `.json` or `.lua`; order: mod order, then file name (lexicographic);
  all JSON before any Lua; each applied once per save; all run when the mod is added to a save;
  not run on MP join; temporary Lua env if no control.lua.
- JSON renames prototypes by IDType:
```json
{ "entity": [["wall", "stone-wall"]], "item": [["wall", "stone-wall"]] }
```
  Rename keeps `unit_number` and storage refs; type change gives new unit_number (refs invalid);
  removed prototypes invalidate refs; unmigratable ghosts may be removed.
- Lua migrations have `game`. Recipes/technologies are reset automatically on mod/prototype/
  startup-setting changes.

## Instrument mode
`--instrument-mod modname` (one mod only; disables MP). Loads `instrument-settings.lua` before all
settings, `instrument-data.lua` before all data, `instrument-after-data.lua` after all
data-final-fixes, `instrument-control.lua` before every mod's control.lua. Adds
`LuaGuiElement.actual_size`. Intended for debug tooling / LuaProfiler.

## Prototype inheritance (summary)
`PrototypeBase` -> `Prototype` (most prototypes) and `GuiStyle`. Big branches: `EntityPrototype`
-> `EntityWithHealthPrototype` -> `EntityWithOwnerPrototype` (buildings, vehicles, `character`,
`rocket-silo` under AssemblingMachine), `CombinatorPrototype` (arithmetic/decider/selector),
`RailPrototype` (incl. elevated/half-diagonal/ramp), `EquipmentPrototype`, `ItemPrototype` ('item'
-> ammo, capsule, gun, module, rail-planner, tool -> armor/repair-tool, selection-tool ->
blueprint/copy-paste-tool/deconstruction-item/upgrade-item), plus recipe, technology, quality,
item-group, item-subgroup, fluid, planet, surface, tile, shortcut, procession.

## Machine-readable docs
`https://lua-api.factorio.com/latest/runtime-api.json` and `prototype-api.json`, `api_version` 6
(since 2.0.7). Runtime top-level: `classes, events, concepts, defines, global_objects,
global_functions`; prototype: `prototypes, types, defines`. Attributes use `read_type`/
`write_type`; classes/attributes carry `visibility` (e.g. `"space_age"`). Useful for generating
LuaLS type stubs or for diffing API versions.

## Other auxiliary pages (one-liners)
- Noise expressions: per-tile mapgen language; builtins `x`, `y`, `map_seed`, `basis_noise`,
  `multioctave_noise`, `spot_noise`, voronoi functions; use `var('name-with-dashes')`.
- Item weight: derived from recipes, `default_item_weight`, `ingredient_to_weight_coefficient`
  (default 0.5), `rocket_lift_weight / stack_size`.
- Furnace and circuit recipe selection: deterministic rules by subgroup/order and quality.
