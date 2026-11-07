# Plan 2: Architecture enhancements

Status: ready for implementation, after plan 1 (`01-factorio-2.1-compatibility.md`).
Reference notes: `doc/factorio-2.1/`.

## Goal
Make stdlib2 easier to test and maintain, and safer for the mods that depend on it, without
breaking their public API. Every item here is additive or internal. Anything that changes
behaviour is opt-in or keeps the old behaviour as the default.

## Current architecture (as found)
- `stdlib/core.lua` is the base class every module `__index`es into. Requiring it runs
  `stdlib/utils/globals.lua`, which `rawset`s many names into the caller's `_ENV`
  (`STDLIB`, `inspect`, `traceback`, `data_traceback`, `prequire`, `rawtostring`, `inline_if`,
  `concat`) and mutates `defines` (`defines.color`, `anticolor`, `lightcolor`, `time`).
- Data stage: `stdlib/data/data.lua` wraps a raw prototype in a proxy object
  (`_object_mt`) with a `valid` flag; `Recipe`, `Item`, `Fluid`, `Entity`, `Technology`,
  `Category` subclass it. Stage detection is `if _G.remote and _G.script then error`.
- Control stage: `stdlib/event/event.lua` owns `script.on_event` for every event it registers and
  fans out to a Lua registry with optional Lua filter functions and patterns. Helper modules
  (`player`, `force`, `surface`, `trains`, `changes`, `gui`) keep state in `storage` under
  ad-hoc keys (`players`, `forces`, `surfaces`, `_train_registry`, `_entity_data`,
  `_chunk_data`, `_tile_data`, `_print_queue`, `_changes`).
- Tests use `busted` plus the external `faketorio` package (not in the repo, built for 1.x
  data). CI runs `busted` on push and luacheck only on master.

## Problems this plan addresses
1. Tests cannot run from a fresh clone (missing `faketorio`) and its fixtures are 1.x.
2. No use of native event filters, so every handler for entity events runs Lua filtering for
   every entity in the game.
3. `storage._entity_data` grows forever: entries for destroyed entities are never removed.
4. Stage detection, deprecation logging and storage access are duplicated or ad-hoc.
5. `Core._VERSION` is stale (`1.0.0`) and nothing reports the library version.
6. Dead files (`spec/event/*_bak.lua`) and unused stubs (`stdlib/config.lua` returns `{}`,
   `STDLIB.reload_class` "NOT IMPLEMENTED").

## Work items (in order)

### 1. In-repo test harness (replaces faketorio)
- Add `spec/setup/factorio_env.lua` that provides minimal, deterministic stand-ins:
  - `defines` with `events` (all 227 names from `doc/factorio-2.1/runtime-core.md`, assigned
    sequential ids), `direction` (16 values, north=0 ... northnorthwest=15), `inventory`
    (names from the reference, sequential ids), `wire_connector_id` (`circuit_red`,
    `circuit_green`, ...), `train_state`, `controllers`.
  - `script` stub: records `on_event`, `on_nth_tick`, `on_init`, `on_load`,
    `on_configuration_changed`, `set_event_filter`, `register_on_object_destroyed`;
    `generate_event_name` returns increasing ids; `mod_name = 'stdlib2'`;
    `active_mods = {base = '2.1.0', stdlib2 = '2.1.0'}`.
  - `helpers` stub: `write_file`, `remove_path`, `table_to_json` (via a tiny encoder),
    `stage`.
  - `game` stub factory with `tick`, `players`, `forces`, `surfaces`, `get_player`, `print`,
    `train_manager.get_trains`.
  - `log` and `serpent` globals.
- Add `spec/setup/data_fixtures.lua`: `reset()` builds a small 2.x-format `data.raw`
  (a few items, fluids, recipes with `ingredients`/`results`/`categories`, technologies with
  `unit` and one with `research_trigger`, a lab, an assembling machine, item groups/subgroups,
  recipe categories `crafting`, `smelting`, `hand-held`).
- Make `require('__stdlib2__/stdlib/...')` resolve in tests with a `package.searchers` entry
  that maps `__stdlib2__/` to the repo root (and `package.remove_stdlib()` to clear
  `package.loaded` of stdlib modules between tests, as specs already expect).
- Replace `spec/setup/busted.lua`'s `require('faketorio')` with the new setup. Migrate all specs
  off `faketorio/dataloader` to `data_fixtures.reset()`.
- Add `.busted` config so plain `busted` from the repo root works.
- Delete `spec/event/force_bak.lua` and `spec/event/player_bak.lua`.
- CI: run luacheck on push and pull_request for all branches (match the busted workflow), and
  pin the `.luacheckrc` URL to a commit instead of `master`.
- Acceptance: `busted` passes from a fresh clone with only `busted` installed.

### 2. Shared utilities
- `stdlib/utils/stage.lua`: `Stage.current()` returns `'settings' | 'data' | 'control'`, using
  `helpers.stage` when present (`'prototype'` maps to `'data'`, `'runtime'` to `'control'`), and
  falling back to today's checks. `Stage.assert(expected, module_name)` raises
  `"<module> can only be required in the <expected> stage"`. Use it in `stdlib/data/data.lua`
  and at the top of `stdlib/event/event.lua`.
- `stdlib/utils/deprecate.lua`: `Deprecate.warn(key, message)` logs `stdlib2: DEPRECATED: ...`
  once per key per Lua state. Plan 1's deprecation notices must use it.
- `stdlib/utils/storage.lua`: a documented accessor, `Storage.get(key, default_factory)` and
  `Storage.KEYS` listing every key stdlib2 uses in `storage` (the list above). Do not rename any
  key (save compatibility). Refactor `Game.get_or_set_data`, `Entity.get_data/set_data`,
  `Trains`, `Player`, `Force`, `Surface`, `Changes` to go through it. Writes from `on_load` must
  error with a clear message (check `Stage`/a flag set by Event's on_load dispatch).

### 3. Native event filters in `Event`
- Extend `Event.register(event_id, handler, filter, pattern, options)` so `options.event_filter`
  may hold a native `EventFilter` array (see `doc/factorio-2.1/runtime-core.md`).
- Rule: for an event id, if **every** registered handler supplies `options.event_filter`, call
  `script.set_event_filter(id, union_of_all_filters)` (filters in one array are OR-ed, so the
  union is correct). If any handler has no native filter, call `script.set_event_filter(id, nil)`.
  Recompute on every register/remove. Lua `filter`/`pattern` still run afterwards, so each
  handler only sees events that match its own native filter: store the native filter per
  handler and check it in Lua only when the union is wider than the handler's filter (implement
  a small matcher for the common keys `name`, `type`, `ghost`, `ghost_name`, `ghost_type`,
  `invert`, `mode`; for unknown keys, skip the Lua re-check and document that).
- Only events that support filters (the 30 `Lua*EventFilter` events) may take
  `event_filter`; others raise an error at registration.
- Provide `Event.Filters.native` helpers, e.g. `Event.Filters.native.name('iron-chest')` ->
  `{{filter = 'name', name = 'iron-chest'}}`, `.type(...)`, `.ghost()`.
- Desync safety: registration must be deterministic and repeated in `on_load`; document that
  `event_filter` must be passed identically on every load (same rule as `script.on_event`).
- Acceptance: specs show `set_event_filter` calls for: one filtered handler; two filtered
  handlers (union); one filtered + one unfiltered (nil); removal of the unfiltered handler
  restores the union.

### 4. Entity data cleanup
- `Entity.set_data(entity, data)`: when storing data for an entity with a `unit_number`, call
  `script.register_on_object_destroyed(entity)` and remember the returned registration number
  in `storage._entity_data_reg[reg_number] = unit_number`.
- Register (through `Event`) a handler for `defines.events.on_object_destroyed` that removes
  `storage._entity_data[unit_number]` and the reg entry. Make it opt-out via
  `Entity.options.auto_cleanup = true` (default true) and register it lazily the first time
  `set_data` is called **and** in `on_load` when `storage._entity_data_reg` is non-empty, so
  registration stays identical between host and joining clients.
- For entities without `unit_number` (current name-keyed list), prune invalid entries on every
  `get_data`/`set_data` (today only `set_data` prunes).
- Migration: in `on_configuration_changed`, walk existing unit_number-keyed `_entity_data`
  entries. For each, try `game.get_entity_by_unit_number(n)`; if it returns a valid entity,
  register it for destruction. Otherwise keep the entry untouched (that lookup only works for
  some prototypes, so a nil result does not prove the entity is gone).

### 5. Version reporting
- `Core._VERSION` read from `script.active_mods['stdlib2']` at control stage and
  `mods['stdlib2']` at data/settings stage, falling back to a constant kept in sync with
  `info.json` (add a spec that parses `info.json` and compares).
- Add `Core.require_version(min_version)` using `helpers.compare_versions` that errors with a
  clear message if the loaded stdlib2 is older.

### 6. Quality-aware helpers (additive)
- `Inventory.get_contents_by_name(inventory)` -> `{[name] = total_count}` summing all qualities
  (common 1.x usage pattern); `Inventory.get_contents_by_quality(inventory)` ->
  `{[name] = {[quality] = count}}`.
- `Data` helpers for recipes: `Recipe:allow_quality(bool)`, `Recipe:set_can_set_quality(bool)`
  writing the 2.x fields only (no Space Age requirement; fields are inert without quality).

### 7. Globals hygiene (opt-in)
- Add `config.no_globals` in `stdlib/config.lua` (documented: set
  `require('__stdlib2__/stdlib/config').no_globals = true` before requiring other modules).
  When true, `globals.lua` does not `rawset` `inspect`, `traceback`, `prequire`, `rawtostring`,
  `inline_if`, `concat`, `STDLIB` into `_ENV`; modules use local requires instead. Default
  stays false. All stdlib modules must stop reading these via `_ENV.x` and use local requires so
  that `no_globals` works.
- The `defines` mutations (`color`, `anticolor`, `lightcolor`, `time`) are skipped when
  `no_globals` is true; expose them as `require('__stdlib2__/stdlib/utils/defines/color')`
  return values instead.
- Remove `STDLIB.reload_class` (no-op) only if nothing references it; otherwise leave it with a
  `Deprecate.warn`.

### 8. Documentation
- `readme.md`: state Factorio 2.1 support, list breaking/deprecated behaviour from plan 1
  (normal/expensive ignored, `make_difficult` no-op, train ids now `LuaTrain.id`,
  `created_entity` alias deprecated), and document the new options (`event_filter`,
  `auto_cleanup`, `no_globals`).
- Each new module gets LDoc headers consistent with existing ones (`doc/config.ld`).

## Out of scope
- Splitting the mod into multiple mods, renaming modules, or changing require paths.
- Rewriting vendor libraries.
- GUI framework changes.

## Acceptance criteria
- All items above have specs; `busted` passes from a fresh clone.
- No public function was removed or renamed; only additions and deprecations.
- No new `storage` key renames; any new keys are listed in `Storage.KEYS`.
- luacheck passes with the pinned Factorio `.luacheckrc`.
