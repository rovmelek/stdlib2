# Prototype (data stage) API (2.1.24)

Condensed from https://lua-api.factorio.com/latest/index-prototype.html, prototypes.html,
types.html and the pages for PrototypeBase, ItemPrototype, RecipePrototype, TechnologyPrototype,
FluidPrototype, EntityPrototype, ItemGroup, ItemSubGroup, RecipeCategory, IngredientPrototype,
ProductPrototype, ItemProductPrototype, FluidProductPrototype, IconData, TechnologyUnit, Modifier,
PipeConnectionDefinition, Sprite, LocalisedString, Data, ModSetting.
**(new)**/**(changed)** = badge on the site. *[unverified]* = from a partial page read.

## Data-stage model
- Globals: `data` (Data), `mods` (name -> version), `settings` (startup values), `feature_flags`
  (flag -> bool), `helpers` (LuaHelpers), `defines`.
- `data.raw[type][name]` holds every prototype; `data:extend({proto, ...})` adds them (each needs
  `type` and `name`). Example: `data.raw["item"]["coal"].stack_size = 1000`.
- Validated at end of prototype stage; unknown properties are ignored.
- Every concrete prototype: `Prototype` << `PrototypeBase`. Abstract classes have no type string.
- Setting prototypes (`bool-setting` etc.) are not on prototypes.html; see `wiki-modding.md`.

### PrototypeBase / Prototype fields
`type`, `name` (req; <=200 chars), `order` (default ""), `localised_name`,
`localised_description`, `factoriopedia_description`, `factoriopedia_simulation`, `subgroup`,
`hidden` (false), `hidden_in_factoriopedia` (= hidden), `parameter` (false),
`custom_tooltip_fields`, `factoriopedia_alternative`.
In settings/data stage, locale keys and plain strings are limited to 200 chars, and every
LocalisedString parameter must be a string.

## Highest-impact changes for stdlib2 data helpers

| Area | 2.1.24 shape | stdlib2 status |
|---|---|---|
| Recipe difficulty | **no `normal` / `expensive`**; only `ingredients`, `results`, `main_product` | `stdlib/data/recipe.lua` still branches on `self.normal`/`expensive` and `get_difficulties` |
| Recipe results | `results` array of `{type, name, amount}`; no `result`/`result_count` | `recipe.lua` `format(ingredient, result_count)`, `modules/util.lua` `proto.result` |
| Recipe category | **`categories` (new)**: array[RecipeCategoryID], default `{"crafting"}` *[unverified whether singular `category` is still accepted]* | `recipe.lua`, `modules/recipe.txt` use `category` |
| Item fuel | **`fuel_categories` (new)**: array, required (>=1) when `fuel_value` is nonzero *[unverified whether `fuel_category` remains]* | check `item.lua` |
| Ingredients | always `{type="item"|"fluid", name, amount}` tables; item names unique | `recipe.lua` shorthand conversion |
| Icons | `icon_size` default 64; `icons` cannot be empty | `modules/sprites.lua`, `data.lua` |
| Group lists | `rail-category` no longer a prototype type | `modules/groups.lua` lists it |

## ItemPrototype ('item') (changed)
- Required: `stack_size`.
- Icons: `icons` (non-empty array[IconData]) or `icon` + `icon_size`; `dark_background_icon(s)`,
  `dark_background_icon_size`; `pictures`.
- Placement: `place_result`, `place_as_tile`, `place_as_equipment_result`, `plant_result`.
- Fuel: `fuel_value`, **`fuel_categories` (new)**, `burnt_result`, `fuel_acceleration_multiplier`,
  `fuel_top_speed_multiplier`, `fuel_emissions_multiplier`, `fuel_glow_color`,
  `*_quality_bonus` variants.
- Spoil (Space Age, loaded only if `spoil_ticks > 0`): `spoil_ticks`, `spoil_result`,
  `spoil_to_trigger_result`, `spoil_level`, `spoil_quality_change/min/max`,
  `quality_affects_spoil_ticks`.
- Misc: `weight` (else derived from recipes, see auxiliary item weight), `ingredient_to_weight_coefficient`,
  `flags`, `has_random_tint`, `random_tint_color`, `color_hint`, `destroyed_by_dropping_trigger`,
  `rocket_launch_products`, `send_to_orbit_mode`, `moved_to_hub_when_building`,
  `default_import_location`, `auto_recycle`; sounds `open_sound`, `close_sound`, `pick_sound`,
  `drop_sound`, `inventory_move_sound`.
- New *[unverified]*: `space_platform_request_priority`, `lab_ignores_spoil_percent`, `science_capacity`.
- Item subtypes: ammo, capsule, gun, item-with-entity-data, item-with-label, item-with-inventory,
  blueprint-book, item-with-tags, selection-tool, blueprint, copy-paste-tool, deconstruction-item,
  spidertron-remote, upgrade-item, module, rail-planner, space-platform-starter-pack, tool, armor,
  repair-tool.

## RecipePrototype ('recipe') (changed)
```lua
{
  type = "recipe", name = "my-recipe",
  categories = {"crafting"},            -- new; default {"crafting"}
  energy_required = 0.5,                -- default 0.5, > 0.001
  enabled = false,                      -- default true
  ingredients = {
    {type = "item",  name = "steel-plate", amount = 8},
    {type = "fluid", name = "water",       amount = 50},
  },
  results = {
    {type = "item", name = "my-item", amount = 1},
  },
  main_product = "my-item",             -- optional
}
```
- `ingredients`/`results` optional (empty allowed). The "crafting" category cannot have fluids.
- Other fields *[mostly unverified defaults]*: `icon`/`icons`/`icon_size`, `hidden`,
  `hide_from_player_crafting`, `hide_from_signal_gui`, `hide_from_stats`, `hide_from_bonus_gui`,
  `allow_decomposition` (true), `allow_as_intermediate`, `allow_intermediates`,
  `always_show_made_in`, `emissions_multiplier` (1), `maximum_productivity` (3.0),
  `overload_multiplier` (0), `allow_inserter_overload` (true), `requester_paste_multiplier` (30),
  `allowed_module_categories`, `crafting_machine_tint`, `surface_conditions`,
  `alternative_unlock_methods`, `auto_recycle`, `preserve_products_in_machine_output`,
  `unlock_results`, `allow_consumption/speed/productivity/pollution/quality` (+ `_message`).
- New: `categories`, `can_set_quality`, `raise_on_crafted` (raises RecipeCraftedEvent),
  `requires_ingredients_to_unlock_results`, `recycle_to_ingredients_of`, `sort_item_ingredients`.
- If `main_product` is set, subgroup/name/icon default from it; `""` forces the recipe's own.

### ItemProductPrototype (type "item") (changed)
`name` (req); `amount` (uint16) **or** `amount_min` + `amount_max`; `probability`;
`ignored_by_stats` (0), `ignored_by_productivity` (= ignored_by_stats), `extra_count_fraction` (0),
`percent_spoiled` (0, [0,1)). New: `always_fresh`, `reset_freshness_on_craft`, `quality_min`,
`quality_max`, `quality_change` (int8), `affected_by_quality` (true), and from
ProductPrototypeBase `independent_probability`, `shared_probability`,
`show_details_in_recipe_tooltip`.

### FluidProductPrototype (type "fluid") (changed)
`name`; `amount` or `amount_min`+`amount_max`; `ignored_by_stats`, `ignored_by_productivity`,
`temperature`, `fluidbox_index` (1-based, 0 = any). New: `fluidbox_multiplier` (3, >=1),
`optional_fluidbox_indexes`. No quality fields.

## TechnologyPrototype ('technology')
Fields: `icons` / `icon` (required if no icons) + `icon_size` (base uses 256), `upgrade`,
`enabled` (true), `essential`, `visible_when_disabled`, `ignore_tech_cost_multiplier`,
`allows_productivity` (true), `prerequisites` (array[TechnologyID]), `effects` (array[Modifier]),
`max_level` (uint32 or `"infinite"`), `show_levels_info`, and exactly one of:
- `unit` (TechnologyUnit): `count` (uint64 > 0) **or** `count_formula` (MathExpression, `L` =
  level; e.g. `"2500*(L - 3)"`), `time` (seconds), `ingredients` (array[ResearchIngredient],
  e.g. `{"automation-science-pack", 1}`).
- `research_trigger` (TechnologyTrigger): automatic unlock, mandatory if `unit` absent.
A trailing `-<number>` in the name sets the level and is ignored for locale.

Modifier `type`s (changed): inserter-stack-size-bonus, bulk-inserter-capacity-bonus,
laboratory-speed, character-logistic-trash-slots, maximum-following-robots-count,
worker-robot-speed, worker-robot-storage, turret-attack, ammo-damage, give-item, gun-speed,
unlock-recipe, character-crafting-speed, character-mining-speed, character-running-speed,
character-build-distance, character-item-drop-distance, character-reach-distance,
character-resource-reach-distance, character-item-pickup-distance,
character-loot-pickup-distance, character-inventory-slots-bonus, deconstruction-time-to-live,
max-failed-attempts-per-tick-per-construction-queue,
max-successful-attempts-per-tick-per-construction-queue, character-health-bonus,
mining-drill-productivity-bonus, train-braking-force-bonus, worker-robot-battery,
laboratory-productivity, follower-robot-lifetime, artillery-range, nothing,
character-logistic-requests, vehicle-logistics, unlock-space-location, unlock-quality,
unlock-space-platforms, unlock-travel-to-space-platforms, unlock-circuit-network,
cargo-landing-pad-count, max-cargo-bay-unloading-distance, change-recipe-productivity,
cliff-deconstruction-enabled, mining-with-fluid, rail-support-on-deep-oil-ocean,
rail-planner-allow-elevated-rails, beacon-distribution, create-ghost-on-entity-death,
belt-stack-size-bonus, unlock-logistic-network. (`unlock-recipe` uses `recipe = "<name>"`.)

## FluidPrototype ('fluid') (changed)
Required: `default_temperature` (< `max_temperature`), `base_color`, `flow_color`.
Optional: `icons`/`icon`/`icon_size`, `visualization_color`, `max_temperature`, `heat_capacity`
("1kJ"), `fuel_value` ("0J"), `emissions_multiplier` (1), `gas_temperature`, `auto_barrel` (true,
read by base mod), `hidden`. New: `draw_as_glow`, `spent_fluid`.

## EntityPrototype (abstract) (changed), partial
`icons`/`icon`/`icon_size`, `collision_box`, `collision_mask` (CollisionMaskConnector; defaults per
type from UtilityConstants), `map_generator_bounding_box`, `selection_box`,
`drawing_box_vertical_extension`, `sticker_box`, `hit_visualization_box`, `trigger_target_mask`,
`flags`, `tile_buildability_rules`, `minable` (MinableProperties, `results` array or
`result`), *[unverified]* `placeable_by`, `remains_when_mined`, `deconstruction_alternative`,
`next_upgrade`, `surface_conditions`, `heating_energy`, new `ghost_build_sound`, `tall`,
`show_fluid_visualization_when_in_cursor`. `max_health` is on EntityWithHealthPrototype.
Machines gained `module_slots`, `quality_affects_module_slots`, `allowed_effects`,
`allowed_module_categories`, `effect_receiver`.

## ItemGroup / ItemSubGroup / RecipeCategory
- `item-group`: max 255; `icons`/`icon` (mandatory if no icons)/`icon_size` (base uses 128),
  `order_in_recipe` (used with `sort_item_ingredients`). Built-ins: logistics, production,
  intermediate-products, combat.
- `item-subgroup`: required `group` (ItemGroupID).
- `recipe-category`: only `type`, `name`.

## Icons and sprites
**IconData**: `icon` (req), `icon_size` (64), `tint` ({1,1,1,1}), `shift` (px, from center),
`scale` (default `(expected_icon_size/2)/icon_size`), `draw_background` (true for first layer),
`floating` (false). Later layers draw on top. Expected sizes: 512 starmap icons, 256 technology,
128 achievement and item-group, 32/24 shortcut icons/small_icons, 64 everything else.
`defines.constant.default_icon_size` exists at runtime.

**Sprite**: `layers` (overrides everything), `filename` (req without layers), `size` or
`width`+`height`, `x`, `y`, `position`, `scale`, `shift`, `tint`, `blend_mode`, `priority`,
`flags`, `mipmap_count`, one of `draw_as_shadow`/`draw_as_glow`/`draw_as_light`,
`color_channels` (new), `dice`/`dice_x`/`dice_y`.

## PipeConnectionDefinition (changed)
`flow_direction` ("input-output" | "input" | "output"), `connection_type` ("normal" |
"underground" | "linked"), `direction` (defines.direction), `position` or `positions` (4),
new `alt_position`/`alt_direction`, `connection_category` (string|array, "default"),
`max_underground_distance`, `max_distance_tint`, `underground_collision_mask`,
`linked_connection_id`, `enable_working_visualisations`, new `hide_connection_info`.
Relevant to `stdlib/data/modules/pipes.lua`.

## Quality fields (where they live)
Items: fuel quality bonuses, spoil quality fields. Item products: `quality_min/max/change`,
`affected_by_quality`. Recipes: `can_set_quality`, `allow_quality`. Machines:
`quality_affects_module_slots`. Not on technology, fluid, item-group, subgroup, recipe-category.

## Prototype type names
**Data/misc:** achievement (+ ~30 `*-achievement` subtypes), chain-active-trigger,
delayed-active-trigger, airborne-pollutant, ammo-category, asteroid-chunk, autoplace-control,
burner-usage, collision-layer, custom-event, custom-input, damage-type, optimized-decorative,
optimized-particle, fluid, fuel-category, item-group, item-subgroup, mod-data, module-category,
noise-expression, noise-function, procession-layer-inheritance-group, procession, quality,
recipe-category, recipe, resource-category, shortcut, space-connection, space-location, planet,
surface-property, surface, technology, tile, tile-effect, trivial-smoke, virtual-signal,
tips-and-tricks-item, tips-and-tricks-item-category, tutorial, utility-constants, utility-sounds,
utility-sprites, gui-style, map-gen-presets, map-settings, mouse-cursor, font, sound, sprite,
animation, ambient-sound, editor-controller, god-controller, remote-controller,
spectator-controller, impact-category, deliver-category, deliver-impact-combination,
trigger-target-type.

**Equipment:** equipment-category, equipment-grid, active-defense-equipment, battery-equipment,
belt-immunity-equipment, electric-energy-interface-equipment (new), energy-shield-equipment,
equipment-ghost, generator-equipment, inventory-bonus-equipment, movement-bonus-equipment,
night-vision-equipment, roboport-equipment, solar-panel-equipment.

**Entities:** arrow, artillery-flare, artillery-projectile, beam, character-corpse, cliff, corpse,
rail-remnants, deconstructible-tile-proxy, entity-ghost, accumulator, agricultural-tower,
artillery-turret, asteroid-collector, asteroid, beacon, boiler, burner-generator, cargo-bay,
cargo-landing-pad, cargo-pod, character, arithmetic-combinator, decider-combinator,
selector-combinator, constant-combinator, container, logistic-container, infinity-container,
temporary-container, assembling-machine, rocket-silo, furnace, display-panel,
electric-energy-interface, electric-pole, unit-spawner, capture-robot, combat-robot,
construction-robot, logistic-robot, fusion-generator, fusion-reactor, gate, generator,
heat-interface, heat-pipe, inserter, lab, lamp, land-mine, lightning-attractor, linked-container,
market, mining-drill, offshore-pump, pipe, infinity-pipe, pipe-to-ground, player-port
(deprecated), power-switch, programmable-speaker, proxy-container, pump, radar, curved-rail-a,
elevated-curved-rail-a, curved-rail-b, elevated-curved-rail-b, half-diagonal-rail,
elevated-half-diagonal-rail, legacy-curved-rail, legacy-straight-rail, rail-ramp, straight-rail,
elevated-straight-rail, rail-chain-signal, rail-signal, rail-support, reactor, roboport, segment,
segmented-unit, simple-entity-with-owner, simple-entity-with-force, solar-panel,
space-platform-hub, spider-leg, spider-unit, storage-tank, thruster, train-stop, lane-splitter,
linked-belt, loader-1x1, loader, splitter, transport-belt, underground-belt, ammo-turret,
electric-turret, fluid-turret, unit, valve, car, artillery-wagon, cargo-wagon,
infinity-cargo-wagon, fluid-wagon, locomotive, spider-vehicle, wall, fish, simple-entity, tree,
plant, resource, explosion, fire, stream, highlight-box, item-entity, item-request-proxy,
lightning, particle-source, projectile, rocket-silo-rocket, rocket-silo-rocket-shadow,
smoke-with-trigger, speech-bubble, sticker, tile-ghost.

Class/type-string mismatches: DecorativePrototype = `optimized-decorative`, ParticlePrototype =
`optimized-particle`, EnemySpawnerPrototype = `unit-spawner`, FluidStreamPrototype = `stream`,
Loader1x2Prototype = `loader`, FireFlamePrototype = `fire`.
