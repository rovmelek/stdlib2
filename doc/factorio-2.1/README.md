# Factorio 2.1 modding reference (for the stdlib2 port)

Condensed notes from the official docs, read on 2026-11-07 when
https://lua-api.factorio.com/latest/ was **version 2.1.24**. Sources were
https://wiki.factorio.com/Tutorial:Mod_settings, https://lua-api.factorio.com/latest/index-prototype.html
and https://lua-api.factorio.com/latest/index-runtime.html, plus pages linked from them.

| file | covers |
|---|---|
| [wiki-modding.md](wiki-modding.md) | mod settings (types, setting_type, reading/writing, locale), localisation, wiki modding tutorial |
| [auxiliary.md](auxiliary.md) | data lifecycle, storage, mod structure and info.json, changelog format, Lua library changes, migrations, instrument mode, JSON docs |
| [runtime-core.md](runtime-core.md) | `script`, `game`, `helpers`, `rendering`, `remote`, `settings`, `prototypes`, `commands`, defines, events, EventFilter, LocalisedString, and an audit of the calls stdlib2 makes |
| [runtime-classes.md](runtime-classes.md) | LuaEntity, LuaControl, LuaPlayer, LuaSurface, LuaForce, LuaInventory, LuaItemStack, LuaTrain, LuaTrainManager, LuaGuiElement, LuaTile, position/area/filter concepts |
| [prototype.md](prototype.md) | data stage: data.raw, item, recipe, technology, fluid, entity, groups, icons, sprites, pipe connections, type-name list |

## How complete this is
- The docs site cannot be reached from the cloud sandbox with curl, so pages were read with a
  web fetcher that returns about 40k characters of each page verbatim and summarises the rest.
  Long class pages (LuaEntity, LuaSurface, LuaForce, RecipePrototype, EntityPrototype, defines)
  are partly summary. Those parts are marked *[unverified]* or `[S]`.
- "Five levels of links" over these indexes is thousands of pages (every class, concept, type
  and prototype). The notes cover the pages a library like stdlib2 touches, not every page.
- The site marks members **new** / **changed** but has no 2.0 -> 2.1 changelog page, so the
  badges are the best available signal of what changed.
- Not captured: numeric values of `defines.direction`, members of `defines.train_state`, the
  setting prototype pages (they 404 under `prototypes/`), `wiki Tutorial:Migrations` (fetch
  error), per-filter fields of EventFilter, ItemIngredientPrototype/FluidIngredientPrototype.
- For exhaustive, machine-checkable data use
  https://lua-api.factorio.com/latest/runtime-api.json and `prototype-api.json` (format in
  `auxiliary.md`), fetched from a machine with normal internet access.

## Port issues spotted while reading (not yet fixed)
1. `game.write_file`, `game.table_to_json`, `game.remove_path` are gone from LuaGameScript; use
   `helpers.*` (stdlib2 still calls the `game.` versions about 30 times across `stdlib/event`, `stdlib/game.lua`, `stdlib/scripts/interface.lua`).
2. `game.pollution_statistics` -> `game.get_pollution_statistics(surface)`.
3. `stdlib/data/recipe.lua` still models `normal`/`expensive` difficulty and `result`/`result_count`;
   2.x recipes only have `ingredients`/`results`.
4. Recipe `categories` (array) and item `fuel_categories` (array) are new in 2.1; stdlib2 uses
   singular `category`. Check whether the singular form is still accepted.
5. `rendering.draw_*` return LuaRenderObject; stdlib2 has no id-based `rendering.*` calls, but callers keeping the return value get an object now.
6. `rail-category` is listed in `stdlib/data/modules/groups.lua` but is not a prototype type.
7. `info.json` `factorio_version` must become `"2.1"` and `dependencies` `base >= 2.1.0` when targeting 2.1.
8. `changelog.txt` 2.0.2 entry is placeholder text.
