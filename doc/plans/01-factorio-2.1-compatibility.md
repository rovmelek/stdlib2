# Plan 1: Factorio 2.1 compatibility

Status: ready for implementation. Target: Factorio 2.1 (API docs 2.1.24).
Reference notes: `doc/factorio-2.1/` (read `README.md` first).
Companion plan: `02-architecture-enhancements.md`. Implement this plan first; plan 2 builds on it.

## Goal
stdlib2 loads in Factorio 2.1, every public function uses only APIs that exist in 2.1, and the
data-stage helpers produce prototypes in the 2.x format. Public function names and signatures
stay the same unless this plan says otherwise. Where a parameter loses meaning (for example
`expensive`), it is accepted and ignored with a one-time `log()` deprecation notice, so
dependent mods keep loading.

## Non-goals
- No new features beyond what is needed for 2.1 (those belong to plan 2).
- No changes under `stdlib/vendor/`.
- No Space Age dependency. Nothing may require `quality_required` or other feature flags.

## Facts this plan relies on (verified on lua-api.factorio.com 2.1.24)
- `game.write_file`, `game.table_to_json`, `game.remove_path` do not exist; use `helpers.write_file`,
  `helpers.table_to_json`, `helpers.remove_path`. `helpers` exists in every stage.
- `game.pollution_statistics` does not exist; use `game.get_pollution_statistics(surface)`.
- `LuaForce.item_production_statistics` etc. are gone; use
  `force.get_item_production_statistics(surface)`, `get_fluid_production_statistics(surface)`,
  `get_kill_count_statistics(surface)`, `get_entity_build_count_statistics(surface)`.
- `LuaSurface.get_trains` is gone; use `game.train_manager.get_trains{surface=?, force=?}`
  (TrainFilter fields: train_id, surface, force, stock, min_stocks, max_stocks, is_moving,
  has_passenger, is_manual, group). `LuaTrain.id` is a stable uint32.
- `LuaEntity.circuit_connected_entities` is gone; use `entity.get_circuit_network(defines.wire_connector_id.circuit_red | circuit_green)`
  (returns LuaCircuitNetwork or nil) or `entity.get_wire_connectors(false)`.
- `RecipePrototype.category` is gone; `categories :: array[RecipeCategoryID]` (default `{"crafting"}`).
  Runtime `LuaRecipe(Prototype).categories` and `has_category(name)`.
- `ItemPrototype.fuel_category` is gone; `fuel_categories :: array[FuelCategoryID]`
  (mandatory, at least one, when `fuel_value` is nonzero).
- Recipes have no `normal`/`expensive`, no `result`/`result_count`; only `ingredients` and
  `results` arrays of `{type="item"|"fluid", name=..., amount=...}`.
- Technologies have either `unit` or `research_trigger`; `unit` may be nil.
- `LuaInventory.get_contents()` returns `array[{name, quality, count}]`.
- `defines.direction` has 16 values (north=0, east=4, south=8, west=12).
- `rail-category`, `noise-layer` are not prototype types in 2.x.
- Event payloads: build events use `entity` (not `created_entity`).

## Work items

### A. Mod metadata
1. `info.json`: `"version": "2.1.0"`, `"factorio_version": "2.1"`, `"dependencies": ["base >= 2.1.0"]`,
   update `description` and `title` ("Factorio Standard Library 2.1"). Keep `package.ignore`.
2. `changelog.txt`: replace the placeholder 2.0.2 section with a `Version: 2.1.0` section listing
   the changes made under this plan (follow the format in `doc/factorio-2.1/auxiliary.md`:
   99 dashes, two-space categories, four-space `- ` entries, no tabs or trailing spaces).

### B. Runtime API renames
3. `stdlib/game.lua`
   - `write_mods`, `write_surfaces`: `game.write_file` -> `helpers.write_file`, `game.remove_path` -> `helpers.remove_path`.
   - `write_statistics`: iterate `game.surfaces` as well as forces; for each force+surface write
     `get_item_production_statistics`, `get_fluid_production_statistics`,
     `get_kill_count_statistics`, `get_entity_build_count_statistics`, and per surface
     `game.get_pollution_statistics(surface)`. Each LuaFlowStatistics has `input_counts` and
     `output_counts`. Output path `Statistics/<tick>/<surface>/<force>/<kind>-<count_type>.json`
     (pollution under `Statistics/<tick>/<surface>/pollution-<count_type>.json`). Use
     `helpers.table_to_json`.
4. Replace every remaining `game.write_file` / `game.remove_path` / `game.table_to_json` in
   `stdlib/event/changes.lua`, `stdlib/event/player.lua`, `stdlib/event/force.lua`,
   `stdlib/event/surface.lua`, `stdlib/event/modules/dump_event_data.lua`,
   `stdlib/scripts/interface.lua` with the `helpers.*` equivalents.
5. `stdlib/scripts/interface.lua` `write_global`: it reads the 1.x `global` table. Read `storage`
   instead and write to `<mod>/storage.lua`; keep the remote function name `write_global` and add
   an alias `write_storage`.
6. `spec/misc/logger_spec.lua` stubs `game.write_file`; logger already uses `helpers.write_file`.
   Update the spec to stub `_G.helpers = { write_file = ... }` and spy on that.

### C. Trains
7. `stdlib/event/trains.lua`
   - `Trains.find_filtered(criteria)`: build a `TrainFilter` from `criteria.surface` (each
     surface from `Surface.lookup`, or all when nil) and `criteria.force`, call
     `game.train_manager.get_trains(filter)`, then apply the `state` filter as today.
   - Train identity: switch from "unit_number of main locomotive" to `train.id`.
     `Trains.get_train_id(train)` returns `train.id`. `storage._train_registry` is keyed by
     `train.id`. Keep `Trains.on_train_id_changed` and `_on_locomotive_changed`, but drive
     renames from `defines.events.on_train_created` (`event.old_train_id_1`,
     `event.old_train_id_2`, `event.train`): for each old id present in the registry, remove it
     and dispatch `on_train_id_changed{old_id, new_id = event.train.id}`.
   - `Trains.to_entity` uses `'train-' .. train.id`.
   - Registry entries must not be stale: on `create_train_registry` drop entries whose train is
     invalid.
   - One-time migration in `create_train_registry` (runs on init and configuration change):
     rebuild the registry from scratch with the new keys.

### D. Entities and inventories
8. `stdlib/entity/entity.lua`
   - `is_circuit_connected(entity)`: true if `entity.get_circuit_network(defines.wire_connector_id.circuit_red)`
     or `..._green` returns a network with at least one other connected entity
     (`network.connected_circuit_count > 1` if present; otherwise just non-nil). Guard with
     `pcall` or a type check because not every entity has circuit connectors.
   - `count_circuit_connections(entity)`: use `entity.get_wire_connectors(false)`; sum
     `connector.connection_count` over the red and green circuit connectors.
   - `find_resources`: use `entity.prototype.get_mining_drill_radius(entity.quality)` when
     available, else `mining_drill_radius`.
   - `set_frozen`/`set_indestructible`: unchanged (attributes still exist), but add a guard so
     non-entity inputs raise a clear error.
9. `stdlib/entity/inventory.lua`
   - `copy_as_simple_stacks`: include `quality = stack.quality.name` and, when the item can
     spoil, `spoil_percent = stack.spoil_percent`. Keep `health`, `durability`, `ammo`.
   - `swap_inventory`: fix `source[1]` -> `source[i]` (existing bug).
   - `transfer_inventory`: unchanged API; verify `supports_filters`, `is_filtered`, `get_filter`,
     `set_filter` against `doc/factorio-2.1/runtime-classes.md` and adjust if names changed.
   - `get_blueprint`: unchanged.

### E. Directions and orientations
10. `stdlib/area/orientation.lua` `to_direction` is wrong for the 16-value defines (4-way east
    returns south). Correct formula:
    `4-way: floor(o * 4 + 0.5) % 4 * 4`; `8-way: floor(o * 8 + 0.5) % 8 * 2`.
    Add an optional third mode `sixteen_way` (`floor(o * 16 + 0.5) % 16`). Fix
    `spec/area/direction_spec.lua` / add `spec/area/orientation_spec.lua` cases for all 4 and 8
    cardinal/diagonal directions.
11. `stdlib/area/direction.lua`: already 16-based. Add the 8 secondary directions
    (`northnortheast` ... `northnorthwest`) as fields, extend `to_vector` to handle them
    (unit vector scaled by `distance`, use `{x = sin, y = -cos}` of orientation, rounded to 1e-6),
    and add `Direction.next(direction, mode)` where `mode` may be `true` (8-way, today's
    behaviour), `'16'` (step 1) or nil (4-way). Existing boolean behaviour must not change.

### F. Events
12. `stdlib/event/event.lua`
    - Remove `created_entity` aliasing for new code paths but keep backward compatibility: for
      `script_raised_revive`, `script_raised_built`, `on_entity_cloned`, `on_built_entity`,
      `on_robot_built_entity`, `on_space_platform_built_entity` set
      `event.created_entity = event.entity or event.destination` only when
      `Event.options.legacy_created_entity` is true (default true in this release, documented
      as deprecated). Always ensure `event.entity` is set (`event.entity or event.destination`).
    - Bug: `Event.register` with a table of ids drops `filter`, `pattern`, `options`
      (`Event.register(id, handler)`). Pass all arguments through. Same for `Event.remove`.
13. `stdlib/event/modules/event_filters.lua`: read `event.entity` first, then
    `event.created_entity`, then `event.destination`; return nil (not error) when there is no
    valid entity.
14. `stdlib/event/trains.lua` `register_events`: `on_pre_player_mined_item` and
    `on_robot_pre_mined` are still valid 2.1 events; keep them. Remove the locomotive-change
    listeners if C. makes them redundant (renames now come from `on_train_created`).
15. Audit every `defines.events.*` reference in `stdlib/` against the event list in
    `doc/factorio-2.1/runtime-core.md`. Any name not present must be removed or replaced.
    (`on_entity_destroyed` -> `on_object_destroyed`, `register_on_entity_destroyed` ->
    `register_on_object_destroyed`.)

### G. Data stage helpers
16. `stdlib/data/recipe.lua`: rewrite to the 2.x recipe model.
    - Remove all `self.normal` / `self.expensive` branches. Methods that took
      `(normal, expensive)` keep the signature; if `expensive` is non-nil, log once
      (`log('stdlib2: expensive recipes do not exist in 2.x; argument ignored')`) and ignore it.
    - `make_difficult`: becomes a no-op that logs the deprecation once and returns `self`.
    - `convert_results`: converts legacy `result`/`result_count` (and legacy `normal`/`expensive`
      if a third-party mod left them) into `results`; ingredients in short form `{name, count}`
      become `{type="item", name=, amount=}`. Keep the function, it is the migration helper.
    - `format()`: always returns `{type, name, amount}` (or `amount_min`/`amount_max`, with
      optional `probability`). Fix the probability check: `amount` OR (`amount_min` AND
      `amount_max`) is required; `probability` is optional.
    - `remove_ingredient` / `remove_result`: accept a string or formatted table; compare names,
      not `name.name` on strings. Remove all matches by iterating backwards.
    - `add_result`: create `self.results = {}` when missing.
    - `change_category(name)`: sets `self.categories = { name }` and clears legacy `category`.
      Add `add_category(name)`, `remove_category(name)`, `has_category(name)` that operate on
      `categories` (treat nil as `{'crafting'}`). Validate the category exists in
      `data.raw['recipe-category']`.
    - `set_enabled`: just `self.enabled = enabled`.
17. `stdlib/data/technology.lua`
    - `add_effect`: create `effects` when nil. Support non-recipe effects:
      `add_effect(effect_table)` where `effect_table.type ~= 'unlock-recipe'` is appended as is.
    - `remove_effect` for a technology (currently a TODO): remove effects matching
      `unlock_type` (default `unlock-recipe`) and `name` (matches `effect.recipe` for
      unlock-recipe, otherwise `effect.item`/`effect.space_location`/`effect.quality` as
      applicable). Iterate backwards so multiple matches are removed.
    - `add_pack` / `remove_pack` / `replace_pack`: if `self.unit` is nil (technology uses
      `research_trigger`), log and return self unchanged. Accept both `{name, count}` and
      `{type?, name=, amount=}` ingredient shapes when reading.
    - Add `set_research_trigger(trigger)` (sets `research_trigger`, clears `unit`) and
      `set_unit(unit)` (sets `unit`, clears `research_trigger`).
18. `stdlib/data/item.lua`: add `Item:set_fuel(value, categories, burnt_result?)` that writes
    `fuel_value` and `fuel_categories` (string becomes `{string}`), and
    `Item:add_fuel_category(name)`. If a legacy `fuel_category` field exists, move it into
    `fuel_categories`.
19. `stdlib/data/category.lua` and `stdlib/data/modules/groups.lua`: remove `rail-category` and
    `noise-layer`; cross-check every type string in `groups.lua` against the type list in
    `doc/factorio-2.1/prototype.md` and remove any that are not 2.1 prototype types
    (e.g. `combat-robot-count`, `market` in the wrong group). Add new 2.x types that belong in
    each group (e.g. `quality`, `surface`, `planet`, `space-location`, `space-connection`,
    `asteroid-chunk`, `airborne-pollutant`, `burner-usage`, `collision-layer`, `procession`,
    `mod-data`; equipment `inventory-bonus-equipment`, `electric-energy-interface-equipment`,
    `equipment-ghost`; item subtypes `space-platform-starter-pack`, `spidertron-remote`).
    `Category:replace` calls `self:valid`, which does not exist; use `self:is_valid()`.
20. `stdlib/data/data.lua`
    - `Data:copy`: guard `copy.results` being nil; handle `minable.results` arrays as well as
      `minable.result`.
    - `Data:set_icon_at`: bug `self.icons[index].k = v` -> `self.icons[index][k] = v`.
    - `Data:replace_icon`: the `icon_size` error must only fire for valid objects; default
      `icon_size` to 64 (the 2.x default) instead of erroring.
    - `Data:make_icons`: default `icon_size` to 64 when absent.
    - `Data:any_flag` uses `:all`; should be `:any`.
21. `stdlib/data/modules/util.lua` `Util.duplicate`: also rewrite `minable.results[*].name`
    when `mining_result` is set and the result matched the original; drop the `proto.result`
    branch for recipes and rename `results[1].name` only when there is exactly one result
    (same rule as `Data:copy`).
22. `stdlib/data/entity.lua` `get_minable_item`: `Item` is referenced outside the scope where it
    is required; hoist the require. Prefer `minable.results[1].name` then `minable.result`.
23. `stdlib/data/modules/pipes.lua` and `sprites.lua`: check base-game graphic paths and sizes
    used by `Pipes.pictures` / `Pipes.covers` against Factorio 2.x (`__base__/graphics/entity/...`
    paths and that 2.x ships only the former HR sprites with `scale = 0.5`). Update widths,
    heights and add `scale = 0.5` where the HR files are now the only ones. If a path cannot be
    verified without the game files, leave it and add a `-- TODO(2.1): verify` comment and list
    it in the PR description.

### H. Globals and core
24. `stdlib/utils/globals.lua` `STDLIB.install_global_utils` calls `STDLIB.install.math()`;
    should be `STDLIB.install_math()` etc. (existing bug).
25. `stdlib/core.lua` `log_and_print`: unchanged API; uses `game.print`. Fine.

### I. Specs
26. Every behaviour change above gets a spec under `spec/` mirroring the module path. Specs that
    test removed behaviour (`make_difficult`, normal/expensive) are rewritten to assert the new
    no-op/deprecation behaviour.
27. Tests currently depend on the external `faketorio` package (1.x data). Plan 2, item 1
    replaces it with an in-repo harness. Until then, new specs for this plan must not require
    `faketorio/dataloader`; build the minimal `data.raw` fixtures inline (see plan 2 for the
    fixture helper) so they can run with plain `busted`.

## Acceptance criteria
- `grep -rnE "game\.(write_file|table_to_json|remove_path|pollution_statistics)|circuit_connected_entities|get_trains\(|\.normal\b|\.expensive\b|result_count|rail-category|noise-layer|\bglobal\b\." stdlib`
  returns nothing except comments and the legacy-conversion code in `Recipe:convert_results`.
- `info.json` targets 2.1.
- `busted` passes for all specs that do not need `faketorio` (and all specs once plan 2 item 1 lands).
- `luacheck stdlib` (using the Factorio luacheckrc referenced in `.github/workflows/luacheck.yml`) reports no new warnings.
- Changelog has a 2.1.0 section in valid format.
- Each `TODO(2.1): verify` left in the code is listed in the PR description.

## Manual in-game verification (for the human, after merge)
Load Factorio 2.1 with stdlib2 plus a small test mod that: calls `Game.write_statistics()`;
registers `Event.register(defines.events.on_built_entity, ...)` with a name filter; uses
`Recipe('iron-gear-wheel'):add_ingredient('copper-plate')` and `:change_category('crafting')` in
data stage; `Technology('automation'):add_pack('logistic-science-pack')`;
`Trains.find_filtered{}` with one train placed. No errors on load or in `factorio-current.log`.
