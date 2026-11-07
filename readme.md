# Factorio-Stdlib

Factorio Standard Library Project

## About

The Factorio Standard Library is a project to bring Factorio modders high-quality, commonly-required utilities and tools that developers have been often copying around, remixing, and rewriting poor quality copies of. Factorio mods often re-implement basic tools like logging, math calculations, and position or area manipulation. These common operations can be a subtle source of errors and their regular occurance has encouraged the creation of the Factorio Stdlib, as a toolbox and set of utilities for modders. Factorio Standard Library APIs are all unit-tested, documented, and high quality, and written to be simple and straightforward for the earliest beginners and seasoned developers alike.

## Usage

1. Install the Factorio Standard Library  mod from the mod portal [latest release](https://mods.factorio.com/mod/stdlib)
2. In your `info.json` add `stdlib` as a dependency.
3. In your `control.lua` or other lua modules, [you can import the stdlib modules you need](https://github.com/Afforess/Factorio-Stdlib/wiki/Home#adding-factorio-stdlib-to-your-mod).

## Factorio version

This version (2.1.x) supports **Factorio 2.1**. It needs `base >= 2.1.0`. Use an earlier stdlib2 release for Factorio 2.0.

### Breaking and deprecated behaviour since 2.0.x

- Recipes have no `normal` and `expensive` versions in Factorio 2.x. Functions of `Data.Recipe` that take an
  `expensive` argument still accept it, ignore it and log a notice once. `Recipe:make_difficult()` does nothing.
- Train ids are `LuaTrain.id` (they used to be the unit number of the main locomotive). Ids change when Factorio
  creates new trains; `Trains.on_train_id_changed` reports the renames. Data stored with `Trains.set_data` is keyed by
  the id.
- Build events carry `event.entity`. The 1.x field `event.created_entity` is still added but deprecated, switch it off
  with `Event.options.legacy_created_entity = false`.
- `game.write_file`, `game.table_to_json` and `game.remove_path` are `helpers.*`. The remote interface function
  `write_global` is now `write_storage`, `write_global` stays as an alias.
- `Orientation.to_direction` and the `Direction` functions use the 16 value `defines.direction`.
- `Recipe:change_category` sets `categories`; use `add_category` and `remove_category` for more than one category.

### Options

- **Native event filters.** `Event.register(id, handler, filter, pattern, { event_filter = ... })` takes a native
  `EventFilter` array for events that support filters; `Event.Filters.native.name('iron-chest')` builds one. When every
  handler of an event has a native filter, the union is passed to `script.set_event_filter`, otherwise the event is not
  filtered natively. Handlers only see events that match their own filter. Pass the same `event_filter` on every load.
- **Entity data cleanup.** `Entity.options.auto_cleanup` (default `true`) removes `Entity.set_data` data when the entity
  is destroyed. **Require the `Event` module in the main chunk of `control.lua` before the `Entity` module**: the `on_load` restore and the `on_configuration_changed` migration are only hooked when `Event` is already loaded, and `require` is not allowed once the game runs, so the cleanup stays off (with a log message) otherwise.
- **No globals.** Set `require('__stdlib2__/stdlib/config').no_globals = true` before requiring other stdlib2 modules to
  stop stdlib2 from adding `inspect`, `traceback`, `data_traceback`, `prequire`, `rawtostring`, `inline_if`, `concat`
  and `STDLIB` to the global environment and `color`, `anticolor`, `lightcolor` and `time` to `defines`. Get them from
  `require('__stdlib2__/stdlib/utils/globals')` and `require('__stdlib2__/stdlib/utils/defines/color')` instead.
- **Version.** `Core._VERSION` is the loaded version, `Core.require_version('2.1.0')` raises an error when an older
  stdlib2 is loaded.

## Documentation

See [the wiki](https://github.com/Afforess/Factorio-Stdlib/wiki) for an introduction and usage/examples.

See the [github pages](http://afforess.github.io/Factorio-Stdlib/) for the latest generated documentation of the Factorio-stdlib

## Unit Tests

The codebase is tested with [`busted`](http://olivinelabs.com/busted). Test specifications are located under `spec/`.
Run `busted` from the root of the repository, nothing else is needed: `spec/setup/factorio_env.lua` and
`spec/setup/data_fixtures.lua` stand in for the game.

## Contributing

Contributions are welcome! Please follow general lua coding standards and include ldoc-compatible comments.

[![Circle CI](https://circleci.com/gh/Afforess/Factorio-Stdlib/tree/master.svg?style=svg)](https://circleci.com/gh/Afforess/Factorio-Stdlib/tree/master)
