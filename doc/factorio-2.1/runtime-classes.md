<!-- Condensed from lua-api.factorio.com/latest class and concept pages, read 2026-11-07. -->

# stdlib2 port reference: Factorio runtime API (docs 2.1.24)

**Markers:** [N] = marked new on the page, [C] = marked changed, [Q] = quality-related, [S] = taken from the model-generated summary of a page tail (fetch cut each long page at about 39.9k characters), not verbatim. No page I read marks anything deprecated.

**Version caveat:** Most pages show the banner "Version 2.1.24". BoundingBox shows 2.1.21, ItemStackIdentification and LuaTile show 2.1.23, and SurfaceIdentification shows 2.1.14. The pages give no per-member version, so [N]/[C] flags carry no version number.

**Gaps:** LuaForce's final 6,147 characters were never read. Several class tails (LuaEntity, LuaSurface, LuaPlayer, LuaControl, LuaInventory, LuaItemStack, LuaTrain, LuaGuiElement) are [S]. Section 14 lists details.

---

## 1. Concepts (exact accepted shapes)

### 1.1 MapPosition (2.1.24)
- Two forms: table `{x = double, y = double}` or array `{double, double}`.
- Examples from the page: `{x = 5.5, y = 2}`, `{y = 2.25, x = 5.125}`, shorthand `{1.625, 2.375}`.
- Reads always return the table form.
- Stored as fixed 32-bit with 8 fractional bits, so the minimum step is 1/256 = 0.00390625 tiles.
- Used by, among others: `LuaControl.position`/`render_position` (R), `teleport`, `can_place_entity`, `update_selected_entity`, `LuaEntity.drop_position`/`pickup_position` (RW), `LuaSurface.get_pollution`/`set_pollution`, `find_non_colliding_position(center)`, `LuaForce.get_spawn_position`, `LuaPlayer.add_pin`, `LuaPlayer.can_build_from_cursor`.

### 1.2 BoundingBox (banner 2.1.21)
- Table form: `{left_top = MapPosition, right_bottom = MapPosition, orientation = RealOrientation?}`. The field names use underscores; `orientation` is optional.
- Array form: `{MapPosition, MapPosition}`, with an optional third element for orientation. Shorthand example: `{{-2, -3}, {5, 8}}`.
- When read from the game, `orientation` is present only if non-zero.
- Used by: `LuaEntity.mining_area`/`bounding_box`/`selection_box`/`secondary_*` (R), `LuaSurface.find_entities(area)`, `find_non_colliding_position_in_box`, `find_units{area}`, `find_tiles_filtered`/`count_tiles_filtered` (via TileSearchFilters), `create_entity` [S], `request_path{bounding_box}` [S], `LuaForce.chart`/`find_chart_tags`, `LuaItemCommon.create_blueprint`/`deconstruct_area`.

### 1.3 ChunkPosition (2.1.24)
- Table `{x = int32, y = int32}` or array `{int32, int32}`. Same format as MapPosition.
- Convert a MapPosition to a ChunkPosition by dividing x and y by 32. The page does not state rounding.
- Used by: `LuaSurface.is_chunk_generated`, `set_chunk_generated_status`, `delete_chunk`, `get_territory_for_chunk`, `set_territory_for_chunks`, `clear_territory_for_chunks`, `get_entities_with_force`, `get_random_chunk` (returns it), `LuaForce.is_chunk_charted`, `is_chunk_visible`, `is_chunk_requested_for_charting`, `unchart_chunk`, `get_chunk_chart`.

### 1.4 EntitySearchFilters (2.1.24, table)
| Field | Type | Notes |
|---|---|---|
| `area` | BoundingBox? | |
| `position` | MapPosition? | Takes precedence over `area`. |
| `radius` | double? | Used with `position`: all entities within radius. |
| `name` | EntityID or array[EntityID]? | Empty array matches nothing. |
| `type` | string or array[string]? | Empty array matches nothing. |
| `ghost_name` | EntityID or array[EntityID]? | Empty array matches nothing. |
| `ghost_type` | string or array[string]? | Empty array matches nothing. |
| `direction` | defines.direction or array? | |
| `collision_mask` | CollisionLayerID, array[CollisionLayerID], or dictionary[CollisionLayerID → true]? | |
| `force` | ForceSet? | |
| `to_be_deconstructed` | boolean? | |
| `to_be_upgraded` | boolean? | |
| `limit` | uint32? | |
| `is_military_target` | boolean? | |
| `has_item_inside` | ItemWithQualityID? | [Q] |
| `quality` | QualityCondition? | [Q] |
| `invert` | boolean? | Inverts the filters. |

- Used by `LuaSurface.find_entities_filtered(filter)` → array[LuaEntity] and `count_entities_filtered(filter)` → uint32.
- There is no `surface` field; the surface is the LuaSurface receiver.
- No field is marked new or changed on this page.

### 1.5 SurfaceIdentification (banner 2.1.14, union)
- `uint32`: surface index (nauvis = 1; later surfaces count upward).
- `string`: surface name, e.g. `"nauvis"`.
- `LuaSurface`: the object itself.
- Used by: `LuaControl.teleport(surface?)`, `LuaPlayer.set_controller`, `add_pin`, `create_local_flying_text`, `LuaForce` chart and surface methods (`chart`, `clear_chart`, `rechart`, `chart_all`, `copy_chart`, `cancel_charting`, `find_logistic_network_by_position`, `set/get_spawn_position`, `set/get_surface_hidden`, `unchart_chunk`, `add_chart_tag`, `find_chart_tags`, `get/set_evolution_factor*`, the `get_*_statistics` family, `get_chunk_chart`), `LuaItemCommon.build_blueprint`/`create_blueprint`/`deconstruct_area`/`cancel_deconstruct_area`, `LuaSurface.clone_*`.

### 1.6 ItemStackIdentification (banner 2.1.23, union)
- `string`: item name, meaning a full stack. Example: `"iron-plate"`, which the page says is a full stack of 100.
- `ItemStackDefinition`: table form with `name`, `count`, `quality`. Page examples: `{name="iron-plate"}`, `{name="iron-plate", count=1}`, `{name="iron-plate", count=1, quality="normal"}`, `{name="copper-plate", count=47}`. The ItemStackDefinition page was not read, so the default for `quality` is unconfirmed.
- `LuaItemStack`: the object.
- Used by: `LuaControl.insert`/`can_insert`/`remove_item`, `LuaInventory.insert`/`can_insert`/`remove`, `LuaItemStack.set_stack`/`can_set_stack`/`transfer_stack`, `LuaTrain.insert`/`remove_item`, `LuaSurface.spill_item_stack`, `LuaLogisticNetwork.insert`/`remove_item`.

### 1.7 Quality ID types (referenced, not read)
ItemWithQualityID, ItemIDAndQualityIDPair, EntityWithQualityID, QualityID, QualityCondition, ItemWithQualityCount, PrototypeWithQuality, RecipeIDAndQualityIDPair and EquipmentWithQualityID are used in signatures below. Their definitions were not fetched.

---

## 2. LuaControl (abstract; base of LuaEntity and LuaPlayer) [C]

Non-character entities reach player-only methods only if they are characters. Methods marked "character" need an associated character when called on a LuaPlayer.

**Methods (inherited by LuaEntity and LuaPlayer):**
- `get_inventory(inventory: defines.inventory) → LuaInventory?`
- `get_inventory_name(inventory) → string?`
- `get_max_inventory_index() → defines.inventory`
- `get_main_inventory() → LuaInventory?` (character/player only)
- `can_insert(items: ItemStackIdentification) → boolean`
- `insert(items: ItemStackIdentification) → uint32`
- `remove_item(items: ItemStackIdentification) → uint32`
- `get_item_count(item?: ItemFilter-or-ItemID) → uint32`
- `has_items_inside() → boolean`, `clear_items_inside()`
- `can_reach_entity(entity: LuaEntity) → boolean`
- `teleport(position, surface?: SurfaceIdentification, raise_teleported?, snap_to_grid?, build_check_type?) → boolean`. A one- or two-number shorthand is treated as a relative offset [S].
- `update_selected_entity(position)`, `clear_selected_entity()`
- `set_gui_arrow{margin: uint32, type: GuiArrowType, ...}`, `clear_gui_arrow()`
- `enable_flashlight()`, `disable_flashlight()`, `is_flashlight_enabled() → boolean`
- `get_craftable_count(recipe: RecipeID) → uint32`
- `begin_crafting{count: uint32, recipe: RecipeID, silent?} → uint32`
- `cancel_crafting{index: uint32, count: uint32}`
- `mine_entity(entity, force?) → boolean`, `mine_tile(tile: LuaTile) → boolean`
- `is_player() → boolean`
- `open_technology_gui(technology?)`, `open_factoriopedia_gui(prototype?)`, `close_factoriopedia_gui()`
- `is_cursor_blueprint() → boolean`, `is_cursor_empty() → boolean`
- `get_requester_point() → LuaLogisticPoint?`
- `set_driving(driving: boolean, force?: boolean)`
- `can_place_entity{name: EntityID, position: MapPosition, direction?} → boolean`

**Attributes:**
- `surface` R LuaSurface; `surface_index` R uint32
- `position` R MapPosition; `render_position` R MapPosition
- `is_flying` R boolean; `flight_height` R double
- `vehicle` R LuaEntity?; `cargo_pod` R LuaEntity?; `hub` R LuaEntity?
- `force` R LuaForce | W ForceID; `force_index` R uint32
- `selected` RW LuaEntity?
- `opened` RW [C]: LuaEntity, LuaItemStack, LuaEquipment, LuaEquipmentGrid, LuaPlayer, LuaGuiElement, LuaInventory, LuaLogisticNetwork, LuaTile, or defines.gui_type?
- `opened_gui_type` R defines.gui_type?
- `crafting_queue_size` R uint32; `crafting_queue_progress` RW double (0–1); `crafting_queue` R array[CraftingQueueItem]?
- `walking_state`, `mining_state`, `shooting_state`, `repair_state` RW table; `riding_state` RW RidingState; `picking_state` RW boolean
- `mining_progress` RW double [N] (0–1 for characters and players)
- `character_mining_progress` R double
- `driving` RW boolean; `cheat_mode` RW boolean; `in_combat` R boolean
- `cursor_stack` R LuaItemStack?; `cursor_record` R LuaRecord?
- `cursor_ghost` R ItemIDAndQualityIDPair? | W ItemWithQualityID? [Q]
- `following_robots` R array[LuaEntity]
- Character modifiers (RW, character-only for players): `character_crafting_speed_modifier` (double), `character_mining_speed_modifier` (double), `character_additional_mining_categories` (array[string]), `character_running_speed_modifier` (double, percentage), `character_build_distance_bonus`, `character_item_drop_distance_bonus`, `character_reach_distance_bonus`, `character_resource_reach_distance_bonus`, `character_item_pickup_distance_bonus`, `character_loot_pickup_distance_bonus`, `character_inventory_slots_bonus`, `character_trash_slot_count_bonus`, `character_maximum_following_robot_count_bonus` (all uint32), `character_health_bonus` (float)
- Character reads (R): `build_distance`, `drop_item_distance`, `reach_distance` (uint32; max uint when not a character), `item_pickup_distance`, `loot_pickup_distance`, `resource_reach_distance` (double; max double when not a character), `character_running_speed` (double)
- Summary-only: writing `mining_state` errors unless the controller type is character, god, or editor [S].

---

## 3. LuaEntity (extends LuaControl) [C]

About 60 niche entries are omitted from the signatures below: ghost-specific, rail-signal, spider, cargo-pod, territory, tooltip, and remaining fluid-segment internals. Names are listed where I saw them.

### 3.1 Inventories and filters
- `get_output_inventory() → LuaInventory?`, `get_module_inventory() → LuaInventory?`, `get_fuel_inventory() → LuaInventory?`, `get_burnt_result_inventory() → LuaInventory?`
- `get_filter(slot_index) → ItemFilter | EntityID | AsteroidChunkID?` (type depends on entity kind)
- `set_filter(index, filter?)`: ItemFilter for inserter/loader; EntityID for mining drill; AsteroidChunkID for asteroid collector; ItemWithQualityID for logistic storage container [Q]
- `get_infinity_container_filter(index) → InfinityInventoryFilter?`, `set_infinity_container_filter(index, filter)`
- `get_infinity_pipe_filter() → InfinityPipeFilter?`, `set_infinity_pipe_filter(filter)`
- `get_inventory_bar(inventory_index) → uint32`, `set_inventory_bar(inventory_index, bar?)`, `inventory_supports_bar(...)`, `inventory_supports_filters(...)`, `is_inventory_filtered(...)`, `can_set_inventory_filter(...)`, `get_inventory_filter(...)`, `set_inventory_filter(...)` [S]
- `set_inventory_size_override(inventory_index, size_override, overflow?)`, `get_inventory_size_override(inventory_index) → uint16?` [S]

### 3.2 Lifecycle, damage, orders
- `damage(damage, force, type?, source?, cause?) → float`
- `destroy{do_cliff_correction?, raise_destroy?, player?, undo_index?} → boolean`
- `die(force?, cause?) → boolean`
- `can_be_destroyed() → boolean`
- `has_flag(flag) → boolean`, `ghost_has_flag(flag) → boolean`
- `order_deconstruction(force, player?, undo_index?) → boolean`, `cancel_deconstruction(force, player?)`, `to_be_deconstructed() → boolean`
- `order_upgrade{target, force, player?, undo_index?} → boolean`, `cancel_upgrade(force, player?) → boolean`, `to_be_upgraded() → boolean`
- `apply_upgrade(override_target?, buffer?) → LuaEntity?, LuaEntity?` [C]
- `revive{raise_revive?, overflow?} → array[ItemWithQualityCount]?, LuaEntity?, LuaEntity?` (ghosts only)
- `silent_revive{raise_revive?, overflow?} → array[ItemWithQualityCount], LuaEntity?, LuaEntity?`
- `clone{position, surface?, force?, create_build_effect_smoke?} → LuaEntity?`
- `rotate{reverse?, by_player?} → boolean`; `flip{horizontal, by_player?} → boolean` [N]
- `mine{inventory?, force?, raise_destroyed?, ignore_minable?} → boolean` [S]
- `deplete()`, `release_from_spawner()`, `create_build_effect_smoke()` [S]
- `is_registered_for_construction()`, `is_registered_for_deconstruction(force)`, `is_registered_for_upgrade()`, `is_registered_for_repair()` [S]
- `get_upgrade_target() → LuaEntityPrototype?, LuaQualityPrototype?` [S] [Q]
- `get_damage_to_be_taken() → float?`, `get_health_ratio() → float?`, `get_radius() → double` (verbatim)

### 3.3 Logistics, transport, and circuits
- `get_transport_line(index) → LuaTransportLine`; `get_max_transport_line_index() → defines.transport_line`
- `get_item_insert_specification(position, mirrored?) → uint32, float` [C]
- `get_line_item_position(index, position) → MapPosition`
- `get_logistic_point(index?) → LuaLogisticPoint or array[LuaLogisticPoint]?`
- `get_logistic_sections() → LuaLogisticSections?` [S]
- `get_control_behavior() → LuaControlBehavior?`; `get_or_create_control_behavior() → LuaControlBehavior?`
- `get_circuit_network(wire_connector_id) → LuaCircuitNetwork?`
- `get_signal(signal, wire_connector_id, extra_wire_connector_id?) → int32`
- `get_signals(wire_connector_id, extra_wire_connector_id?) → array[Signal]?`
- `get_signals_changed(wire_connector_id, tick_of_last_check?) → boolean?` [N]
- `get_wire_connector(wire_connector_id, or_create) → LuaWireConnector?`, `get_wire_connectors(or_create)` [S]
- `can_wires_reach(entity) → boolean` [S]
- `update_connections()`: reconnects loader, beacon, cliff and mining-drill links after script teleports [verbatim].

### 3.4 Recipes and quality [Q]
- `get_recipe() → LuaRecipe?, LuaQualityPrototype?`
- `set_recipe(recipe?, quality?) → array[ItemWithQualityCount]`
- `copy_settings(entity, by_player?) → array[ItemWithQualityCount]`
- `get_electric_input_flow_limit(quality?) → double?`, `get_electric_output_flow_limit(quality?) → double?` [S] [Q]
- `create_cargo_pod{cargo_hatch?, cargo_pod_prototype?} → LuaEntity?` [C] [S]
- `get_stored_durability(item) → LabStoredDurability`, `set_stored_durability(item, durability)`, `clear_stored_durability()` [N] [S]
- Tooltip API [N] [S]: `get_tooltip_fields()`, `get_tooltip_field(id)`, `set_tooltip_field(field) → uint32`, `clear_tooltip_field(id)`, `clear_tooltip_fields()`

### 3.5 Vehicles, trains, passengers
- `get_driver() → LuaEntity or LuaPlayer?`, `set_driver(driver)`
- `get_passenger() → LuaEntity or LuaPlayer?`, `set_passenger(passenger)`
- `connect_rolling_stock(direction) → boolean`, `disconnect_rolling_stock(direction) → boolean`
- `get_train_stop_trains() → array[LuaTrain]`: trains scheduled to stop here.
- `get_stopped_train() → LuaTrain?`: the train currently stopped here.
- `get_rail_end(direction) → LuaRailEnd` [S]; rail-segment helpers such as `get_rail_segment_stop`, `get_rail_segment_rails`, `get_rail_segment_length`, `is_rail_in_same_rail_segment_as`, `is_rail_in_same_rail_block_as` [S].
- `get_connected_rail{rail_direction, rail_connection_direction}`, `get_connected_rails()` (verbatim).

### 3.6 Fluids (heavily reworked in 2.1)
Methods the page marks [C] or [N]. Most fluid-box helpers are new.
- `get_fluid_count(fluid?) → FluidAmount` [C]
- `get_fluid_contents() → dictionary[string → FluidAmount]`
- `get_fluid(index) → Fluid?` [C]
- `set_fluid(index, fluid) → FluidAmount` [C]
- `add_fluid(index, fluid) → FluidAmount` [N]
- `remove_fluid(index, amount) → Fluid?` [C]
- `clear_fluid(index) → Fluid?` [N]
- `clear_fluids() → array[Fluid]` [N]
- `clear_fluid_inside()`: removes fluid in this entity and connected segments.
- `insert_fluid(fluid) → FluidAmount` [C]
- `extract_fluid{name, amount, minimum_temperature?, maximum_temperature?, temperature?} → FluidAmount` [N]
- `get_fluid_capacity(index) → FluidAmount` [N]
- `get_fluid_filter(index) → LuaFluidPrototype?`, `set_fluid_filter(index, filter?) → boolean` [N]
- `get_fluid_box_prototype(index) → LuaFluidBoxPrototype or array?` [N]
- `get_fluid_box_neighbours(index) → array[FluidBoxNeighbourRecord]?` [N]
- `get_fluid_box_pipe_connections(index) → array[PipeConnection]?` [N]
- `add_fluid_box_linked_connection(this_id, other_entity, other_id)`, `remove_fluid_box_linked_connection(this_id)`, `get_fluid_box_linked_connection(this_id) → LuaEntity?, uint32?`, `get_fluid_box_linked_connections() → array[FluidBoxConnectionRecord]` [N]
- Fluid segments [N]: `has_fluid_segment(index)`, `get_fluid_segment_fluid(index)`, `set_fluid_segment_fluid(index, fluid)`, `add_fluid_segment_fluid(index, fluid)`, `clear_fluid_segment_fluid(index)`, `remove_fluid_segment_fluid(index, amount)`, `get_fluid_segment_filter(index)`, `get_fluid_segment_capacity(index)`, `get_fluid_segment_extent_bounding_box(index) → BoundingBox`, `get_fluid_segment_id(index) → uint32`
- `get_fluid_source_tile() → TilePosition`, `get_fluid_source_fluid() → string?` [S]
- Beams: `get_beam_source()`/`set_beam_source(source)`, `get_beam_target()`/`set_beam_target(target)` → BeamTarget?

### 3.7 Entity-specific and miscellaneous
- `get_beacons()`, `get_beacon_effect_receivers()` [S]
- `get_spider_legs()`, `stop_spider()`, `get_movement()`, `set_movement(direction, speed)`, `get_cargo_bays()`, `register_tree(tree)` [S]
- `play_note(instrument, note, stop_playing_sounds?) → boolean`
- `launch_rocket(destination?, character?) → boolean`
- `get_priority_target(index)`, `set_priority_target(index, entity_id?)` [S]
- `supports_backer_name() → boolean`
- `get_connected_rolling_stock(direction)` [S]
- Autopilot: `add_autopilot_destination(position, attempt_patrol?)` [C] [S]
- Doors: `is_opened()`, `is_opening()`, `is_closed()`, `is_closing()`, `request_to_open(force, extra_time?)`, `request_to_close(force)`
- Heat: `get_heat_setting() → HeatSetting`, `set_heat_setting(filter)`

### 3.8 Attributes (LuaEntity)
**Identity and state:**
- `name` R string; `ghost_name` R string; `type` R string; `ghost_type` R string
- `localised_name`, `localised_description`, `ghost_localised_name`, `ghost_localised_description` R LocalisedString
- `unit_number` R uint64?; `ghost_unit_number` R uint64?; `backer_name` RW string?; `entity_label` RW string?
- `color` RW Color?; `prototype` R LuaEntityPrototype; `ghost_prototype` R LuaEntityPrototype or LuaTilePrototype
- `active` R boolean [C]; `minable` R boolean [C]; `minable_flag` RW boolean; `destructible` RW boolean; `operable` RW boolean; `rotatable` RW boolean
- `protected` RW boolean [N]
- `use_filters` RW boolean; `to_be_looted` RW boolean; `time_to_live` RW uint64
- `health` RW float?; `max_health` R float
- `direction` RW defines.direction; `mirroring` RW boolean; `supports_direction` R boolean
- `orientation` RW RealOrientation; `cliff_orientation` R CliffOrientation; `relative_turret_orientation` RW RealOrientation?; `torso_orientation` RW RealOrientation
- `rail_length` R double; `fluids_count` R uint32
- `amount` RW uint32; `initial_amount` RW uint32?; `energy` RW double; `temperature` RW double?; `effectivity_modifier`, `consumption_modifier`, `friction_modifier` RW float
- `speed` RW float?; `effective_speed` R float?; `driver_is_gunner` RW boolean?; `vehicle_automatic_targeting_parameters` RW; `selected_gun_index` RW uint32?
- `stack` R LuaItemStack; `held_stack` R LuaItemStack; `held_stack_position` R MapPosition
- `drop_position`, `pickup_position` RW MapPosition; `drop_target`, `pickup_target` RW LuaEntity?
- `train` R LuaTrain?
- `mining_target` R LuaEntity?; `mining_area` R BoundingBox; `bonus_mining_progress` RW double?; `filter_slot_count` R uint32; `loader_container` R LuaEntity?; `loader_type` RW BeltConnectionType; `belt_to_ground_type` R BeltConnectionType
- Boxes: `bounding_box`, `selection_box` R BoundingBox; `secondary_bounding_box`, `secondary_selection_box` R BoundingBox?
- Neighbours: `belt_neighbours` R table; `heat_neighbours` R array[LuaEntity]; `fluidbox_neighbours` R array[array[LuaEntity]] [N]; `underground_belt_neighbour` R LuaEntity? [N]; `wall_neighbours` R table [N]; `cliff_neighbours` R table [N]; `neighbour_connectable_connections` R array[NeighbourConnectableConnection] [N]
- Crafting: `crafting_speed` R double; `crafting_progress` RW float; `bonus_progress` RW double; `productivity_bonus`, `pollution_bonus`, `speed_bonus`, `consumption_bonus` R double
- Quality [Q]: `result_quality` R LuaQualityPrototype? | W QualityID?; `previous_recipe` R RecipeIDAndQualityIDPair?; `item_requests` R array[ItemWithQualityCount]
- Electric: `electric_buffer_size` RW double?; `electric_drain` R double?; `electric_emissions_per_joule` R dictionary[string → double]?
- Rockets/platforms: `rocket_parts` RW uint32; `send_to_orbit_automatically` RW boolean; `transitional_request_target` R LuaSpacePlatform? [S]; `use_transitional_requests` RW boolean [S]
- Logistic: `logistic_network` RW LuaLogisticNetwork; `logistic_cell` R LuaLogisticCell
- Plans: `insert_plan`, `removal_plan` RW array[BlueprintInsertPlan]
- Player-related: `player` R LuaPlayer?; `last_user` R LuaPlayer? | W PlayerIdentification?; `damage_dealt` RW double; `kills` RW uint32; `ignore_unprioritised_targets` RW boolean [S]
- `grid` R LuaEquipmentGrid [S]: truncated in the verbatim text.
- Other [S]: `signal_state` R defines.signal_state; `chain_signal_state` R defines.chain_signal_state.

---

## 4. LuaPlayer (extends LuaControl) [C]

### 4.1 Methods (LuaPlayer-specific)
**Printing and UI:**
- `print(message, print_settings?)`, `clear_console()`
- `set_goal_description(text?, only_update?)`, `get_goal_description() → LocalisedString`
- `set_ending_screen_data(message, file?)`
- `create_local_flying_text{text, position?, surface?, create_at_cursor?, color?, time_to_live?, speed?}`, `clear_local_flying_texts()`
- `print_entity_statistics(entities?)` [Q: argument is array of EntityWithQualityID]
- `print_robot_jobs()`, `print_lua_object_statistics()`
- `unlock_achievement(name)`

**Alerts:**
- `add_alert(entity, type)`, `add_custom_alert(entity, icon, message, show_on_map)`
- `remove_alert(filter) [C]`, `get_alerts(filter) → dictionary[uint32 → dictionary[defines.alert_type → array[Alert]]] [C]`
- `mute_alert(alert_type) → boolean`, `unmute_alert(alert_type) → boolean`, `is_alert_muted(alert_type)`, `enable_alert(alert_type) → boolean`, `disable_alert(alert_type) → boolean`, `is_alert_enabled(alert_type)`

**Pins [C/N]:**
- `add_pin{label?, preview_distance?, always_visible?, entity?, player?, surface?, resource?, chart_tag?, position?} → LuaPin` [C]. `preview_distance` uint16? defaults to 16; `always_visible` boolean? defaults to true; `resource` EntityID? requires `surface` and `position`.
- `get_pins() → array[LuaPin]` [N], `clear_pins()` [N]

**Cursor and building:**
- `clear_cursor() → boolean`
- `can_build_from_cursor{position, direction?, flip_horizontal?, flip_vertical?, build_mode?, terrain_building_size?, skip_fog_of_war?} → boolean` (verbatim list truncated; `mirror` likely also exists)
- `build_from_cursor{position, direction?, mirror?, flip_horizontal?, flip_vertical?, build_mode?, terrain_building_size?, skip_fog_of_war?}`
- `use_from_cursor(position)`
- `pipette(id: PipetteID, quality?: QualityID, allow_ghost?: boolean) → boolean` [Q] (`allow_ghost` defaults to false [S])
- `drag_wire{position} → boolean`
- `start_selection(position, selection_mode)`, `clear_selection()`
- `clear_inventory_highlights()`
- `cursor_transfer(inventory, index) → boolean` [N], `cursor_split(inventory, index) → boolean` [N]
- `stack_transfers{source_inventory, index, target, transfer_type, target_equipment_grid?, play_transfer_sound?, check_for_invalid_armor_removal?, notify_if_invalid_armor_removal?} → array[ItemWithQualityCount]?` [N] [Q]

**Character and controller:**
- `create_character(character?) → boolean` [Q: EntityWithQualityID per summary]
- `set_controller{type, character?, waypoints?, start_position?, start_zoom?, final_transition_time?, chart_mode_cutoff?, position?, surface?}`
- `associate_character(character)`, `disassociate_character(character)`, `get_associated_characters() → array[LuaEntity]`
- `swap_characters(player) → boolean`
- `enter_space_platform(space_platform) → boolean` [S], `leave_space_platform()` [S], `land_on_planet() → boolean` [S]
- `set_zoom_limits(controller_type, zoom_limits)` [S]
- `exit_remote_view()`, `exit_cutscene()`, `jump_to_cutscene_waypoint(waypoint_index)`
- `toggle_map_editor()`, `get_infinity_inventory_filter(index)`, `set_infinity_inventory_filter(index, filter)`

**Quickbar:**
- `get_quick_bar_slot(page_index, slot_index) → QuickBarSlot? [C]`
- `set_quick_bar_slot(page_index, slot_index, filter) [C]`
- `get_active_quick_bar_page(index) → uint8?`, `set_active_quick_bar_page(screen_index, page_index)`

**Recipes, blueprints, clipboard:**
- `get_recipe_notifications() → array[LuaRecipePrototype]`; `add_recipe_notification(recipe)`, `clear_recipe_notification(recipe)`, `clear_recipe_notifications()`
- `add_to_clipboard(blueprint)`, `activate_paste()`
- `disable_recipe_groups()`, `enable_recipe_groups()`, `disable_recipe_subgroups()`, `enable_recipe_subgroups()`

**Sound, music, misc:**
- `play_sound(sound_specification)` [S], `play_music(music_specification)` [N]
- `connect_to_server{address, name?, description?, password?}` [S]
- `request_translation(localised_string) → uint32`, `request_translations(localised_strings) → array[uint32]`

### 4.2 Attributes (LuaPlayer)
- Identity: `name` R string; `index` R uint32; `tag` RW string; `color` RW Color; `chat_color` RW Color; `admin` RW boolean; `connected` R boolean; `permission_group` RW LuaPermissionGroup?; `mod_settings` R LuaCustomTable[string → ModSetting]
- Character and position: `character` RW LuaEntity?; `cutscene_character` R LuaEntity?; `physical_surface` R LuaSurface; `physical_surface_index` R uint32; `physical_position` R MapPosition; `physical_vehicle` R LuaEntity?; `physical_controller_type` R defines.controllers; `controller_type` R defines.controllers; `stashed_controller_type` R defines.controllers?
- View: `zoom` RW double; `zoom_limits` RW ZoomLimits; `centered_on` RW LuaEntity?; `game_view_settings` RW GameViewSettings; `map_view_settings` W MapViewSettings; `minimap_enabled` RW boolean; `show_on_map` RW boolean; `render_mode` R defines.render_mode; `input_method` R defines.input_method
- Display: `display_resolution` R DisplayResolution; `display_scale` R double; `display_density_scale` R double; `locale` R string
- Inventory and cursor: `cursor_stack_temporary` RW boolean; `hand_location` RW ItemStackLocation?; `auto_sort_main_inventory` R boolean; `blueprint_to_setup` R LuaItemStack; `blueprints` R array[LuaRecord]; `undo_redo_stack` R LuaUndoRedoStack; `drag_target` R DragTarget?
- Selection: `spidertron_remote_selection` RW array[LuaEntity]?; `entity_copy_source` RW LuaEntity? [C]
- Timing: `afk_time`, `online_time`, `last_online` R uint32 (ticks)
- Respawn: `ticks_to_respawn` RW uint32?; `respawn_quality` R LuaQualityPrototype? | W QualityID? [N] [Q]
- Settings: `disable_space_map` RW boolean [N]; `toggle_menu_leaves_remote_view` RW boolean [N]; `hide_locked_prototypes_in_factoriopedia` RW boolean [N]; `current_music` R string [N]; `saved_logistic_filters` RW SavedLogisticFilters [N]; `editor_settings` RW MapEditorSetting? [N]; `remove_unfiltered_items` RW boolean; `infinity_inventory_filters` RW array[InfinityInventoryFilter]
- Gui: `gui` R LuaGui; `opened_self` R boolean
- Other: `quick_bar_width` R uint8 [N]; `valid` R boolean; `object_name` R string
- Inherited character and control attributes apply (see section 2).

---

## 5. LuaSurface [C]

A surface is "uniquely identified by its name"; nauvis always exists. About 40 niche entries are omitted: prototype-specific create_entity extras, script areas and positions, and daytime/brightness details.

### 5.1 Entity placement and search
- `create_entity{name, position, direction?, mirror?, quality?, force?, target?, source?, cause?, snap_to_grid?, fast_replace?, undo_index?, player?, character?, spill?, raise_built?, create_build_effect_smoke?, spawn_decorations?, move_stuck_players?, item?, preserve_ghosts_and_corpses?, register_plant?, burner_fuel_inventory?} → LuaEntity?` [Q: `quality`, default `normal` per summary]. Type-specific extras keyed by prototype type [S].
- `can_place_entity{name, position, direction?, force?, build_check_type?, forced?, inner_name?} → boolean`
- `can_fast_replace{name, position, direction?, force?} → boolean`
- `entity_prototype_collides(prototype, position, use_map_generation_bounding_box, direction?) → boolean` [S]
- `find_entity(entity: EntityWithQualityID, position) → LuaEntity?` [Q]
- `find_entities(area?: BoundingBox) → array[LuaEntity]`: no area returns all.
- `find_entities_filtered(filter: EntitySearchFilters) → array[LuaEntity]`
- `count_entities_filtered(filter: EntitySearchFilters) → uint32`
- `find_tiles_filtered(filter: TileSearchFilters) → array[LuaTile]`
- `count_tiles_filtered(filter: TileSearchFilters) → uint32`
- `get_closest(position, entities) → LuaEntity?` [S]
- `get_entities_with_force(chunk_position, force) → array[LuaEntity]` [S]
- `find_non_colliding_position(name: EntityID, center: MapPosition, radius, precision, force_to_tile_center?) → MapPosition?`: radius 0 means unbounded; precision minimum 0.01 [S]
- `find_non_colliding_position_in_box(name, search_space: BoundingBox, precision, force_to_tile_center?) → MapPosition?` [S]
- `spill_item_stack{position, stack: ItemStackIdentification, enable_looted?, force?, allow_belts?, max_radius?, use_start_position_on_failure?, drop_full_stack?} → array[LuaEntity]`
- `spill_inventory{position, inventory: LuaInventory, ...same optional fields} → array[LuaEntity]`

### 5.2 Tiles
- `get_tile(x, y) → LuaTile`: takes two numbers, not a MapPosition.
- `set_tiles(tiles, correct_tiles?, remove_colliding_entities?, remove_colliding_decoratives?, raise_event?, player?, undo_index?)`
- `get_connected_tiles(position, tiles, include_diagonal?, area?) → array[TilePosition]`
- `get_hidden_tile(position) → string?`, `set_hidden_tile(position, tile?)`, `get_double_hidden_tile(position) → string`, `set_double_hidden_tile(position, tile?)`, `clear_hidden_tiles()`
- `build_checkerboard(area)`: sets lab tiles.
- `get_default_cover_tile(force, tile) → LuaTilePrototype?`, `set_default_cover_tile(force, from_tile, to_tile)`

### 5.3 Chunks and territories
- `get_chunks() → LuaChunkIterator`
- `is_chunk_generated(chunk_position) → boolean`
- `request_to_generate_chunks(position, radius?)`, `force_generate_chunk_requests()`
- `set_chunk_generated_status(chunk_position, status)`
- `delete_chunk(chunk_position)`
- `get_random_chunk() → ChunkPosition?`
- `get_territories() → array[LuaTerritory]`, `get_territory_for_chunk(chunk_position)`, `set_territory_for_chunks(chunk_positions, territory?)`, `clear_territory_for_chunks(chunk_positions)`, `create_territory{chunks, patrol_path?}` [S]

### 5.4 Pollution, combat, and units
- `get_pollution(position: MapPosition) → double`, `set_pollution(position, amount)`: amount must be ≥ 0. Bypasses statistics and evolution [S].
- `pollute(source, amount, prototype?)`, `clear_pollution()`, `get_total_pollution() → double`
- `find_enemy_units(center, radius, force?) → array[LuaEntity]` [S: default force is the player force]
- `find_units{area, force, condition} → array[LuaEntity]` [S: all three required]
- `find_nearest_enemy{position, max_distance, force?} → LuaEntity?` [S]
- `find_nearest_enemy_entity_with_owner{position, max_distance, force?} → LuaEntity` [S: no optional marker, though the text allows nil]
- `set_multi_command{command, unit_count, force?, unit_search_distance?} → uint32` [S]
- `create_unit_group{position, force?} → LuaCommandable`, `build_enemy_base(position, unit_count, force?)`
- `create_segmented_unit{name, quality?, force?, territory?} → LuaSegmentedUnit?` [Q]
- `get_segmented_units() → array[LuaSegmentedUnit]`

### 5.5 Logistics and paths
- `find_logistic_network_by_position(position, force) → LuaLogisticNetwork?`
- `find_closest_logistic_network_by_position(position, force)`
- `find_logistic_networks_by_construction_area(position, force) → array[LuaLogisticNetwork]`
- `request_path{bounding_box, collision_mask, start, goal, force, radius?, pathfind_flags?, can_open_gates?, path_resolution_modifier?, max_gap_size?, max_attack_distance?, entity_to_ignore?} → uint32` [S: returns an array of PathfinderWaypoints]

### 5.6 Construction orders
- `deconstruct_area{area, force, player?, skip_fog_of_war?, item?, super_forced?}`
- `cancel_deconstruct_area{area, force, player?, skip_fog_of_war?, item?, undo_index?, super_forced?}`
- `upgrade_area{area, force, player?, skip_fog_of_war?, item}`
- `cancel_upgrade_area{area, force, player?, skip_fog_of_war?, item}`

### 5.7 Decoratives and cloning
- `find_decoratives_filtered{area?, position?, name?, collision_mask?, from_layer?, to_layer?, exclude_soft?, limit?, invert?} → array[DecorativeResult]`
- `destroy_decoratives{...same}`, `create_decoratives{check_collision?, decoratives}`, `regenerate_entity(entities?, chunks?)`, `regenerate_decorative(decoratives?, chunks?)` [S]
- `clone_area{source_area, destination_area, destination_surface?, destination_force?, clone_tiles?, clone_entities?, clone_decoratives?, clear_destination_entities?, clear_destination_decoratives?, expand_map?, create_build_effect_smoke?}` [S]
- `clone_entities{entities, destination_offset, destination_surface?, destination_force?, snap_to_grid?, create_build_effect_smoke?}` [S]

### 5.8 Other methods
- `print(message, print_settings?)`, `play_sound(sound_specification)`, `play_music(music_specification)` [N]
- `get_resource_counts() → dictionary[string → uint32]`, `get_starting_area_radius() → double`, `get_map_exchange_string() → string`
- `calculate_tile_properties(property_names, positions) → dictionary[string → array[double]]` [S]
- `get_property(property) → double`, `set_property(property, value)` [S]
- `create_particle{...}`, `create_trivial_smoke{...}` [S]; `execute_lightning{name, position}` [S]
- `clear(ignore_characters?)`: deletes all entities and chunks [S]
- `create_entities_from_blueprint_string{...} → int32?`: simulations only [S]
- `create_global_electric_network()`, `destroy_global_electric_network()` [S]
- Script areas and positions: `get_script_areas(name?)`, `get_script_area(key?)`, `add_script_area(area) → uint32`, `edit_script_area(id, area)`, `remove_script_area(id)`, plus matching `*_script_position` functions [S]

### 5.9 Attributes (LuaSurface)
- `name` RW string; `index` R uint32; `valid` R boolean; `object_name` R string
- `map_gen_settings` RW MapGenSettings; `generate_with_lab_tiles` RW boolean (new chunks use lab tiles instead of map gen settings)
- `always_day` RW boolean; `daytime` RW double ([0, 1)); `darkness` R float; `freeze_daytime` RW boolean; `ticks_per_day` RW uint32; `dusk`, `dawn`, `evening`, `morning` RW double; `daytime_parameters` RW table
- `wind_speed` RW double; `wind_orientation` RW RealOrientation; `wind_orientation_change` RW double
- `peaceful_mode`, `no_enemies_mode`, `show_clouds` RW boolean; `ignore_surface_conditions` RW boolean [S]
- `solar_power_multiplier`, `min_brightness` RW double; `brightness_visual_weights` RW ColorModifier
- `has_global_electric_network` R boolean; `global_electric_network` R LuaElectricSubNetwork? [N]; `global_electric_network_statistics` R LuaFlowStatistics? [S]
- `global_effect` RW Effect? [C] [S]
- `pollutant_type` R LuaAirbornePollutantPrototype? [S]; `override_pollution_type` RW Pollutant? [N] [S]; `pollution_statistics` R LuaFlowStatistics [S]
- `localised_name` RW LocalisedString? [S]; `deletable` R boolean [S]
- `planet` R LuaPlanet? [S]; `platform` R LuaSpacePlatform? [S]

---

## 6. LuaForce [C]

The page marks the class changed. Forces number up to 64. Default forces are player, enemy and neutral. About 40 entries are omitted, including the full evolution, statistics and logistic-group sets. The final ~6.1k characters were not read.

### 6.1 Research and prototypes
- `add_research(technology) → boolean`, `cancel_current_research()`, `research_all_technologies(include_disabled_prototypes?)`, `script_trigger_research(technology)`, `reset_technologies()`, `reset_technology_effects()`, `reset_recipes()`, `reset()`
- `enable_research()`, `disable_research()`, `enable_all_prototypes()`, `disable_all_prototypes()`, `enable_all_recipes()`, `enable_all_technologies()`
- `get_hand_crafting_disabled_for_recipe(recipe) → boolean`, `set_hand_crafting_disabled_for_recipe(recipe, hand_crafting_disabled)` [S]
- `get_entity_count(name) → uint32` (counts entities of a type)
- `technologies`, `recipes` R LuaCustomTable [verbatim attribute]

### 6.2 Charting
- `chart(surface, area)`, `clear_chart(surface?)`, `rechart(surface?)`, `chart_all(surface?)`, `copy_chart(source_force, source_surface, destination_surface)`, `copy_from(force)`
- `is_chunk_charted(surface, chunk_position) → boolean`, `is_chunk_visible(...)`, `is_chunk_requested_for_charting(...)`, `unchart_chunk(chunk_position, surface)`, `cancel_charting(surface?)`, `get_chunk_chart(surface, chunk_position) → string?` [S]
- `add_chart_tag(surface, tag) → LuaCustomChartTag?`, `find_chart_tags(surface, area?) → array[LuaCustomChartTag]` [S]
- `find_logistic_network_by_position(position, surface) → LuaLogisticNetwork?` [S]

### 6.3 Surfaces and spawn
- `set_spawn_position(position, surface)`, `get_spawn_position(surface) → MapPosition`
- `set_surface_hidden(surface, hidden)`, `get_surface_hidden(surface) → boolean`
- `get_linked_inventory(prototype, link_id) → LuaInventory?` [S]

### 6.4 Modifiers and combat
- `get_ammo_damage_modifier(ammo) → double`, `set_ammo_damage_modifier(ammo, modifier)`
- `get_gun_speed_modifier(ammo) → double`, `set_gun_speed_modifier(ammo, modifier)`
- `get_turret_attack_modifier(turret) → double`, `set_turret_attack_modifier(turret, modifier)`
- `set_cease_fire(other, cease_fire)`, `get_cease_fire(other)`, `set_friend(other, friend)`, `get_friend(other)`, `is_friend(other)`, `is_enemy(other)` [S]
- `kill_all_units()`, `is_pathfinder_busy() → boolean` [S]

### 6.5 Evolution and statistics (summary)
- `get_evolution_factor(surface?)`, `get_evolution_factor_by_pollution`, `get_evolution_factor_by_time`, `get_evolution_factor_by_killing_spawners` → double
- `set_evolution_factor(factor, surface?)`, and the `_by_pollution`, `_by_time`, `_by_killing_spawners` variants [S]
- `reset_evolution()` [S]
- `get_item_production_statistics(surface)`, `get_fluid_production_statistics(surface)`, `get_kill_count_statistics(surface)`, `get_entity_build_count_statistics(surface)` → LuaFlowStatistics [S]
- Logistic groups: `get_logistic_groups(type?)`, `get_logistic_group(name, type?)`, `create_logistic_group(name, type?)`, `delete_logistic_group(name, type?)` [S]

### 6.6 Locks and visibility
- `lock_space_location(name)`, `unlock_space_location(name)`, `is_space_location_unlocked(name)` [S]
- `lock_quality(quality)`, `unlock_quality(quality)`, `is_quality_unlocked(quality)` [Q] [S]
- `is_visible(unlockable) → boolean` [N], `set_script_visible(unlockable, value?)` [N], `get_script_visible(unlockable) → boolean?` [N]: these take an UnlockableID [S].
- `lock_space_platforms()`, `unlock_space_platforms()`, `is_space_platforms_unlocked()` [S]
- `create_space_platform{name?, planet, starter_pack} → LuaSpacePlatform?` [S]
- `get_space_platforms(location) → array[LuaSpacePlatform]` [N] [S]

### 6.7 Alerts, printing, sound
- `add_alert(entity, type)`, `add_custom_alert(entity, icon, message, show_on_map)`, `remove_alert(filter)` (empty table removes all). The page flags these as new in the summary only [N] [S].
- `print(message, print_settings?)`, `play_sound(sound_specification)`, `play_music(music_specification)` [N]

### 6.8 Attributes (LuaForce)
- `name` R string
- `technologies`, `recipes` R LuaCustomTable
- `manual_mining_speed_modifier`, `manual_crafting_speed_modifier` RW double
- `laboratory_speed_modifier`, `laboratory_productivity_bonus` RW double (descriptions not read)
- Remaining attributes not read.

---

## 7. LuaInventory [C]

Inventories created by `LuaGameScript::create_inventory` can be resized or destroyed. About 6 niche entries are omitted.

### 7.1 Methods
- `clear()`
- `can_insert(items: ItemStackIdentification) → boolean`
- `insert(items: ItemStackIdentification) → uint32`
- `remove(items: ItemStackIdentification) → uint32`
- `transfer_from_stack(source: LuaItemStack) → uint32` [N]: source must not belong to this inventory.
- `transfer_from_inventory(source: LuaInventory, filter?: ItemFilter) → uint32` [N]: source must be a different inventory.
- `get_item_count(item?: ItemWithQualityID) → uint32` [Q]: no argument counts all items.
- `get_item_count_filtered(filter: ItemFilter) → uint32`
- `get_item_quality_counts(item?: ItemID) → dictionary[string → uint32]` [Q] [S]: aggregated by quality.
- `is_empty() → boolean`
- `is_full() → boolean` [S]: ignores bar-blocked stacks; may be true for machine inputs even when more fits.
- `get_contents() → array[ItemWithQualityCount]` [Q]
- `supports_bar() → boolean`, `get_bar() → uint32`, `set_bar(bar?: uint32)`: nil clears the limit [S].
- `supports_filters() → boolean`, `is_filtered() → boolean`
- `can_set_filter(index: uint32, filter: ItemFilter) → boolean`
- `get_filter(index: uint32) → ItemFilter?`
- `set_filter(index: uint32, filter: ItemFilter | nil) → boolean`: nil erases the filter. Some slots reject some filters (e.g., gun ammo slots reject non-ammo) [S].
- `find_item_stack(item: ItemWithQualityID) → LuaItemStack?, uint32?` [Q]
- `find_empty_stack(item?: ItemWithQualityID) → LuaItemStack?, uint32?` [Q]: with an item, includes empty slots that filter for that item [S].
- `count_empty_stacks(include_filtered?: boolean = false, include_bar?: boolean = true) → uint32` [S]
- `get_insertable_count(item: ItemWithQualityID) → uint32` [Q]: an estimate. Inaccurate for module slots, filtered machine slots, durability items and mixed-health items. Respects the bar [S].
- `sort_and_merge()`
- `resize(size: uint16)`: items beyond the new size are deleted; only for create_inventory inventories; raises `on_pre_script_inventory_resized`/`on_script_inventory_resized` [S]
- `destroy()`: only for create_inventory inventories [S]

### 7.2 Attributes and operators
- `index` R defines.inventory?; `name` R string?: matches defines.inventory keys
- `entity_owner` R LuaEntity?; `player_owner` R LuaPlayer?; `equipment_owner` R LuaEquipment?; `mod_owner` R string?
- `weight` R Weight: total weight of contents; `max_weight` R Weight?: only for InventoryWithWeightLimit [S]
- `valid` R boolean; `object_name` R string
- `[]` (index) → LuaItemStack; `#` (length) → uint32 (slot count)

---

## 8. LuaItemStack (extends LuaItemCommon)

### 8.1 Methods (LuaItemStack)
- `set_stack(stack?: ItemStackIdentification?) → boolean`; `can_set_stack(stack?) → boolean` (dry run)
- `transfer_stack(stack: ItemStackIdentification, amount?: uint32) → boolean`
- `swap_stack(stack: LuaItemStack) → boolean`
- `clear()`, `spoil()` [S]
- `add_ammo(amount: float)`, `drain_ammo(amount: float)`: ammo items only [S]
- `add_durability(amount: double)`, `drain_durability(amount: double)`: tool items only [S]
- `use_capsule(entity: LuaEntity, target_position: MapPosition) → array[LuaEntity]`
- `export_stack() → string`: blueprint, blueprint-book, deconstruction-planner, upgrade-planner or item-with-tags [S]
- `import_stack(data: string) → int32`: 0 success, -1 success with errors, 1 failure [S]
- `create_grid() → LuaEquipmentGrid`: item-with-entity-data only [S]

### 8.2 Attributes (LuaItemStack)
- `valid_for_read` R boolean
- `prototype` R LuaItemPrototype; `name` R string; `type` R string
- `count` RW uint32
- `health` RW float in [0, 1]
- `quality` R LuaQualityPrototype [Q]
- `spoil_tick` RW MapTick; `spoil_percent` RW double
- `item` R LuaItem? (extra data for items with data)
- `is_module` R boolean [S]
- `valid` R boolean; `object_name` R string

### 8.3 LuaItemCommon (inherited) [N/C]
Verbatim methods:
- `get_inventory(inventory) → LuaInventory?`, `clear_blueprint()`, `is_blueprint_setup() → boolean`
- `build_blueprint{surface, force, position, direction?, build_mode?, skip_fog_of_war?, by_player?, raise_built?} → array[LuaEntity]`
- `create_blueprint{surface, force, area, always_include_tiles?, include_entities?, include_modules?, include_station_names?, include_trains?, include_fuel?} → dictionary[uint32 → LuaEntity]`
- `get_blueprint_entities() → array[BlueprintEntity]?`, `set_blueprint_entities(entities, fix_positions?)` [C], `get_blueprint_entity_count() → uint32`
- `get_blueprint_tiles() → array[Tile]?`, `set_blueprint_tiles(tiles)`
- `get_blueprint_entity_tags(index) → Tags?`, `set_blueprint_entity_tags(index, tags)`, `get_blueprint_entity_tag(index, tag) → AnyBasic?`, `set_blueprint_entity_tag(index, tag, value)`
- `get_tag(tag_name) → AnyBasic?`, `set_tag(tag_name, tag)`
- Summary: `remove_tag(tag)`, `get_tag_names() → array[string]` [N], `get_entity_filter(index)`, `set_entity_filter(index, filter)`, `get_tile_filter(index)`, `set_tile_filter(index, filter)`, `deconstruct_area{...}`, `cancel_deconstruct_area{...}`, `clear_deconstruction_item()`, `clear_upgrade_item()`, `get_mapper(index, type)`, `set_mapper(index, type, mapper)` [S]

Summary-only attributes: `item_number` R uint64?; `cost_to_build` R array[ItemWithQualityCount] [Q]; `entity_filter_count`, `tile_filter_count`, `mapper_count` R uint32; `planner_description` RW string [N]; `durability` RW double; `ammo` RW uint32; `label` RW string?; `entity_label` RW string?; `tags` RW Tags; `blueprint_snap_to_grid`, `blueprint_position_relative_to_grid` RW TilePosition?; `entity_logistic_sections`, `entity_request_from_buffers`, `entity_logistics_enabled`, `entity_driver_is_gunner` RW [S].

---

## 9. LuaTrain (no class marker)

The verbatim page lists 15 methods and 17 attributes. The summary adds 12 attributes. About 3 niche entries are omitted.

### 9.1 Methods
- `get_item_count(item?) → uint32`: item type not shown in verbatim text; summary says ItemFilter [S].
- `get_contents() → array[ItemWithQualityCount]` [Q]
- `insert(stack: ItemStackIdentification)`: no return.
- `remove_item(stack: ItemStackIdentification) → uint32`: actual count removed.
- `clear_items_inside()`
- `get_fluid_count(fluid?) → double`, `get_fluid_contents() → dictionary[string → FluidAmount]`
- `insert_fluid(fluid) → double`, `remove_fluid(fluid) → double`, `clear_fluids_inside()`
- `recalculate_path(force?) → boolean`: force re-paths even if the current path is valid; returns whether a path exists afterward.
- `go_to_station(index: uint32)`: index into the schedule.
- `get_rails() → array[LuaEntity]`
- `get_rail_end(direction: defines.rail_direction) → LuaRailEnd`
- `get_schedule() → LuaSchedule`: full access including interrupts and groups.

### 9.2 Attributes
- `manual_mode` RW boolean: true means player or script controls the train.
- `speed` RW double: the page warns changing it is unsafe, since braking uses it.
- `max_forward_speed`, `max_backward_speed` R double: depend on locomotive and fuel.
- `weight` R double
- `carriages` R array[LuaEntity] (ordered from front); `locomotives` R table `{front_movers, back_movers}`; `cargo_wagons` R array[LuaEntity]; `fluid_wagons` R array[LuaEntity]
- `schedule` RW TrainSchedule? (simplified; excludes groups and interrupts; set nil to clear) [S for scope]
- `state` R defines.train_state
- `front_stock`, `back_stock` R LuaEntity?: the majority-facing end; ties favour North/West [S]
- `station` R LuaEntity?: stop the train is stopped at
- `has_path` R boolean; `path_end_rail` R LuaEntity?; `path_end_stop` R LuaEntity?
- `id` R uint32 [S]: unique train ID
- `passengers` R array[LuaPlayer] [S]: not indexed by player index
- `riding_state` R RidingState [S]
- `killed_players` R dictionary[uint32 → uint32] [S]; `kill_count` R uint32 [S]
- `path` R LuaRailPath? [S]; `signal` R LuaEntity? [S]
- `group` RW string [S]: setting it applies the group's schedule
- `front_end`, `back_end` R LuaRailEnd [S]
- `valid` R boolean; `object_name` R string

---

## 10. LuaTrainManager (no class marker)

The train manager holds all trains. There is exactly one instance per game, obtained from `LuaGameScript::train_manager`. It is always valid and equal to any other instance.

### 10.1 Methods
- `get_train_by_id(train_id: uint32) → LuaTrain?`: returns the train if found.
- `get_trains(filter: TrainFilter) → array[LuaTrain]`: trains passing the filter.
- `get_train_stops(filter: TrainStopFilter) → array[LuaEntity]`: train stops passing the filter.
- `request_train_path{type?, train?, goals, return_path?, starts?, search_direction?, in_chain_signal_section?, steps_limit?, shortest_path?} → TrainPathFinderOneGoalResult or TrainPathAllGoalsResult`

### 10.2 request_train_path parameters
| Field | Type | Notes |
|---|---|---|
| `type` | TrainPathRequestType? | Determines the return type. Defaults to `"path"`. |
| `train` | LuaTrain? | Required if `starts` is absent; otherwise optional. Selects the context for penalties and signal reacquisition. If `starts` is absent, front and back ends are taken from this train. |
| `goals` | array[TrainPathFinderGoal] | Required. |
| `return_path` | boolean? | Only for `"path"` requests. Defaults to false. Returning a path creates many LuaEntity objects, so it is expensive. |
| `starts` | array[RailEndStart]? | Manual start positions. |
| `search_direction` | `"respect-movement-direction"` or `"any-direction-with-locomotives"`? | Only used when `starts` is absent. Defaults to `"any-direction-with-locomotives"`. |
| `in_chain_signal_section` | boolean? | Defaults to false. If true, paths that cannot reserve their start immediately are rejected, since that could stop a train inside an intersection. |
| `steps_limit` | uint32? | Maximum pathfinder steps. |
| `shortest_path` | boolean? | Defaults to false. If true, only rail length counts as penalty. |

### 10.3 Attributes
- `valid` R boolean; `object_name` R string

The page's "Class used in" list names only `LuaGameScript::train_manager`. LuaGameScript was not read.

---

## 11. LuaGuiElement [C]

The class is marked changed. Access children with `parent.child` or `parent["child"]`. Accessing an attribute the element type lacks raises a runtime error. About 15 niche entries are omitted.

### 11.1 Methods
- `add{type, name?, caption?, tooltip?, elem_tooltip?, enabled?, visible?, locked?, ignored_by_interaction?, style?, tags?, index?, anchor?, game_controller_interaction?, raise_hover_events?} → LuaGuiElement` (type-specific keys are in 11.3) [S for per-type keys]
- `clear()`, `destroy()`
- `get_mod() → string?`: nil if owned by the scenario script
- `get_index_in_parent() → uint32`
- `swap_children(index_1: uint32, index_2: uint32)`
- Dropdown/listbox: `clear_items()`, `get_item(index) → LocalisedString`, `set_item(index, string)`, `add_item(string, index?)`, `remove_item(index)`
- Slider: `get_slider_minimum() → double`, `get_slider_maximum() → double`, `set_slider_minimum_maximum(minimum, maximum)` (minimum must be less than maximum [S]), `get_slider_value_step() → double`, `set_slider_value_step(value)`, `get_slider_discrete_values() → boolean`, `set_slider_discrete_values(value)`
- Focus and scroll: `focus()`, `scroll_to_top()`, `scroll_to_bottom()`, `scroll_to_left()`, `scroll_to_right()`, `scroll_to_element(element, scroll_mode?)` (scroll-pane) [S], `scroll_to_item(index, scroll_mode?)` (list-box) [S], `select_all()` and `select(start_index, end_index)` (textfield/text-box) [S]
- Tabs: `add_tab(tab, content)`, `remove_tab(tab?)` (nil removes all) [S]
- `force_auto_center()` (frames on screen) [S]; `bring_to_front()` (screen elements) [S]; `close_dropdown()` [S]

### 11.2 Attributes
- `index` R uint32; `gui` R LuaGui; `parent` R LuaGuiElement?; `player_index` R uint32; `type` R GuiElementType; `children` R array[LuaGuiElement]; `children_names` R array[string]
- `name` RW string; `caption` RW LocalisedString; `tooltip` RW LocalisedString; `elem_tooltip` RW ElemID?; `visible` RW boolean; `enabled` RW boolean; `ignored_by_interaction` RW boolean; `locked` RW boolean
- `style` RW LuaStyle or string (write accepts string only [S])
- `direction` R GuiDirection
- `text` RW string (textfield, text-box); `numeric`, `allow_decimal`, `allow_negative`, `is_password`, `lose_focus_on_confirm`, `word_wrap`, `read_only`, `selectable` RW boolean [S]; `icon_selector` R boolean (fixed at creation)
- `state` RW boolean (checkbox, radiobutton)
- `value` RW double (progressbar); `slider_value` RW double
- `sprite`, `hovered_sprite`, `clicked_sprite` RW SpritePath; `resize_to_sprite` RW boolean
- `number` RW double? (sprite-button bottom-right number); `secondary_number` RW double? [N] (number right side, above `number`); `show_percent_for_small_numbers` RW boolean
- `quality` R LuaQualityPrototype? | W QualityID? [Q]: sprite-button quality corner
- `items` RW array[LocalisedString]; `selected_index` RW uint32 (dropdown, listbox)
- `selected_tab_index` RW uint32?; `tabs` R array[TabAndContent]; `badge_text` RW LocalisedString
- `auto_toggle` RW boolean; `toggled` RW boolean (buttons)
- `mouse_button_filter` R ActiveMouseButtonFlags | W MouseButtonFlags [C]
- `horizontal_scroll_policy`, `vertical_scroll_policy` RW ScrollPolicy
- `elem_type` R ElemType; `elem_value` RW string | SignalID | PrototypeWithQuality? [Q]; `elem_filters` RW PrototypeFilter? (choose-elem-button)
- `column_count` R uint32 (table; fixed); `draw_vertical_lines`, `draw_horizontal_lines`, `draw_horizontal_line_after_headers`, `vertical_centering` RW boolean
- `position` RW MapPosition; `surface_index` RW uint32; `zoom` RW double; `minimap_player_index` RW uint32; `force` RW string?; `entity` RW LuaEntity? (camera, minimap, entity-preview); `location` RW GuiLocation?; `auto_center` RW boolean (frames); `game_controller_interaction` RW defines.game_controller_interaction; `raise_hover_events` RW boolean; `anchor` RW GuiAnchor?; `tags` RW Tags; `drag_target` RW LuaGuiElement?
- `switch_state` RW SwitchState; `allow_none_state` RW boolean; `left_label_caption`, `left_label_tooltip`, `right_label_caption`, `right_label_tooltip` RW LocalisedString
- `inventory` RW LuaInventory? [N]; `slots_per_row` RW uint8? [N]; `empty_slot_info` RW EmptySlotInfo? [N]; `handle_cursor_transfer`, `handle_cursor_split`, `handle_open_item`, `handle_open_mod_item`, `handle_send_stack_to_trash`, `handle_send_stacks_to_trash` RW boolean [N]
- `valid` R boolean; `object_name` R string

### 11.3 Add-spec defaults (summary) [S]
- Common: `enabled`, `visible` true; `locked`, `ignored_by_interaction`, `raise_hover_events` false; `game_controller_interaction` normal.
- `table`: `column_count` required; `vertical_centering` true.
- `checkbox`/`radiobutton`: `state` required.
- `sprite-button`: `quality` string? (name of quality shown) [Q]; `mouse_button_filter` "left-and-right".
- `choose-elem-button`: `elem_type` required; `item-with-quality`, `entity-with-quality`, `recipe-with-quality`, `equipment-with-quality` take PrototypeWithQuality [Q].
- `slider`: min 0, max 30, step 1.
- `camera`: zoom 0.75; `position` required.
- `inventory`: `slots_per_row`, `empty_slot_info`, and six `handle_*` flags [N].

---

## 12. LuaTile (no class marker; banner 2.1.23)

A tile is a single square. Verbatim content is complete.

### 12.1 Methods
- `collides_with(layer: CollisionLayerID) → boolean`
- `to_be_deconstructed(force?: ForceID) → boolean`: no force checks any force.
- `order_deconstruction(force: ForceID, player?: PlayerIdentification) → LuaEntity?`: returns the deconstructible tile proxy created, if any. Raises `on_marked_for_deconstruction`.
- `cancel_deconstruction(force: ForceID, player?: PlayerIdentification)`: raises `on_cancelled_deconstruction`.
- `has_tile_ghost(force?: ForceID) → boolean`
- `get_tile_ghosts(force?: ForceID) → array[LuaEntity]`

### 12.2 Attributes
- `name` R string (e.g. `"sand-3"`, `"grass-2"`)
- `prototype` R LuaTilePrototype
- `position` R TilePosition
- `hidden_tile` R string? (non-mineable or foundation tiles can become hidden in normal play; `LuaSurface.set_hidden_tile` bypasses that)
- `double_hidden_tile` R string? (non-mineable tiles only, normally)
- `surface` R LuaSurface
- `valid` R boolean; `object_name` R string

Classes that use LuaTile include LuaControl.mine_tile, LuaControl.opened, LuaItemCommon.set_tile_filter, LuaSurface.find_tiles_filtered, and LuaSurface.get_tile.

---

## 13. Cross-cutting highlights

### 13.1 New, changed, deprecated
- **Deprecated:** none marked on any page read.
- **[C] changed:** LuaEntity class; LuaEntity `active`, `minable`, `apply_upgrade`, `get_item_insert_specification`, `create_cargo_pod`, `add_autopilot_destination`; LuaEntity fluid getters/setters (`get_fluid_count`, `get_fluid`, `set_fluid`, `remove_fluid`, `insert_fluid`); LuaControl class and `opened`; LuaPlayer class, `add_pin`, `remove_alert`, `get_alerts`, `get_quick_bar_slot`, `set_quick_bar_slot`, `entity_copy_source`; LuaSurface class and `global_effect`; LuaForce class; LuaInventory class; LuaGuiElement class and `mouse_button_filter`; LuaItemCommon `set_blueprint_entities`.
- **[N] new (methods):** LuaEntity: `flip`, `get_signals_changed`, `clear_fluids`, `add_fluid`, `clear_fluid`, `extract_fluid`, the fluid-box and fluid-segment helpers, `get_fluid_capacity`, `get_fluid_filter`/`set_fluid_filter`, `clear_stored_durability`/`get/set_stored_durability` [S], and the tooltip-field family [S]. LuaPlayer: `get_pins`, `clear_pins`, `play_music`, `stack_transfers`, `cursor_transfer`, `cursor_split`. LuaForce: `play_music`, `is_visible`, `set_script_visible`, `get_script_visible`, `get_space_platforms`, `add_alert`, `add_custom_alert`, `remove_alert` [S for the last three]. LuaInventory: `transfer_from_stack`, `transfer_from_inventory`. LuaItemCommon: `get_tag_names`. LuaSurface: `play_music`, `override_pollution_type`, `global_electric_network` (new attribute).
- **[N] new (attributes):** LuaControl `mining_progress`; LuaEntity `protected`, `fluidbox_neighbours`, `underground_belt_neighbour`, `wall_neighbours`, `cliff_neighbours`, `neighbour_connectable_connections`; LuaPlayer `mining_progress`, `respawn_quality`, `disable_space_map`, `toggle_menu_leaves_remote_view`, `hide_locked_prototypes_in_factoriopedia`, `current_music`, `saved_logistic_filters`, `editor_settings`, `quick_bar_width`; LuaGuiElement `secondary_number`, plus the new `inventory`-element attributes listed in 11.2; LuaItemCommon `planner_description`.
- **Class-level flags:** LuaControl, LuaEntity, LuaPlayer, LuaSurface, LuaForce, LuaInventory, LuaGuiElement are marked changed. LuaItemStack, LuaTrain, LuaTrainManager and LuaTile are not.

### 13.2 Quality [Q]
- **Quality-aware IDs in inputs:** `LuaInventory.get_item_count`, `find_item_stack`, `find_empty_stack`, `get_insertable_count` take `ItemWithQualityID`. `EntitySearchFilters.has_item_inside` takes `ItemWithQualityID`, and `EntitySearchFilters.quality` takes `QualityCondition`. `LuaSurface.create_entity` takes `quality` (defaults to normal [S]). `LuaSurface.find_entity` takes `EntityWithQualityID` [S]. `LuaEntity.set_filter` takes `ItemWithQualityID` for logistic storage containers.
- **Quality-aware outputs:** `LuaInventory.get_contents`, `LuaTrain.get_contents`, `LuaEntity.copy_settings`, `revive`, `silent_revive`, `set_recipe`, `LuaPlayer.stack_transfers` return `ItemWithQualityCount` arrays. `LuaItemStack.quality` is a read-only LuaQualityPrototype. `LuaEntity.previous_recipe` returns RecipeIDAndQualityIDPair.
- **Quality readers:** `LuaEntity.get_recipe` returns the quality prototype; `LuaEntity.get_upgrade_target` returns the quality prototype [S].
- **Quality-aware methods:** `LuaEntity.get_electric_input_flow_limit(quality?)`, `get_electric_output_flow_limit(quality?)` [S]. `LuaPlayer.pipette(id, quality?, allow_ghost?)`. `LuaPlayer.cursor_ghost` reads ItemIDAndQualityIDPair and writes ItemWithQualityID.
- **Quality locks:** `LuaForce.lock_quality`, `unlock_quality`, `is_quality_unlocked` [S].
- **Quality on GUI:** `LuaGuiElement.quality` (read prototype, write QualityID), `sprite-button` add-spec `quality`, and the four `*-with-quality` choose-elem-button types.
- **Quality on respawn:** `LuaPlayer.respawn_quality` [N].
- **Quality on create_character:** takes EntityWithQualityID [S].
- **Quality on segmented units:** `create_segmented_unit{quality?}` [S].

### 13.3 Train manager and trains
- Access only through `LuaGameScript::train_manager` (not read). Always valid.
- Query: `get_train_by_id`, `get_trains(TrainFilter)`, `get_train_stops(TrainStopFilter)`.
- Pathfinding: `request_train_path` (section 10.2). Use `type` to pick the result shape. For `"path"` results, pass `return_path=true` to receive the path.
- Trains expose: `get_contents` (with quality), `insert`/`remove_item`/`insert_fluid`/`remove_fluid`, `go_to_station`, `recalculate_path`, `get_schedule` (full, including interrupts and groups), `schedule` (simplified, no groups or interrupts).
- Entity-to-train links: `LuaEntity.train`, `get_train_stop_trains`, `get_stopped_train`, `LuaTrain.station`, `path_end_stop`, `path_end_rail`.
- `LuaTrain.id` is a unique uint32 [S], and `get_train_by_id` searches by it.

### 13.4 find_entities_filtered
- Parameter: one EntitySearchFilters table (section 1.4). There is no separate surface parameter; call it on the LuaSurface.
- Returns array[LuaEntity] (uses `limit` if set [S]). Count variant returns uint32.
- `area`, `position`, `radius`: `position` has precedence over `area`; with `position`, `radius` gives a circular search.
- `name`, `type`, `ghost_name`, `ghost_type`: string/EntityID or array. An empty array matches nothing (not "everything").
- `force` takes a ForceSet; `collision_mask` takes one layer, an array, or a dictionary.
- `to_be_deconstructed`, `to_be_upgraded`, `is_military_target`: boolean filters.
- `invert`: inverts all filters.
- `quality` (QualityCondition) and `has_item_inside` (ItemWithQualityID): quality-aware.
- `find_tiles_filtered`/`count_tiles_filtered` take TileSearchFilters (not read).

### 13.5 Inventory and item quality
- Use `get_item_count(ItemWithQualityID)` to count a specific quality. Without an argument it counts all qualities.
- `get_item_quality_counts(item?)` returns counts per quality as a dictionary (summary says the argument is ItemID [S]).
- `get_contents()` returns quality-aware ItemWithQualityCount entries.
- `find_item_stack(ItemWithQualityID)` returns the first matching stack and an index.
- `find_empty_stack(item?)` with a quality includes empty slots filtered for that item.
- `get_insertable_count` is an estimate; avoid for module slots, filtered machine inputs, durability items and mixed-health stacks.
- `is_full()` ignores bar-blocked stacks.
- `count_empty_stacks(include_filtered, include_bar)`.
- Items can carry health (`LuaItemStack.health`, [0, 1]), durability, spoil_tick/spoil_percent, and ammo.
- `LuaInventory.transfer_from_stack` and `transfer_from_inventory` are new. Use them rather than manual insert/remove when moving between inventories.

### 13.6 Position formats
- **MapPosition:** `{x=, y=}` or `{x, y}`; reads are always tables; 1/256-tile precision.
- **BoundingBox:** `{left_top=, right_bottom=, orientation?}` or `{{x,y},{x,y}}`; the array form may carry orientation as a third element; orientation is read only when non-zero.
- **ChunkPosition:** `{x=, y=}` or `{x, y}` with integers; a chunk is a MapPosition divided by 32.
- **TilePosition:** not read. `LuaTile.position` returns it; `get_connected_tiles` returns an array of them.
- **LuaSurface.get_tile(x, y)** takes two numbers, not a MapPosition.
- **Teleport shorthand:** `LuaControl.teleport` treats one or two numbers as relative offsets [S].
- **Surface identification:** uint32 index (nauvis = 1), name string, or LuaSurface object (SurfaceIdentification).

### 13.7 Porting notes for stdlib2
- Expect fluid-API churn: many 2.1 fluid methods are new or changed, and `get_fluid_count`, `get_fluid`, `set_fluid`, `remove_fluid`, `insert_fluid` have new return types (FluidAmount or Fluid?).
- Expect quality to appear in any wrapper that handles item or entity identity. Items are now (name, quality) pairs in several outputs.
- `LuaInventory.get_item_count(item?)` requires quality-aware IDs where the old API accepted plain names.
- `find_entities_filtered` uses the same filter table for count and search. Treat empty arrays as no match.
- The stdlib2 position helpers should accept both MapPosition forms and both BoundingBox forms, and should normalise to the table form when reading.

---

## 14. Gaps and omissions

- **Not read (tails):** LuaForce's final 6,147 characters were not read at all. Its middle section is summary-only.
- **Summary-only (not verbatim):** the lower halves of LuaEntity, LuaSurface, LuaPlayer, LuaControl, LuaInventory, LuaItemStack (LuaItemCommon), LuaTrain and LuaGuiElement. Anything marked [S] comes from those summaries, not verbatim text.
- **Not fetched (linked types):** ItemFilter, ItemWithQualityID, ItemWithQualityCount, QualityID, QualityCondition, ItemStackDefinition, TilePosition, TileSearchFilters, TrainFilter, TrainStopFilter, TrainPathFinderGoal, TrainPathRequestType, RailEndStart, TrainPathFinderOneGoalResult, TrainPathAllGoalsResult, LuaGameScript, LuaLogisticNetwork, LuaRailEnd, LuaRailPath, LuaSchedule, TrainSchedule, Effect, UnlockableID, SpritePath, Tags, ModSetting, Weight, PipetteID, ForceSet and PlayerIdentification.
- **Not confirmed:** `LuaTrain.get_item_count` parameter type (summary: ItemFilter); `LuaInventory.get_item_quality_counts` parameter type (summary: ItemID); `LuaSurface.find_entity` entity type (summary: EntityWithQualityID); `remove_alert` new flag on LuaForce (summary).
- **Omitted for length:** about 60 LuaEntity niche entries; about 40 LuaSurface niche entries; about 40 LuaForce entries (evolution, statistics, logistic groups, and some lock/visibility helpers); about 6 LuaInventory niche entries; about 3 LuaTrain entries; about 15 LuaGuiElement entries.
- **Doc inconsistencies noted:** `LuaSurface.find_nearest_enemy_entity_with_owner` is declared non-optional but its text allows nil [S]. `LuaSurface.set_multi_command`'s text calls the parameter `count` while the signature says `unit_count` [S].
- **Version banners:** BoundingBox (2.1.21), ItemStackIdentification and LuaTile (2.1.23), SurfaceIdentification (2.1.14) differ from the rest (2.1.24). Check whether the signatures on those pages match 2.1.24 before relying on them.

---

## 15. URLs read

1. https://lua-api.factorio.com/latest/classes/LuaEntity.html
2. https://lua-api.factorio.com/latest/classes/LuaSurface.html
3. https://lua-api.factorio.com/latest/classes/LuaPlayer.html
4. https://lua-api.factorio.com/latest/classes/LuaControl.html
5. https://lua-api.factorio.com/latest/classes/LuaForce.html
6. https://lua-api.factorio.com/latest/classes/LuaInventory.html
7. https://lua-api.factorio.com/latest/classes/LuaItemStack.html
8. https://lua-api.factorio.com/latest/classes/LuaTrain.html
9. https://lua-api.factorio.com/latest/classes/LuaTrainManager.html
10. https://lua-api.factorio.com/latest/classes/LuaGuiElement.html
11. https://lua-api.factorio.com/latest/classes/LuaTile.html
12. https://lua-api.factorio.com/latest/concepts/MapPosition.html
13. https://lua-api.factorio.com/latest/concepts/BoundingBox.html
14. https://lua-api.factorio.com/latest/concepts/ChunkPosition.html
15. https://lua-api.factorio.com/latest/concepts/EntitySearchFilters.html
16. https://lua-api.factorio.com/latest/concepts/SurfaceIdentification.html
17. https://lua-api.factorio.com/latest/concepts/ItemStackIdentification.html

No file paths were produced; no files were written.