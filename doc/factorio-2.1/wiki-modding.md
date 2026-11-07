# Wiki: mod settings, localisation, modding tutorial

Condensed from wiki.factorio.com (read 2026-11-07). Pages read:
Tutorial:Mod_settings, Tutorial:Localisation, Tutorial:Modding_tutorial/Gangsir,
Tutorial:Mod_structure and Tutorial:Mod_changelog_format (both now stubs pointing to
lua-api auxiliary pages, see `auxiliary.md`). Tutorial:Migrations could not be fetched.
No wiki page read mentions 2.1 specifically; the tutorial is "updated for 2.0".

## Mod settings

### Stages and files
- Defined in the settings stage: `settings.lua`, then `settings-updates.lua`, then
  `settings-final-fixes.lua`. Each pass runs for all mods (dependency order, then natural sort)
  before the next pass starts.
- Settings stage runs before data. No prototypes, no remote, no user setting values. Settings
  cannot be created conditionally on other settings' values. `mods["name"]` detects mods.
- Other mods' settings can be modified in the updates/final-fixes passes via
  `data.raw["string-setting"]["name"]` etc.
- Player-local values are stored in `mod-settings.dat` in the user mods folder.

### Common properties
| property | type | notes |
|---|---|---|
| `name` | string, required | prefix with mod name (settings are global across mods) |
| `type` | string, required | `bool-setting`, `int-setting`, `double-setting`, `string-setting`, `color-setting` |
| `setting_type` | string, required | `startup`, `runtime-global`, `runtime-per-user` |
| `localised_name`, `localised_description` | LocalisedString, optional | |
| `order` | string, optional | sort: mod, then order, then name |
| `hidden` | bool, optional | hidden from GUI, still readable |

### Per-type properties
- **bool-setting**: `default_value` (bool, req), `forced_value` (bool, only used when `hidden = true`).
- **int-setting** (int64): `default_value` (req), `minimum_value`, `maximum_value`,
  `allowed_values` (array -> dropdown; a single value forces it).
- **double-setting**: same as int with doubles.
- **string-setting**: `default_value` (req), `allow_blank` (default false), `auto_trim`
  (default false), `allowed_values` (dropdown, localisable).
- **color-setting**: `default_value` (Color, req), `forced_value` (Color, only when hidden).

Lock a value: hidden + single-element `allowed_values` (+ `forced_value` for bool/color).
```lua
data.raw["string-setting"]["my-mod-always-difficult"].hidden = true
data.raw["string-setting"]["my-mod-always-difficult"].allowed_values = {"no"}
data.raw["string-setting"]["my-mod-always-difficult"].default_value = "no"
```

### setting_type
- `startup`: readable in settings (later passes) and data stages via `settings.startup`; fixed at
  runtime; must match on all MP clients. (Also readable at runtime via `settings.startup`.)
- `runtime-global`: per save, changeable at runtime (admins only on servers); `settings.global`; Map tab.
- `runtime-per-user`: control stage only; `settings.get_player_settings(player)` or
  `player.mod_settings`.

### Reading and writing
Always use `.value`. Dropdown strings return the raw defined string, not the localised label.
```lua
-- data stage
data.raw.item["stone-wall"].stack_size = settings.startup["my-mod-stone-wall-stack-size"].value
-- control stage
settings.global["my-mod-always-difficult"].value
settings.get_player_settings(event.player_index)["my-mod-kill-player"].value
game.players[i].mod_settings["setting-name"].value
-- write own runtime setting
settings.global["my-mod-always-difficult"] = {value = "yes"}
```
Tips: never `require` conditionally on a setting (breaks MP CRC); cache the settings table inside
the event; for values cached outside events, refresh on `on_runtime_mod_setting_changed`.

### Locale for settings (`locale/en/locale.cfg`)
```ini
[mod-setting-name]
my-mod-setting=Name
[mod-setting-description]
my-mod-setting=Description
[string-mod-setting]
# <setting-name>-<dropdown-item>=label
my-mod-setting-item-1=Item 1
[string-mod-setting-description]
my-mod-setting-item-1=Item 1 tooltip
```

## Localisation
- Files: `__mod__/locale/<lang>/<any>.cfg`, many per language allowed; always ship `en` (fallback).
- `[category]` headers, `key=value`; `#` or `;` comments; whitespace around `=` is significant.
- Lookup `{"category.key", params...}`; params `__1__`, `__2__`.
- Tokens: `__CONTROL__name__`, `__ITEM__name__`, `__ENTITY__name__`, `__FLUID__name__`,
  `__PLANET__name__`, `__TILE__name__`, `__CONTROL_MOVE__`, `__ALT_CONTROL__n__name__`,
  `__REMARK_COLOR_BEGIN__`/`__REMARK_COLOR_END__`.
- Plurals: `__plural_for_parameter__1__{1=day|rest=days}__`.
- Concatenate with empty key: `{"", {"item-name.iron-plate"}, ": ", 60}`.
- **Data stage: every LocalisedString parameter must be a string** (use `tostring`).
- Defaults when `localised_name` absent: `{"<base-type>-name.<name>"}`; items fall back via
  `place_result` / `placed_as_equipment_result`; recipes via `main_product`; technologies strip a
  trailing `-<number>`.
- Language codes include `en de fr ja zh-CN zh-TW pt-BR pt-PT es-ES sv-SE fy-NL ga-IE fil`.

## Modding tutorial (Gangsir, 2.0)
- Stage order: settings (3 passes) -> data (`data.lua`, `data-updates.lua`, `data-final-fixes.lua`,
  each across all mods) -> migrations -> runtime (`control.lua`, one Lua state per mod).
- Create prototypes early (data.lua) so other mods' data-updates can see them.
- `~` dependency = does not affect load order. Full prefix syntax: see `auxiliary.md`.
- info.json example: `"factorio_version": "2.0"`, `"dependencies": ["base >= 2.0"]`; folder name
  must equal `name`; zip as `name_version.zip`.
- `data.raw` is not available at runtime; use `prototypes.*`.
- Determinism: game-affecting state goes in `storage`; never subscribe to events conditionally;
  `on_load` only re-registers conditional handlers, restores metatables, makes local refs to
  `storage`. LuaObjects compare with `==` but should not be table keys (use `unit_number`).
- Migrations: avoid renaming prototypes; migration name lists are static.
