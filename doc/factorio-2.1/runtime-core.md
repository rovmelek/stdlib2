# Runtime API: global objects, defines, events (2.1.24)

Condensed from https://lua-api.factorio.com/latest/ (index-runtime, LuaBootstrap, LuaGameScript,
LuaHelpers, LuaRendering, LuaRenderObject, LuaRemote, LuaSettings, LuaPrototypes,
LuaCommandProcessor, defines, events, EventFilter, LocalisedString). Items marked **(new)** or
**(changed)** carry that badge on the site (relative to the previous release line, i.e. 2.0).
Items marked *[unverified]* came from a partial page read.

Global objects: `game` LuaGameScript, `script` LuaBootstrap, `rendering` LuaRendering,
`remote` LuaRemote, `commands` LuaCommandProcessor, `rcon` LuaRCON, `prototypes` LuaPrototypes,
`settings` LuaSettings, `helpers` LuaHelpers, plus `storage`.

## stdlib2 call audit

| stdlib2 uses | 2.1.24 | action |
|---|---|---|
| `game.write_file` | **not on LuaGameScript** | `helpers.write_file(filename, data, append?, for_player?)` |
| `game.table_to_json` | **not on LuaGameScript** | `helpers.table_to_json(t)` (`helpers.json_to_table(s)` for reverse) |
| `game.remove_path` | **not on LuaGameScript** | `helpers.remove_path(path)` |
| `game.pollution_statistics` | **not an attribute** | `game.get_pollution_statistics(surface)` -> LuaFlowStatistics |
| `global.*` | renamed | `storage.*` (already done in most places) |
| script.on_event / on_nth_tick / on_init / on_load / on_configuration_changed / generate_event_name / get_event_handler / get_event_order / raise_event / mod_name / active_mods | exist | `raise_event` is restricted (below) |
| remote.add_interface / call / interfaces | exist | |
| game.print / get_player / players / forces / surfaces / connected_players / is_multiplayer / force_crc | exist | |
| rendering.draw_line / draw_circle | exist | return **LuaRenderObject** (not a numeric id) |
| prototypes.entity / item / equipment | exist | |
| defines.events / direction / inventory / train_state | exist | direction has 16 values; inventory changed |

## LuaBootstrap (`script`) (changed)
Methods:
- `on_init(fn?)`, `on_load(fn?)`, `on_configuration_changed(fn(ConfigurationChangedData)?)`
- `on_event(event | event[], fn(EventData)?, filters?: EventFilter)`: one handler per mod per
  event, re-registering overwrites (incl. filters); filters only with a single event, not an
  array; `nil` handler unregisters. Custom-input names are accepted as events.
- `on_nth_tick(tick | tick[] | nil, fn?)`: all handlers run on tick 0; `on_nth_tick(nil)` clears all.
- `register_on_object_destroyed(object: RegistrationTarget) -> uint64 reg_number, uint64 useful_id, defines.target_type`
  (global, persists, fires `on_object_destroyed` at end of this or next tick)
- `register_metatable(name, mt)`: root scope only, unique name per mod; not in console/events/remote.call
- `generate_event_name() -> defines.events`, `get_event_id(event)`, `get_event_name(event) -> string?` **(new)**
- `get_event_handler(event)`, `get_event_order() -> string`
- `set_event_filter(event, filters?)`, `get_event_filter(event) -> EventFilter?`
- `new_notification_queue() -> LuaNotificationQueue` **(new)**, `finish_test(passed?)` **(new)**
- `raise_event(event, data)`: **only** for `generate_event_name` events and: on_console_chat,
  on_player_crafted_item, on_player_fast_transferred, on_biter_base_built,
  on_market_item_purchased, script_raised_built, script_raised_destroy, script_raised_revive,
  script_raised_teleported, script_raised_set_tiles, script_raised_destroy_segmented_unit.
  An invalid LuaObject in `data` silently cancels the raise.
- Typed raisers: `raise_console_chat{player_index, message}`, `raise_player_crafted_item{item_stack, player_index, recipe}`,
  `raise_player_fast_transferred{player_index, entity, from_player, is_split}`, `raise_biter_base_built{entity}`,
  `raise_market_item_purchased{player_index, market, offer_index, count}`, `raise_script_built{entity}`,
  `raise_script_destroy{entity}`, `raise_script_revive{entity, tags?}`,
  `raise_script_teleported{entity, old_surface_index, old_position}`, `raise_script_set_tiles{surface_index, tiles}`,
  `raise_script_destroy_segmented_unit{segmented_unit}`.

Attributes (R): `mod_name`, `level` (`{is_simulation?, is_tutorial?, campaign_name?, level_name, mod_name?}`),
`active_mods` (name -> version), `feature_flags` **(changed)** (`expansion, quality, rail_bridges,
space_travel, spoiling, freezing, segmented_units, expansion_shaders`), `test_arg` **(new)**, `object_name`.

Filter examples:
```lua
script.on_event(defines.events.on_built_entity, fn, {{filter = "name", name = "fast-inserter"}})
script.set_event_filter(defines.events.on_marked_for_deconstruction, {{filter = "ghost", invert = true}})
{{filter = "type", type = "unit"}, {filter = "type", type = "unit-spawner"}}
{{filter = "rail"}, {filter = "damage-type", type = "acid", mode = "and"}}
```

## LuaGameScript (`game`) (changed)
Methods: `set_game_state{game_finished?, player_won?, next_level?, can_continue?}`, `reset_game_state()`,
`set_win_ending_info{title, message?, bullet_points?, final_message?, image_path?}`, `set_lose_ending_info{...}`,
`get_entity_by_tag(tag)`, `show_message_dialog{text, image?, point_to?, style?, wrapper_frame_style?}`,
`is_demo()`, `reload_script()`, `reload_mods()`, `save_atlas()`, `check_consistency()`,
`regenerate_entity(names)`, `take_screenshot{...}` (changed), `set_wait_for_screenshots_to_finish()`,
`take_technology_screenshot{...}` (changed), `remove_offline_players(players?)`, `force_crc()`,
`create_force(name)`, `merge_forces(src, dst)`, `create_surface(name, MapGenSettings?)`,
`server_save(name?)`, `auto_save(name?, allow_in_replay?)` (changed), `delete_surface(surface) -> bool`,
`delete_blueprint_library(player)` **(new)**, `disable_replay()`,
`print(LocalisedString, PrintSettings?)`, `create_random_generator(seed?) -> LuaRandomGenerator`,
`play_sound(PlaySoundSpecification)`, `play_music(PlayMusicSpecification)` **(new)**,
`kick_player`, `ban_player`, `unban_player`, `purge_player`, `mute_player`, `unmute_player`,
`is_multiplayer()`, `get_map_exchange_string()`, `get_player(index|name) -> LuaPlayer?`,
`get_surface(index|name) -> LuaSurface?`, `create_inventory(size, gui_title?)`,
`get_script_inventories(mod?)`, `reset_time_played()`,
`get_pollution_statistics(surface) -> LuaFlowStatistics`,
`get_vehicles{unit_number?, force?, surface?, type?, is_moving?, has_passenger?}`,
`get_entity_by_unit_number(n) -> LuaEntity?` (only prototypes with the get-by-unit-number flag).

Attributes: `player` (R, only in commands/console), `players`, `forces`, `surfaces` (R LuaCustomTable
by index or name), `planets` (R string -> LuaPlanet), `connected_players` (R array),
`map_settings`, `difficulty_settings`, `difficulty`, `tick`, `ticks_played`, `tick_paused` (RW),
`ticks_to_run` (RW), `speed` (RW), `finished`, `finished_but_continuing`, `permissions`,
`backer_names`, `default_map_gen_settings`, `train_manager` (R LuaTrainManager), `blueprints`,
`simulation`, `console_command_used`, `allow_debug_settings`, `autosave_enabled`,
`draw_resource_selection`, `enemy_has_vision_on_land_mines`, `technology_notifications_enabled`,
`player_death_notifications_enabled` **(new)**, `space_platform_death_notifications_enabled` **(new)**,
`allow_tip_activation`, `object_name`.

## LuaHelpers (`helpers`) (changed). Available in settings, prototype and runtime stages
`table_to_json(t)`, `json_to_table(s) -> AnyBasic?`,
`write_file(filename, data: LocalisedString, append?=false, for_player?)` (under script-output;
`for_player` not allowed in settings/data; 0 = server only), `remove_path(path)`,
`send_udp(port, data, for_player?)`, `recv_udp(for_player?)` (needs `--enable-lua-udp`),
`direction_to_string(dir)`, `evaluate_expression(expr, vars?)`, `encode_string`, `decode_string`,
`parse_map_exchange_string`, `check_prototype_translations()`, `is_valid_sound_path`,
`is_valid_ambient_sound` **(new)**, `is_valid_sprite_path`, `is_valid_animation_path` **(new)**,
`create_profiler(stopped?)`, `compare_versions(a, b) -> int32`, `multilingual_to_lower(s)`.
Attributes: `game_version`, `stage` **(new)** (`"settings"|"prototype"|"runtime"`),
`instrument_mod` **(new)**, `object_name`.

## LuaRendering (`rendering`) (changed)
All `draw_*` take one table and **return LuaRenderObject** (changed). Common tail:
`surface, time_to_live?, blink_interval?, forces?, players?, visible?, only_in_alt_mode?, tall?, render_mode?`
(+ `draw_on_ground?` for text/line/circle/rectangle/arc/polygon).
- `draw_line{color, width, gap_length?, dash_length?, dash_offset?, from, to, ...}`
- `draw_text{text, target, color, scale?, font?, orientation?, alignment?, vertical_alignment?, scale_with_zoom?, use_rich_text?, ...}`
- `draw_circle{color, radius, width?, filled?, target, ...}`
- `draw_rectangle{color, width?, filled?, left_top, right_bottom, ...}`
- `draw_arc{color, max_radius, min_radius, start_angle, angle, target, ...}`
- `draw_polygon{color, vertices, target?, orientation?, orientation_target?, use_target_orientation?, ...}`
- `draw_sprite{sprite, orientation?, x_scale?, y_scale?, tint?, render_layer?, orientation_target?, use_target_orientation?, oriented_offset?, target, light_mode?, ...}`
- `draw_light{sprite, orientation?, scale?, intensity?, minimum_darkness?, oriented?, color?, target, ...}`
- `draw_animation{animation, orientation?, x_scale?, y_scale?, tint?, render_layer?, animation_speed?, animation_offset?, ..., light_mode?}`
- `get_all_objects(mod?) -> LuaRenderObject[]`, `clear(mod?)`, `get_object_by_id(id) -> LuaRenderObject?`

Width is in pixels (32 per tile). Objects die with their entity target.
`rendering.draw_line{surface = s, from = {0, 0}, to = {2, 2}, color = {1, 1, 1}, width = 2}`

**LuaRenderObject**: methods `destroy()`, `bring_to_front()`, `move_to_back()`,
`set_dashes(dash, gap)`, `set_corners(lt, rb)`. Attributes: `id` (uint64), `type`, `surface`,
`valid`, plus RW versions of every draw parameter (`color, width, from, to, target, text, radius,
visible, time_to_live, players, forces, ...`), `tall` **(new)**, `light_mode` **(new)**.
So the old `rendering.destroy(id)` / `rendering.set_color(id, c)` style is replaced by
`obj.destroy()` / `obj.color = c`.

## LuaRemote (`remote`)
`add_interface(name, {fn...})` (errors if exists), `remove_interface(name) -> bool`,
`call(interface, fn, ...) -> Any?` (args copied, metatables dropped, LuaObjects kept, no
functions). Attribute `interfaces` (name -> {fn = true}).

## LuaSettings (`settings`)
`get_player_settings(player) -> LuaCustomTable[string -> ModSetting]`; attributes `startup`,
`global` (write an entry by assigning `{value = x}`), `player_default`.

## LuaPrototypes (`prototypes`) (changed)
Filtered getters: `get_entity_filtered, get_item_filtered, get_equipment_filtered,
get_mod_setting_filtered, get_achievement_filtered, get_tile_filtered, get_decorative_filtered,
get_fluid_filtered, get_recipe_filtered, get_technology_filtered` (each `filters[]` ->
LuaCustomTable), `get_history(type, name) -> PrototypeHistory`.
Tables: `entity, item, fluid, tile, equipment, damage, virtual_signal, equipment_grid, recipe,
technology, decorative, particle, autoplace_control, mod_setting, custom_input, ammo_category,
named_noise_expression, named_noise_function, item_group` (changed), `item_subgroup` (changed),
`fuel_category, resource_category, achievement, module_category, equipment_category,
trivial_smoke, shortcut, recipe_category, quality, surface_property, space_location,
space_connection, custom_event, active_trigger, asteroid_chunk, collision_layer,
airborne_pollutant, burner_usage, mod_data, surface, procession,
procession_layer_inheritance_group, font, map_gen_preset, style`;
`utility_constants` (changed); distance maxima such as `max_inserter_reach_distance`,
`max_underground_belt_distance`, `max_logistics_connection_distance` **(new)**.

## LuaCommandProcessor (`commands`)
`add_command(name, help, fn(CustomCommandData{name, tick, player_index?, parameter?}))`,
`remove_command(name) -> bool`; attributes `commands`, `game_commands`. Not persisted; register
in control.lua main chunk / on_load.

## defines (62 namespaces)
alert_type (changed), behavior_result, build_check_type, build_mode, cargo_destination,
chain_signal_state, chunk_generated_status, command, compound_command, constant **(new)**,
control_behavior (changed), controllers, deconstruction_item, difficulty, direction,
disconnect_reason, distraction, electric_interface_mode **(new)**, entity_status (changed),
entity_status_diode, events (changed), flow_precision_index, game_controller_interaction,
group_state, gui_type (changed), input_action (changed), input_method, inventory (changed),
inventory_actions **(new)**, logistic_group_type, logistic_member_index, logistic_mode,
logistic_section_type, mouse_button_type, moving_state, print_skip, print_sound, prototypes
(changed), rail_connection_direction, rail_direction, rail_layer, relative_gui_position,
relative_gui_type (changed), render_mode, rich_text_setting, riding, robot_order_type,
rocket_silo_status, segmented_unit_activity_mode, segmented_unit_ai_state,
segmented_unit_created_cause, selection_mode (changed), shooting, signal_state,
space_platform_state, target_type (changed), territory_created_cause, train_state,
transport_line, wire_connector_id, wire_origin, wire_type.

- `defines.direction` (16): north, northnortheast, northeast, eastnortheast, east,
  eastsoutheast, southeast, southsoutheast, south, southsouthwest, southwest, westsouthwest,
  west, westnorthwest, northwest, northnorthwest. *Numeric values not captured; since 2.0 they
  are 0..15 (north=0, east=4, south=8, west=12), which stdlib2 `area/direction.lua` must use.*
- `defines.inventory` (changed): fuel, burnt_result, chest, logistic_container_trash,
  character_main/guns/ammo/armor/vehicle/trash, god_main, editor_main/guns/ammo/armor,
  roboport_robot/material, robot_cargo/repair, assembling_machine_dump, lab_input/modules/trash,
  mining_drill_modules, item_main, rocket_silo_rocket/trash/attached_cargo_unit, cargo_unit,
  car_trunk/ammo/trash, cargo_wagon, turret_ammo, beacon_modules, character_corpse,
  artillery_turret_ammo, artillery_wagon_ammo, spider_trunk/ammo/trash, hub_main/trash,
  cargo_landing_pad_main/trash, proxy_main, agricultural_tower_input/output/modules,
  linked_container_main, **crafter_input, crafter_output, crafter_modules, crafter_trash**,
  asteroid_collector_output/arm. *[unverified, from partial read]* Note the generic `crafter_*`
  names: old per-machine names (e.g. `assembling_machine_input`, `furnace_source`) should be
  checked before use.
- `defines.controllers`: ghost, character, god, editor, cutscene, spectator, remote.
- `defines.constant` (new): default_icon_size. `defines.difficulty`: easy, normal, hard.
- `defines.train_state`: members not captured; verify on defines.html before use.

## Events
`defines.events` has 227 entries (ends with `script_raised_teleported`). Every handler gets
`{name, tick, ...}`. Also on events.html (not in defines.events): `CustomInputEvent`,
`RecipeCraftedEvent` **(new)** (for recipes with `raise_on_crafted`).
- **New:** on_blueprint_settings_pasted, on_gui_inventory_action, on_next_day_started,
  on_player_cancel_selected_area, on_player_change_selected_area; *[unverified]* on_player_color_changed,
  on_player_music_changed, on_player_start_selected_area, on_player_super_forced_selected_area.
- **Changed:** on_player_alt_reverse_selected_area, on_player_alt_selected_area;
  *[unverified]* on_player_deconstructed_area, on_player_respawned, on_player_reverse_selected_area,
  on_player_rotated_entity, on_player_selected_area, on_player_setup_blueprint.
- stdlib2 `event/modules/event_filters.lua` and `dump_event_data.lua` should be checked against
  this list (e.g. on_entity_destroyed became on_object_destroyed in 2.0).

EventFilter: an array of filters for **one** event type (30 filter concept types, e.g.
LuaPlayerBuiltEntityEventFilter, LuaEntityDiedEventFilter, LuaScriptRaisedBuiltEventFilter,
LuaPlatformBuiltEntityEventFilter, LuaSectorScannedEventFilter, LuaSegmentedUnit*EventFilter).
Keys: `filter`, plus filter-specific (`name`, `type`, ...), `invert`, `mode = "or"|"and"`.

## LocalisedString
`string | number | boolean | LuaObject | nil | LocalisedString[]`. Array: first = key, rest fill
`__1__...`. Max 20 deep, 20 params. `""` key concatenates; `"?"` key picks first valid
alternative (fallback). Example `{"description.durability", 5, 9}`.
