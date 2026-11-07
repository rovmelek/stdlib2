--- A small, deterministic stand-in for the parts of the Factorio 2.1 environment that stdlib2 uses.
-- It replaces the external `faketorio` package so that `busted` runs from a fresh clone.
-- The event list approximates `defines.events` of 2.1 (see doc/factorio-2.1/runtime-core.md); it is
-- not guaranteed to be complete, and specs must not depend on the exact count.
local Env = {}

local root = (debug.getinfo(1, 'S').source:match('^@(.*)spec/setup/factorio_env%.lua$')) or './'
if root == '' then root = './' end
Env.root = root

local event_names = [[
on_achievement_gained on_ai_command_completed on_area_cloned on_biter_base_built on_brush_cloned
on_build_base_arrived on_built_entity on_cancelled_deconstruction on_cancelled_upgrade on_character_corpse_expired
on_chart_tag_added on_chart_tag_modified on_chart_tag_removed on_chunk_charted on_chunk_deleted on_chunk_generated
on_combat_robot_expired on_console_chat on_console_command on_cutscene_cancelled on_cutscene_finished
on_cutscene_started on_cutscene_waypoint_reached on_entity_cloned on_entity_color_changed on_entity_damaged
on_entity_died on_entity_logistic_slot_changed on_entity_renamed on_entity_settings_pasted on_equipment_inserted
on_equipment_removed on_force_cease_fire_changed on_force_created on_force_friends_changed on_force_reset
on_forces_merged on_forces_merging on_game_created_from_scenario on_gui_checked_state_changed on_gui_click
on_gui_closed on_gui_confirmed on_gui_elem_changed on_gui_location_changed on_gui_opened
on_gui_selected_tab_changed on_gui_selection_state_changed on_gui_switch_state_changed on_gui_text_changed
on_gui_value_changed on_land_mine_armed on_lua_shortcut on_marked_for_deconstruction on_marked_for_upgrade
on_market_item_purchased on_object_destroyed on_player_alt_reverse_selected_area on_player_alt_selected_area
on_player_ammo_inventory_changed on_player_armor_inventory_changed on_player_banned on_player_built_tile
on_player_cancelled_crafting on_player_changed_force on_player_changed_position on_player_changed_surface
on_player_cheat_mode_disabled on_player_cheat_mode_enabled on_player_clicked_gps_tag on_player_configured_blueprint
on_player_configured_spider_remote on_player_crafted_item on_player_created on_player_cursor_stack_changed
on_player_deconstructed_area on_player_demoted on_player_died on_player_display_density_scale_changed
on_player_display_resolution_changed on_player_display_scale_changed on_player_driving_changed_state
on_player_dropped_item on_player_fast_transferred on_player_flipped_entity on_player_flushed_fluid
on_player_gun_inventory_changed on_player_input_method_changed on_player_joined_game on_player_kicked
on_player_left_game on_player_main_inventory_changed on_player_mined_entity on_player_mined_item
on_player_mined_tile on_player_muted on_player_pipette on_player_placed_equipment on_player_promoted
on_player_removed on_player_removed_equipment on_player_repaired_entity on_player_respawned
on_player_reverse_selected_area on_player_rotated_entity on_player_selected_area on_player_set_quick_bar_slot
on_player_setup_blueprint on_player_toggled_alt_mode on_player_toggled_map_editor on_player_trash_inventory_changed
on_player_unbanned on_player_unmuted on_player_used_capsule on_player_used_spider_remote on_post_entity_died
on_pre_build on_pre_chunk_deleted on_pre_entity_settings_pasted on_pre_ghost_deconstructed on_pre_ghost_upgraded
on_pre_surface_cleared on_pre_surface_deleted on_pre_player_crafted_item on_pre_player_died
on_pre_player_left_game on_pre_player_mined_item on_pre_player_removed on_pre_robot_exploded_cliff
on_pre_script_inventory_resized on_redo_applied on_research_cancelled on_research_finished
on_research_moved on_research_reversed on_research_started on_resource_depleted on_robot_built_entity
on_robot_built_tile on_robot_exploded_cliff on_robot_mined on_robot_mined_entity on_robot_mined_tile
on_robot_pre_mined on_rocket_launch_ordered on_rocket_launched on_runtime_mod_setting_changed
on_script_inventory_resized on_script_path_request_finished on_script_trigger_effect
on_sector_scanned on_segment_entity_created on_selected_area_changed on_singleplayer_init on_space_platform_built_entity
on_space_platform_built_tile on_space_platform_changed_state on_space_platform_mined_entity
on_space_platform_mined_item on_space_platform_mined_tile on_space_platform_pre_mined on_spider_command_completed
on_string_translated on_surface_cleared on_surface_created on_surface_deleted on_surface_imported
on_surface_renamed on_technology_effects_reset on_tick on_train_changed_state on_train_created
on_train_schedule_changed on_trigger_created_entity on_trigger_fired_artillery on_undo_applied
on_unit_added_to_group on_unit_group_created on_unit_group_finished_gathering on_unit_removed_from_group
on_worker_robot_expired on_blueprint_settings_pasted on_gui_inventory_action on_next_day_started
on_player_cancel_selected_area on_player_change_selected_area on_player_color_changed on_player_music_changed
on_player_start_selected_area on_player_super_forced_selected_area
script_raised_built script_raised_destroy script_raised_revive script_raised_set_tiles script_raised_teleported
]]

local inventory_names = [[
fuel burnt_result chest logistic_container_trash character_main character_guns character_ammo character_armor
character_vehicle character_trash god_main editor_main editor_guns editor_ammo editor_armor roboport_robot
roboport_material robot_cargo robot_repair assembling_machine_dump lab_input lab_modules lab_trash
mining_drill_modules item_main rocket_silo_rocket rocket_silo_trash rocket_silo_attached_cargo_unit cargo_unit
car_trunk car_ammo car_trash cargo_wagon turret_ammo beacon_modules character_corpse artillery_turret_ammo
artillery_wagon_ammo spider_trunk spider_ammo spider_trash hub_main hub_trash cargo_landing_pad_main
cargo_landing_pad_trash proxy_main agricultural_tower_input agricultural_tower_output agricultural_tower_modules
linked_container_main crafter_input crafter_output crafter_modules crafter_trash asteroid_collector_output
asteroid_collector_arm
]]

local direction_names = {
    'north', 'northnortheast', 'northeast', 'eastnortheast', 'east', 'eastsoutheast', 'southeast',
    'southsoutheast', 'south', 'southsouthwest', 'southwest', 'westsouthwest', 'west', 'westnorthwest',
    'northwest', 'northnorthwest'
}

local function sequence(str, first)
    local t, n = {}, first or 0
    for name in str:gmatch('%S+') do
        t[name] = n
        n = n + 1
    end
    return t
end

function Env.new_defines()
    local direction = {}
    for i, name in ipairs(direction_names) do direction[name] = i - 1 end
    return {
        events = sequence(event_names, 0),
        direction = direction,
        inventory = sequence(inventory_names, 1),
        wire_connector_id = sequence('circuit_red circuit_green combinator_input_red combinator_input_green combinator_output_red combinator_output_green pole_copper', 1),
        train_state = sequence('on_the_path path_lost no_schedule no_path arrive_signal wait_signal arrive_station wait_station manual_control_stop manual_control stop_for_auto_control', 0),
        controllers = sequence('ghost character god editor cutscene spectator remote', 0),
        constant = { default_icon_size = 64 },
    }
end

--- A tiny JSON encoder, deterministic (sorted keys); enough for `helpers.table_to_json`.
local function encode(v)
    local t = type(v)
    if t == 'table' then
        if next(v) == nil or #v > 0 then
            local out = {}
            for i = 1, #v do out[i] = encode(v[i]) end
            return '[' .. table.concat(out, ',') .. ']'
        end
        local keys = {}
        for k in pairs(v) do keys[#keys + 1] = tostring(k) end
        table.sort(keys)
        local out = {}
        for _, k in ipairs(keys) do
            local val = v[k]
            if val == nil then val = v[tonumber(k)] end
            out[#out + 1] = string.format('%q:%s', k, encode(val))
        end
        return '{' .. table.concat(out, ',') .. '}'
    elseif t == 'string' then
        return string.format('%q', v)
    end
    return tostring(v)
end
Env.encode_json = encode

local function compare_versions(a, b)
    local pa, pb = {}, {}
    for n in tostring(a):gmatch('%d+') do pa[#pa + 1] = tonumber(n) end
    for n in tostring(b):gmatch('%d+') do pb[#pb + 1] = tonumber(n) end
    for i = 1, math.max(#pa, #pb) do
        local x, y = pa[i] or 0, pb[i] or 0
        if x ~= y then return x < y and -1 or 1 end
    end
    return 0
end

local function new_script()
    local script = {
        mod_name = 'stdlib2',
        active_mods = { base = '2.1.0', stdlib2 = '2.1.0' },
        handlers = {}, nth_tick_handlers = {}, filters = {}, filter_calls = {},
        object_registrations = {}, next_event_id = 100000, next_registration = 0,
        bootstrap = {},
    }
    function script.on_event(id, f, filter)
        if type(id) == 'table' then
            for _, i in pairs(id) do script.on_event(i, f, filter) end
            return
        end
        script.handlers[id] = f
        if filter ~= nil then script.filters[id] = filter end
    end
    function script.set_event_filter(id, filter)
        script.filters[id] = filter
        script.filter_calls[#script.filter_calls + 1] = { id = id, filter = filter }
    end
    function script.get_event_filter(id) return script.filters[id] end
    function script.on_nth_tick(n, f) script.nth_tick_handlers[n] = f end
    function script.on_init(f) script.bootstrap.on_init = f end
    function script.on_load(f) script.bootstrap.on_load = f end
    function script.on_configuration_changed(f) script.bootstrap.on_configuration_changed = f end
    function script.get_event_handler(id) return script.handlers[id] end
    function script.get_event_order() return '' end
    function script.generate_event_name()
        script.next_event_id = script.next_event_id + 1
        return script.next_event_id
    end
    function script.raise_event(id, data)
        id = id or 0
        data = data or {}
        if type(id) == 'string' and script.bootstrap[id] then
            return script.bootstrap[id](data)
        end
        data.name = data.name or id
        local f = script.handlers[id]
        if f then f(data) end
    end
    function script.register_on_object_destroyed(object)
        script.next_registration = script.next_registration + 1
        script.object_registrations[script.next_registration] = object
        return script.next_registration, object.unit_number
    end
    return script
end

local function new_helpers(files)
    local helpers = { stage = 'runtime', files = files }
    function helpers.write_file(name, data, append) files[name] = (append and files[name] or '') .. data end
    function helpers.remove_path(path)
        for name in pairs(files) do
            if name == path or name:sub(1, #path + 1) == path .. '/' then files[name] = nil end
        end
    end
    function helpers.table_to_json(t) return encode(t) end
    return helpers
end

--- Create a `game` stub.
-- @tparam[opt] table opts `{players, forces, surfaces, trains}`
function Env.new_game(opts)
    opts = opts or {}
    local game = {
        tick = 0, players = opts.players or {}, forces = opts.forces or {}, surfaces = opts.surfaces or {},
        connected_players = {}, printed = {}, pollution = {}, entities_by_unit_number = {},
    }
    function game.get_player(i) return game.players[i] end
    function game.print(msg) game.printed[#game.printed + 1] = msg end
    function game.get_pollution_statistics(surface)
        return game.pollution[surface] or { input_counts = {}, output_counts = {} }
    end
    function game.get_entity_by_unit_number(n) return game.entities_by_unit_number[n] end
    game.train_manager = {
        trains = opts.trains or {}, calls = {},
        get_trains = function(filter)
            local m = game.train_manager
            m.calls[#m.calls + 1] = filter
            local out = {}
            for _, train in ipairs(m.trains) do
                local ok = true
                if filter then
                    if filter.surface and train.surface ~= filter.surface then ok = false end
                    if filter.force and train.force ~= filter.force then ok = false end
                    if filter.is_moving ~= nil and train.is_moving ~= filter.is_moving then ok = false end
                end
                if ok then out[#out + 1] = train end
            end
            return out
        end,
    }
    return game
end

function Env.install_searchers()
    if not package.__factorio_env_installed then
        package.__factorio_env_installed = true
        table.insert(package.searchers or package.loaders, 2, function(name)
            local path = name:match('^__stdlib2__/(.*)$')
            if path then
                local file = Env.root .. path .. '.lua'
                local f = loadfile(file)
                if f then return f, file end
                return '\n\tno repo file ' .. file
            end
        end)
    end
    local keep = {}
    for k in pairs(package.loaded) do keep[k] = true end
    Env.initial_loaded = Env.initial_loaded or keep
    --- Clear every stdlib module from package.loaded so the next require reloads it.
    function package.remove_stdlib()
        for k in pairs(package.loaded) do
            if tostring(k):find('__stdlib2__', 1, true) or tostring(k):find('stdlib', 1, true) then
                package.loaded[k] = nil
            end
        end
    end
end

--- Install fresh globals. Safe to call repeatedly (each call resets the stubs).
function Env.install(opts)
    opts = opts or {}
    Env.install_searchers()
    package.remove_stdlib()
    local files = {}
    _G.defines = Env.new_defines()
    _G.script = new_script()
    _G.helpers = new_helpers(files)
    _G.helpers.compare_versions = compare_versions
    _G.game = Env.new_game(opts.game)
    _G.storage = {}
    _G.remote = { interfaces = {}, add_interface = function(n, i) _G.remote.interfaces[n] = i end }
    Env.logs = {}
    _G.log = function(msg) Env.logs[#Env.logs + 1] = tostring(msg) end
    _G.serpent = require('__stdlib2__/stdlib/vendor/serpent')
    -- Factorio's built-in table_size
    _G.table_size = function(t)
        local n = 0
        for _ in pairs(t) do n = n + 1 end
        return n
    end
    _G.data, _G.mods, _G.settings = nil, nil, nil
    Env.files = files
    return Env
end

--- Fire the registered `on_init` handler (faketorio's `World.init`).
function Env.init()
    if _G.script.bootstrap.on_init then _G.script.bootstrap.on_init() end
end

--- Add `count` fake connected players to the game.
function Env.create_players(count)
    for n = 1, count do
        local player = { index = n, name = 'player' .. n, valid = true, connected = true, __self = true, printed = {} }
        function player.print(msg) player.printed[#player.printed + 1] = msg end
        _G.game.players[n] = player
        _G.game.connected_players[#_G.game.connected_players + 1] = player
    end
end

--- A table that looks like a LuaObject to code that checks `__self` and `valid`.
function Env.fake_userdata()
    return { __self = true, valid = true }
end

--- Mimic faketorio's `World.bootstrap()` for the control stage.
function Env.bootstrap(opts)
    Env.install(opts)
    return Env
end

return Env
