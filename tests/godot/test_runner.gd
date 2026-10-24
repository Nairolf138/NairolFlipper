extends SceneTree

const CueDefinitionResource = preload("res://scripts/show/cue_definition.gd")
const CueManagerNode = preload("res://scripts/show/cue_manager.gd")
const FlowManagerNode = preload("res://scripts/show/flow_manager.gd")
const PhysicsTuningResource = preload("res://scripts/gameplay/physics_tuning.gd")
const MainNode = preload("res://scripts/app/main.gd")
const SettingsStoreNode = preload("res://scripts/app/settings_store.gd")
const ShowFlowManagerNode = preload("res://scripts/show/show_flow_manager.gd")
const SyncBonusManagerNode = preload("res://scripts/show/sync_bonus_manager.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if "--scan-routes" in OS.get_cmdline_user_args():
		for action in [&"flipper_left", &"flipper_right"]:
			for distance in range(75, 166, 5):
				print("AIM ", action, " ", distance, " ", await _sample_cradle_shot(action, float(distance), true))
		quit(0)
		return
	if "--routes-only" in OS.get_cmdline_user_args():
		await _test_physical_routes()
		await _test_route_isolation_and_lifecycle()
		await _test_routes_from_flippers()
		_finish()
		return
	_test_flow_decay_and_multiplier()
	_test_cue_stack_progression()
	_test_show_flow_state_machine()
	_test_sync_bonus_timing()
	_test_audio_settings_persistence()
	await _test_main_scene_scoring_and_reset()
	await _test_physics_drain_lifecycle()
	await _test_android_playtest_regressions()
	await _test_three_ball_game_over_and_recovery()
	await _test_table_2_objectives_and_routes()
	await _test_playfield_safe_trajectories()
	await _test_weighted_pinball_feel()
	await _test_final_show_multiball_and_blackout()
	await _test_stage_identity_and_music_stems()
	await _test_stagecraft_visual_language()
	await _test_sync_bonus_integration()
	await _test_audio_settings_menu()
	await _test_flashing_effects_accessibility()
	await _test_how_to_play_menu()
	await _test_alpha_candidate_player_journey()
	await _test_guided_launcher_and_go()
	await _test_flipper_return_control()
	await _test_rolling_dynamics()
	await _test_flipper_motor_and_cradle_shots()
	await _test_physical_routes()
	await _test_route_isolation_and_lifecycle()
	await _test_routes_from_flippers()
	# Give the audio server and deferred frees time to release stream references.
	await process_frame
	await process_frame

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("Godot behavioral tests: %s passed" % ("routes" if "--routes-only" in OS.get_cmdline_user_args() else "27"))
		quit(0)
		return

	for failure in _failures:
		printerr("FAILED: %s" % failure)
	printerr("Godot behavioral tests: %d failure(s)" % _failures.size())
	quit(1)


func _test_physical_routes() -> void:
	for route_name in ["WarmRamp", "ColdRamp", "UniverseOrbit"]:
		var directions := [1, -1] if route_name == "UniverseOrbit" else [1]
		for direction in directions:
			var speeds := [1800.0, 2000.0] if route_name == "UniverseOrbit" else [1700.0, 2100.0]
			for speed in speeds:
				var result := await _sample_physical_route(route_name, direction, speed)
				_expect(result.entered and result.contacted, "Real ball enters and contacts route rails (%s/%d/%.0f): %s" % [route_name, direction, speed, result])
				_expect_equal(result.completed, 1, "Complete route awards exactly once (%s/%d/%.0f): %s" % [route_name, direction, speed, result])
				_expect(result.restored and not result.recovered, "Route exit restores the deck without a safety recovery (%s): %s" % [route_name, result])
				_expect(result.returned, "Route output can be played back with a real flipper (%s/%d): %s" % [route_name, direction, result])
	for route_name in ["WarmRamp", "ColdRamp"]:
		var weak := await _sample_physical_route(route_name, 1, 650.0, false)
		_expect(weak.entered and weak.rolled_back and not weak.recovered, "Weak ramp shot rolls back through its mouth (%s): %s" % [route_name, weak])
		_expect_equal(weak.completed, 0, "An incomplete ramp cannot advance a cue (%s)" % route_name)


func _sample_physical_route(route_name: String, direction: int, speed: float, play_return: bool = true) -> Dictionary:
	Input.action_release(&"flipper_left")
	Input.action_release(&"flipper_right")
	var scene := load("res://scenes/app/Main.tscn") as PackedScene
	var main := scene.instantiate()
	main.ball_recovery_delay = 60.0
	root.add_child(main)
	await physics_frame
	main.start_game()
	main.session_state = MainNode.SessionState.PLAYING
	var route: Node2D = main.get_node(route_name + "/PhysicalRoute")
	var line: PackedVector2Array = route.centerline
	var endpoint: int = route.entry_index if direction == 1 else route.reverse_entry_index
	var tangent: Vector2 = route._endpoint_tangent(endpoint) * float(direction)
	var ball: RigidBody2D = main.balls[0]
	var start := route.to_global(line[endpoint]) - tangent * 80.0
	ball.reset_ball(start, false)
	await physics_frame
	await physics_frame
	ball.launch_ready = false
	ball.ball_save_used = true
	ball.freeze = false
	ball.linear_velocity = tangent * speed
	var counts := {"completed": 0}
	route.traversed.connect(func(_ball: RigidBody2D) -> void: counts.completed += 1)
	var entered := false
	var contacted := false
	var rolled_back := false
	var restored := false
	var recovered := false
	# A repeatable ramp return can be anticipated, caught, then replayed.
	var output_index := line.size() - 1 if direction == 1 else 0
	var output_action: StringName = &"flipper_left" if route.to_global(line[output_index]).x < 540.0 else &"flipper_right"
	if play_return:
		Input.action_press(output_action)
	for frame in 1200:
		await physics_frame
		entered = entered or ball.route_owner == route
		if ball.route_owner == route:
			for body in ball.get_colliding_bodies():
				if body.get_parent() == route:
					contacted = true
		if "--trace-routes" in OS.get_cmdline_user_args() and frame % 60 == 0:
			print("ROUTE ", route_name, " ", direction, " ", speed, " f=", frame, " p=", ball.global_position, " v=", ball.linear_velocity, " riding=", ball.route_owner == route, " count=", counts.completed)
		if entered and ball.route_owner == null:
			rolled_back = counts.completed == 0
			recovered = ball.launch_ready or ball.freeze
			restored = ball.collision_layer == 1 and ball.collision_mask == 1 and ball.z_index == 0
			break
	var returned := false
	if play_return and counts.completed == 1:
		var played := await _play_physical_return(main, ball, &"", 1200)
		returned = played.returned
	var result := {"entered": entered, "contacted": contacted, "completed": counts.completed, "restored": restored, "rolled_back": rolled_back, "returned": returned, "recovered": recovered, "end": ball.global_position}
	Input.action_release(&"flipper_left")
	Input.action_release(&"flipper_right")
	main.free()
	await process_frame
	return result


func _test_route_isolation_and_lifecycle() -> void:
	var scene := load("res://scenes/app/Main.tscn") as PackedScene
	var main := scene.instantiate()
	main.ball_recovery_delay = 60.0
	root.add_child(main)
	await physics_frame
	main.start_game()
	main.session_state = MainNode.SessionState.PLAYING
	var warm: Node2D = main.get_node("WarmRamp/PhysicalRoute")
	var cold: Node2D = main.get_node("ColdRamp/PhysicalRoute")
	var counts := {"warm": 0, "cold": 0, "orbit": 0}
	var completed_balls: Array[int] = []
	warm.traversed.connect(func(_ball: RigidBody2D) -> void: counts.warm += 1)
	warm.traversed.connect(func(rider: RigidBody2D) -> void: completed_balls.append(rider.get_instance_id()))
	cold.traversed.connect(func(_ball: RigidBody2D) -> void: counts.cold += 1)
	main.get_node("UniverseOrbit/PhysicalRoute").traversed.connect(func(_ball: RigidBody2D) -> void: counts.orbit += 1)
	var ball: RigidBody2D = main.balls[0]
	# Cross under a raised track, without ever passing its entry gate.
	ball.reset_ball(Vector2(270, 930), false)
	await physics_frame
	await physics_frame
	ball.launch_ready = false
	ball.ball_save_used = true
	ball.freeze = false
	ball.linear_velocity = Vector2(800, 0)
	for _frame in 24:
		await physics_frame
	_expect(ball.route_owner == null and ball.collision_mask == 1, "Crossing a track sideways stays on the base deck")
	_expect_equal(counts, {"warm": 0, "cold": 0, "orbit": 0}, "Underpasses and side touches cannot score routes")
	ball.reset_ball(Vector2(350, 1070), false)
	await physics_frame
	await physics_frame
	ball.launch_ready = false
	ball.freeze = false
	ball.linear_velocity = Vector2(0, 600)
	for _frame in 24:
		await physics_frame
	_expect(ball.route_owner == null, "Crossing a ramp entrance backwards cannot board its track")
	_expect_equal(counts.warm, 0, "A backwards mouth crossing cannot award a ramp")

	# Two balls may use the same ramp while a third uses the other one.
	for index in 3:
		var rider: RigidBody2D = main.balls[index]
		var route: Node2D = warm if index < 2 else cold
		var start: Vector2 = route.to_global(route.centerline[route.entry_index]) - route._endpoint_tangent(route.entry_index) * float(35 + (100 if index == 1 else 0))
		rider.reset_ball(start, false)
		rider.ball_save_used = true
	await physics_frame
	await physics_frame
	for index in main.balls.size():
		var rider: RigidBody2D = main.balls[index]
		rider.launch_ready = false
		rider.freeze = false
		var route: Node2D = warm if index < 2 else cold
		rider.linear_velocity = route._endpoint_tangent(route.entry_index) * (1772.0 if index == 1 else 1700.0)
	var simultaneous := false
	var base_leak := false
	for _frame in 840:
		await physics_frame
		if main.balls[0].route_owner == warm and main.balls[1].route_owner == warm and main.balls[2].route_owner == cold:
			simultaneous = true
		for rider in main.balls:
			if rider.route_owner != null and rider.collision_layer == 1:
				base_leak = true
		if counts.warm >= 2 and counts.cold >= 1:
			break
	_expect(simultaneous and not base_leak, "Three physical balls keep independent route ownership and planes")
	_expect(counts.warm >= 1 and counts.warm <= 2, "Concurrent balls may complete or roll back, without phantom awards")
	var unique_ids: Dictionary = {}
	for identity in completed_balls:
		unique_ids[identity] = true
	_expect_equal(completed_balls.size(), unique_ids.size(), "Each concurrent ball scores at most one full traversal")
	_expect_equal(counts.cold, 1, "A third ball completes the opposite ramp concurrently")
	_expect_equal(counts.orbit, 0, "Overlapping route drawings do not award unrelated orbit passes")
	_expect(main.cue_manager.current_cue_ready(), "Physical Warm and Cold completions arm Color Wash through scene signals")

	main.restart_game()
	main.session_state = MainNode.SessionState.PLAYING
	ball.reset_ball(Vector2(350, 1145), false)
	await physics_frame
	await physics_frame
	ball.launch_ready = false
	ball.freeze = false
	ball.linear_velocity = Vector2(0, -1800)
	for _frame in 30:
		await physics_frame
		if ball.route_owner == warm:
			break
	_expect(ball.route_owner == warm, "Reset fixture starts with a real ball riding a ramp")
	main.restart_game()
	var before_reset: Dictionary = counts.duplicate()
	_expect(ball.route_owner == null and ball.collision_layer == 1 and ball.collision_mask == 1 and ball.z_index == 0, "Restart restores route collision and drawing state")
	for _frame in 60:
		await physics_frame
	_expect_equal(counts, before_reset, "An interrupted traversal cannot complete later after restart")
	_expect_equal(main.score_manager.score, 0, "Restart clears all route awards")
	_expect_equal(main.remaining_balls, 3, "Route cancellation preserves the three-ball session")
	main.session_state = MainNode.SessionState.PLAYING
	ball.reset_ball(Vector2(350, 1145), false)
	await physics_frame
	await physics_frame
	ball.launch_ready = false
	ball.freeze = false
	ball.linear_velocity = Vector2(0, -1800)
	for _frame in 30:
		await physics_frame
		if ball.route_owner == warm:
			break
	_expect(ball.route_owner == warm, "Menu fixture starts with a ball riding a ramp")
	main._show_start_menu()
	_expect(ball.route_owner == null and not ball.visible and ball.collision_layer == 1, "Returning to menu cancels and hides a routed ball")
	main.free()
	await process_frame


func _test_routes_from_flippers() -> void:
	for action in [&"flipper_left", &"flipper_right"]:
		for orbit in [true, false]:
			var distances := [74.0, 78.0, 82.0, 86.0] if orbit else [145.0, 147.0, 150.0]
			var expected := "UniverseOrbit" if orbit else ("ColdRamp" if action == &"flipper_left" else "WarmRamp")
			var completed := false
			var samples: Array[Dictionary] = []
			for distance in distances:
				var result := await _sample_cradle_shot(action, distance, true)
				samples.append(result)
				_expect(result.held and result.shot, "A route attempt starts from a physically held and released ball")
				if result.routes == [expected]:
					completed = true
					break
			_expect(completed, "Timed physical flipper shots can complete the aimed route (%s/%s): %s" % [action, expected, samples])


func _test_flow_decay_and_multiplier() -> void:
	var flow := FlowManagerNode.new()
	flow.decay_per_second = 8.0
	flow.add_flow(100)
	_expect_equal(flow.multiplier, 2, "Flow reaches x2 at 100 points")
	flow.decay_flow(0.5)
	_expect_equal(flow.flow_points, 96, "Flow decays by four points over half a second")
	flow.decay_flow(0.5)
	_expect_equal(flow.flow_points, 92, "Flow decay remains frame-rate independent")
	flow.free()


func _test_cue_stack_progression() -> void:
	var manager := CueManagerNode.new()
	var color_cue := CueDefinitionResource.new()
	color_cue.cue_id = &"color_wash"
	color_cue.conditions = [&"warm_ramp", &"cold_ramp"]
	color_cue.bonus_points = 250
	var orbit_cue := CueDefinitionResource.new()
	orbit_cue.cue_id = &"universe_chase"
	orbit_cue.conditions = [&"universe_orbit"]
	orbit_cue.condition_repetitions = 2
	manager.cues = [color_cue, orbit_cue]

	var awarded_points: Array[int] = []
	manager.bonus_awarded.connect(func(points: int) -> void: awarded_points.append(points))
	manager.add_condition(&"warm_ramp")
	_expect(not manager.current_cue_ready(), "Color cue waits for both ramps")
	manager.add_condition(&"cold_ramp")
	_expect(manager.current_cue_ready(), "Color cue arms after both distinct ramps")
	_expect(manager.start_current_cue(), "Console can run the armed color cue")
	_expect(manager.complete_current_cue(), "Active cue completes")
	_expect_equal(awarded_points, [250], "Cue completion emits its configured bonus")
	_expect_equal(manager.current_cue_index, 1, "Cue Stack advances to its second cue")

	manager.add_condition(&"universe_orbit")
	_expect(not manager.current_cue_ready(), "Universe Chase requires two orbit shots")
	manager.add_condition(&"universe_orbit")
	_expect(manager.current_cue_ready(), "Repeated shots can arm a Cue Stack step")
	_expect(manager.start_current_cue(), "Console runs the second armed cue")
	_expect(manager.complete_current_cue(), "Second cue completes")
	_expect(manager.is_stack_completed(), "Completing every cue closes the stack")

	manager.reset_state()
	_expect(manager.active_cue == null, "Cue reset clears the active cue")
	_expect_equal(manager.current_cue_index, 0, "Cue reset returns to the first cue")
	_expect(not manager.start_current_cue(), "Cue reset clears shot progress")
	manager.free()


func _test_show_flow_state_machine() -> void:
	var show := ShowFlowManagerNode.new()
	_expect_equal(show.state, ShowFlowManagerNode.State.STANDBY, "Show starts in Standby")
	show.reset_show()
	_expect_equal(show.state, ShowFlowManagerNode.State.PRESET, "A new session enters Preset")
	_expect(show.begin_build(), "The first launch enters Build")
	_expect(not show.start_final_show(), "Final Show cannot start before the Rig is ready")
	_expect(show.arm_final_show(), "Completing the Rig enters Flow")
	_expect(show.start_final_show(), "An armed show starts Final Show")
	_expect(show.start_blackout(), "Final Show ends in Blackout")
	_expect(show.final_show_completed, "Blackout records Final Show completion")
	_expect(show.finish_blackout(), "Blackout returns to Flow")
	_expect(not show.start_final_show(), "Final Show cannot repeat in the same session")
	show.reset_show()
	_expect(not show.final_show_completed, "A restart clears Final Show completion")
	show.free()


func _test_sync_bonus_timing() -> void:
	var sync := SyncBonusManagerNode.new()
	var awarded_tiers: Array[StringName] = []
	sync.sync_awarded.connect(
		func(tier: StringName, _score: int, _flow: int, _distance: float) -> void:
			awarded_tiers.append(tier)
	)

	_expect(sync.register_hit(4.05), "A hit close to the pulse earns Sync")
	_expect_equal(awarded_tiers, [&"perfect"], "The tight timing window earns Perfect Sync")
	_expect(not sync.register_hit(4.10), "Only one award is granted on the same pulse")
	_expect(not sync.register_hit(4.50), "An off-beat hit receives no bonus and no penalty")
	_expect(sync.register_hit(5.22), "The forgiving outer window earns regular Sync")
	_expect_equal(awarded_tiers, [&"perfect", &"sync"], "Both Sync tiers are distinguishable")
	_expect(not sync.register_hit(6.02, false), "A stopped transport cannot award Sync")
	sync.reset_state()
	_expect_equal(sync.awards, 0, "Reset clears the session Sync counter")
	_expect(sync.register_hit(6.02), "Reset re-opens the timing window")
	sync.free()


func _test_audio_settings_persistence() -> void:
	var save_path := "user://tests/audio_settings_store.json"
	_remove_test_file(save_path)
	var settings := SettingsStoreNode.new()
	settings.save_path = save_path
	_expect(not settings.load_settings(), "Missing audio settings use safe defaults")
	_expect_equal(settings.master_percent, 100.0, "Master defaults to 100 percent")
	_expect_equal(settings.flashing_effects, &"full", "Flashing effects default to Full")
	settings.set_audio_levels(65.0, 40.0, 0.0, false)
	_expect(settings.set_flashing_effects(&"reduced"), "Audio and visual settings can be persisted locally")

	var reloaded := SettingsStoreNode.new()
	reloaded.save_path = save_path
	_expect(reloaded.load_settings(), "Persisted audio settings can be loaded")
	_expect_equal(reloaded.master_percent, 65.0, "Master volume survives a reload")
	_expect_equal(reloaded.music_percent, 40.0, "Music volume survives a reload")
	_expect_equal(reloaded.sfx_percent, 0.0, "Muted SFX survive a reload")
	_expect_equal(reloaded.flashing_effects, &"reduced", "Reduced flashing survives a reload")
	reloaded.set_flashing_effects(&"invalid", false)
	_expect_equal(reloaded.flashing_effects, &"full", "Invalid flashing values fall back to Full")
	_expect(is_equal_approx(SettingsStoreNode.percent_to_db(0.0), -60.0), "Zero percent maps to silence")
	_expect(
		is_equal_approx(SettingsStoreNode.percent_to_db(50.0), linear_to_db(0.5)),
		"Percent levels use a perceptual audio conversion"
	)
	var legacy_file := FileAccess.open(save_path, FileAccess.WRITE)
	_expect(legacy_file != null, "Legacy settings fixture can be written")
	if legacy_file != null:
		legacy_file.store_string(JSON.stringify({
			"schema_version": 1,
			"audio": {
				"master_percent": 55.0,
				"music_percent": 45.0,
				"sfx_percent": 35.0,
			},
		}))
		legacy_file.close()
	var legacy := SettingsStoreNode.new()
	legacy.save_path = save_path
	_expect(legacy.load_settings(), "Version 1 audio settings remain compatible")
	_expect_equal(legacy.master_percent, 55.0, "Legacy audio values survive the schema migration")
	_expect_equal(legacy.flashing_effects, &"full", "Legacy saves receive the safe visual default")
	settings.free()
	reloaded.free()
	legacy.free()
	_remove_test_file(save_path)


func _test_main_scene_scoring_and_reset() -> void:
	var packed_scene := load("res://scenes/app/Main.tscn") as PackedScene
	_expect(packed_scene != null, "Main scene loads")
	if packed_scene == null:
		return

	var main := packed_scene.instantiate()
	root.add_child(main)
	await process_frame

	main.flow_manager.add_flow(100)
	main._on_bumper_hit(10, &"test_bumper")
	_expect_equal(main.score_manager.score, 20, "Flow multiplier applies to gameplay score")

	main.cue_manager.add_condition(&"warm_ramp")
	main.cue_manager.add_condition(&"cold_ramp")
	_expect(main.cue_manager.start_current_cue(), "Configured first Cue Stack step starts")
	main.cue_manager.complete_current_cue()
	_expect_equal(main.score_manager.score, 2020, "Cue bonus reaches ScoreManager with Flow multiplier")

	_expect(main.rig_model.activate_family(&"front_wash"), "Rig family activates")
	main.audio_service.set_stem_level(&"piano", 1.0)
	main.audio_service.seek_transport(4.0)
	main.audio_service.start_transport()
	main.restart_game()

	_expect_equal(main.score_manager.score, 0, "Restart resets score")
	_expect_equal(main.flow_manager.flow_points, 0, "Restart resets Flow")
	_expect_equal(main.flow_manager.multiplier, 1, "Restart resets multiplier")
	_expect(main.cue_manager.active_cue == null, "Restart clears the active cue")
	_expect_equal(main.cue_manager.current_cue_index, 0, "Restart rewinds the Cue Stack")
	_expect(not main.cue_manager.start_current_cue(), "Restart clears cue shot progress")
	_expect(not main.rig_model.is_family_active(&"front_wash"), "Restart resets Rig state")
	_expect(main.audio_service.stem_levels.is_empty(), "Restart clears stem state")
	_expect(not main.audio_service.transport_playing, "Restart stops music transport")
	_expect_equal(main.audio_service.transport_position_beats, 0.0, "Restart rewinds music transport")
	_expect(main.balls[0].visible, "Restart shows the first ball")
	_expect(not main.balls[1].visible and not main.balls[2].visible, "Restart hides inactive balls")

	main.free()
	await process_frame


func _test_physics_drain_lifecycle() -> void:
	var packed_scene := load("res://scenes/app/Main.tscn") as PackedScene
	_expect(packed_scene != null, "Main scene loads for the drain test")
	if packed_scene == null:
		return

	var main := packed_scene.instantiate()
	main.respawn_delay = 0.01
	root.add_child(main)
	await process_frame
	await physics_frame
	main.start_game()
	await process_frame

	var ball: RigidBody2D = main.balls[0]
	main._launch_or_restart()
	ball.global_position = Vector2(540, 1840)
	ball.linear_velocity = Vector2(0, 600)
	for frame in 120:
		if main.playtest_recorder.ball_saves == 1:
			break
		await physics_frame

	_expect_equal(main.playtest_recorder.ball_saves, 1, "Early physical drain records one ball save")
	_expect_equal(main.remaining_balls, 3, "Ball save preserves the ball count")
	_expect(ball.freeze and ball.launch_ready, "Ball save safely resets the rigid body")
	_expect_equal(ball.global_position, ball.spawn_position, "Saved ball returns to its spawn position")

	# Let the Area2D register that the reset ball left the drain before entering
	# it again with an expired safety window.
	await physics_frame
	await physics_frame
	main._launch_or_restart()
	_expect_equal(ball.ball_save_remaining, 0.0, "Safety is only armed once per numbered ball")
	ball.ball_save_remaining = 0.0
	ball.global_position = Vector2(540, 1840)
	ball.linear_velocity = Vector2(0, 600)
	for frame in 120:
		if main.playtest_recorder.drains == 1:
			break
		await physics_frame

	_expect_equal(main.playtest_recorder.drains, 1, "Expired safety records one physical drain")
	_expect_equal(main.remaining_balls, 2, "Physical drain consumes one ball")
	_expect(ball.freeze and not ball.visible, "Drained rigid body is frozen and hidden")

	for frame in 30:
		if main.balls[1].visible and main.balls[1].launch_ready:
			break
		await physics_frame
	_expect(main.balls[1].visible and main.balls[1].launch_ready, "Next ball respawns after a physical drain")

	main.free()
	await process_frame


func _test_android_playtest_regressions() -> void:
	var packed_scene := load("res://scenes/app/Main.tscn") as PackedScene
	_expect(packed_scene != null, "Main scene loads for Android playtest regressions")
	if packed_scene == null:
		return

	var main := packed_scene.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame

	_expect(main.start_overlay.visible, "Start menu is visible on launch")
	_expect(not main.gameplay_active, "Gameplay waits for the Play button")
	main.start_game()
	_expect(not main.start_overlay.visible and main.game_controls.visible, "Play starts the game and shows session controls")

	var left_flipper: Node2D = main.get_node("LeftFlipper")
	var right_flipper: Node2D = main.get_node("RightFlipper")
	_expect(is_equal_approx(rad_to_deg(left_flipper.rotation), 20.0), "Left flipper has the correct resting angle (got %.2f)" % rad_to_deg(left_flipper.rotation))
	_expect(is_equal_approx(rad_to_deg(right_flipper.rotation), -20.0), "Right flipper mirrors the left resting angle (got %.2f)" % rad_to_deg(right_flipper.rotation))

	Input.action_press(&"flipper_left")
	for _frame in 12:
		await physics_frame
	Input.action_release(&"flipper_left")
	_expect(rad_to_deg(left_flipper.rotation) < 0.0, "Left flipper moves upward when activated")
	_expect_equal(main.audio_service.last_sfx_id, &"flipper", "Flipper activation requests audible feedback")

	Input.action_press(&"flipper_right")
	for frame in 12:
		await physics_frame
	Input.action_release(&"flipper_right")
	_expect(rad_to_deg(right_flipper.rotation) > 0.0, "Right flipper moves upward when activated")

	var ball: RigidBody2D = main.balls[0]
	var start_position := ball.global_position
	main._launch_or_restart()
	_expect_equal(main.audio_service.last_sfx_id, &"launcher", "Launcher requests audible feedback")
	var minimum_x := start_position.x
	var minimum_y := start_position.y
	for frame in 240:
		await physics_frame
		minimum_x = minf(minimum_x, ball.global_position.x)
		minimum_y = minf(minimum_y, ball.global_position.y)
	_expect(minimum_y < start_position.y - 300.0, "Launcher sends the ball upward")
	_expect(minimum_x < start_position.x - 60.0, "Launcher feeds the ball left into the playfield")

	main.score_manager.add_points(100)
	main._on_reset_pressed()
	_expect_equal(main.score_manager.score, 0, "Reset button starts a clean game")

	main.free()
	await process_frame


func _test_three_ball_game_over_and_recovery() -> void:
	var packed_scene := load("res://scenes/app/Main.tscn") as PackedScene
	_expect(packed_scene != null, "Main scene loads for session lifecycle regressions")
	if packed_scene == null:
		return

	var main := packed_scene.instantiate()
	main.respawn_delay = 0.01
	root.add_child(main)
	await process_frame
	await physics_frame
	main.start_game()
	main.score_manager.add_points(321)
	await process_frame

	for drain_index in 3:
		var ball: RigidBody2D = main.balls[main.active_ball_index]
		ball.ball_save_used = true
		main._launch_or_restart()
		main._resolve_ball_drain(ball)
		await process_frame
		if drain_index < 2:
			for _frame in 20:
				if main.balls[main.active_ball_index].visible and main.balls[main.active_ball_index].launch_ready:
					break
				await physics_frame

	_expect_equal(main.remaining_balls, 0, "Exactly three consumed balls end the game")
	_expect(main.game_over, "Third drain marks the session as game over")
	_expect(not main.gameplay_active, "Game over blocks table input")
	_expect(main.game_over_overlay.visible, "Game over displays a dedicated overlay")
	_expect(not main.game_controls.visible, "Session controls hide behind the game over overlay")
	_expect_equal(main.final_score_label.text, "SCORE FINAL 000321", "Game over preserves and displays the final score")
	for ball in main.balls:
		_expect(not ball.visible, "Game over hides every ball")
		_expect(ball.get_node("CollisionShape2D").disabled, "Game over disables every ball collision")

	var ended_ball_index: int = main.active_ball_index
	main._launch_or_restart()
	_expect_equal(main.remaining_balls, 0, "Table touches cannot silently restart after game over")
	_expect_equal(main.active_ball_index, ended_ball_index, "Game over cannot create a phantom fourth ball")

	main.start_game()
	await process_frame
	await physics_frame
	_expect_equal(main.remaining_balls, 3, "Replay starts a fresh three-ball session")
	_expect(not main.game_over_overlay.visible, "Replay closes the game over overlay")
	_expect(main.balls[0].visible, "Replay activates the first ball")
	_expect(not main.balls[1].visible and not main.balls[2].visible, "Replay keeps inactive balls hidden")
	_expect(
		main.balls[1].get_node("CollisionShape2D").disabled
		and main.balls[2].get_node("CollisionShape2D").disabled,
		"Inactive balls cannot collide or escape into a corner"
	)

	var recovered_ball: RigidBody2D = main.balls[0]
	recovered_ball.ball_save_used = true
	main._launch_or_restart()
	recovered_ball.global_position = Vector2(-200, 1000)
	main._physics_process(0.1)
	await process_frame
	_expect_equal(main.remaining_balls, 3, "Out-of-bounds recovery does not consume a ball")
	_expect(recovered_ball.freeze and recovered_ball.launch_ready, "Out-of-bounds ball returns ready to the launcher")
	_expect_equal(recovered_ball.global_position, recovered_ball.spawn_position, "Recovered ball returns to the configured launcher")
	_expect(main.status_label.text.begins_with("BILLE RÉCUPÉRÉE"), "Recovery explains how to relaunch")

	main.free()
	await process_frame


func _test_table_2_objectives_and_routes() -> void:
	var packed_scene := load("res://scenes/app/Main.tscn") as PackedScene
	_expect(packed_scene != null, "Table 2.0 main scene loads")
	if packed_scene == null:
		return

	var main := packed_scene.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	main.start_game()
	await process_frame
	main._launch_or_restart()

	var rig_targets := main.get_tree().get_nodes_in_group("rig_targets")
	_expect_equal(rig_targets.size(), 6, "Table 2.0 exposes six readable Rig targets")
	_expect(main.get_node("UniverseOrbit") != null, "Table 2.0 exposes the Universe Orbit")
	_expect(main.get_node("LeftSlingshot") != null and main.get_node("RightSlingshot") != null, "Table 2.0 exposes two active slingshots")
	_expect(main.get_node("LeftOutlaneRail") is StaticBody2D, "Table 2.0 left outlane has physical guidance")
	_expect(main.get_node("LauncherDivider") is StaticBody2D, "Table 2.0 launcher is physically separated")
	_expect(main.get_node("WarmRamp/Label").text.begins_with("▶"), "First cue highlights the Warm ramp")
	_expect(main.get_node("ColdRamp/Label").text.begins_with("▶"), "First cue highlights the Cold ramp")
	_expect(not main.get_node("UniverseOrbit/Label").text.begins_with("▶"), "Future cue routes stay visually quiet")

	var starting_score: int = main.score_manager.score
	for target in rig_targets:
		main._on_rig_target_hit(target, target.family_id, target.display_name, target.score_value, target.flow_value)
	_expect_equal(main._active_rig_family_count(), 6, "Every Rig family can be activated from the table")
	_expect_equal(main.rig_progress_label.text, "RIG 6 / 6", "Rig objective reports complete progress")
	_expect_equal(main.status_label.text, "RIG PRÊT — TERMINEZ LA CUE STACK", "Rig completion keeps the remaining objective explicit")
	_expect(not main.show_flow.can_start_final_show(), "Rig completion alone cannot skip the Cue Stack")
	_expect(main.score_manager.score > starting_score + 1500, "Rig targets and completion award score")
	for target in rig_targets:
		_expect(target.lit, "Activated Rig targets remain visibly lit")

	var warm_ramp = main.get_node("WarmRamp")
	var cold_ramp = main.get_node("ColdRamp")
	main._on_ramp_completed(&"warm_ramp", warm_ramp.definition.score_value, warm_ramp.definition.flow_value)
	_expect(not warm_ramp.get_node("Label").text.begins_with("▶"), "Completed cue shot stops flashing")
	_expect(cold_ramp.get_node("Label").text.begins_with("▶"), "Outstanding cue shot remains highlighted")
	main._on_ramp_completed(&"cold_ramp", cold_ramp.definition.score_value, cold_ramp.definition.flow_value)
	_expect(main.cue_manager.current_cue_ready(), "Both color ramps prepare Color Wash")
	main._on_scoop_completed(&"console_scoop", 500, 80)
	_expect(main.cue_manager.active_cue != null, "Console executes an armed cue")
	main.cue_manager._process(1.3)
	_expect_equal(main.cue_manager.current_cue_index, 1, "Running cue advances automatically after its duration")
	_expect(main.get_node("UniverseOrbit/Label").text.begins_with("▶"), "Universe Chase highlights its route")

	main._on_lane_completed(&"universe_orbit", "UNIVERSE ORBIT", 600, 90)
	_expect(not main.cue_manager.current_cue_ready(), "Universe Chase counts its first orbit")
	main._on_lane_completed(&"universe_orbit", "UNIVERSE ORBIT", 600, 90)
	_expect(main.cue_manager.current_cue_ready(), "Universe Chase requires its second orbit")
	main._on_scoop_completed(&"console_scoop", 500, 80)
	main.cue_manager.complete_current_cue()
	for _hit in 4:
		main._on_bumper_hit(100, &"KickBumper")
	_expect(main.cue_manager.current_cue_ready(), "Four rhythm hits prepare Rhythm Drop")
	main._on_scoop_completed(&"console_scoop", 500, 80)
	main.cue_manager.complete_current_cue()
	_expect(main.cue_manager.is_stack_completed(), "Three Console executions complete the Cue Stack")
	_expect(main.show_flow.can_start_final_show(), "Cue Stack and Rig together arm Final Show")
	_expect_equal(main.status_label.text, "FINAL SHOW ARMÉ — VISEZ LA CONSOLE", "Final Show exposes its Console trigger")

	var route_score: int = main.score_manager.score
	main._on_lane_completed(&"universe_orbit", "UNIVERSE ORBIT", 600, 90)
	_expect(main.score_manager.score > route_score, "Universe Orbit awards score")
	_expect(main.status_label.text.begins_with("UNIVERSE ORBIT"), "Universe Orbit reports readable feedback")

	var sling_score: int = main.score_manager.score
	main._on_slingshot_hit(75, 15, &"LeftSlingshot")
	_expect(main.score_manager.score > sling_score, "Slingshots contribute to the active play loop")

	main.restart_game()
	await process_frame
	_expect_equal(main.rig_progress_label.text, "RIG 0 / 6", "Restart resets Rig progress")
	for target in rig_targets:
		_expect(not target.lit, "Restart clears every Rig target light")

	main.free()
	await process_frame


func _test_playfield_safe_trajectories() -> void:
	var packed_scene := load("res://scenes/app/Main.tscn") as PackedScene
	_expect(packed_scene != null, "Safe trajectory table loads")
	if packed_scene == null:
		return

	var main := packed_scene.instantiate()
	root.add_child(main)
	await process_frame

	var left_wall_shape := main.get_node("LeftWall/CollisionShape2D") as CollisionShape2D
	var right_wall_shape := main.get_node("RightWall/CollisionShape2D") as CollisionShape2D
	_expect(left_wall_shape.shape is RectangleShape2D, "Left boundary exposes a rectangle collision")
	_expect(right_wall_shape.shape is RectangleShape2D, "Right boundary exposes a rectangle collision")
	if left_wall_shape.shape is RectangleShape2D and right_wall_shape.shape is RectangleShape2D:
		_expect((left_wall_shape.shape as RectangleShape2D).size.y >= 1840.0, "Left boundary reaches the drain")
		_expect((right_wall_shape.shape as RectangleShape2D).size.y >= 1840.0, "Right boundary reaches the drain")

	var upper_left := main.get_node("UpperLeftGuide") as StaticBody2D
	_expect(upper_left.rotation > 0.0, "Upper left guide slopes back toward the playfield")

	var left_outlane := main.get_node("LeftOutlaneRail") as StaticBody2D
	var left_return := main.get_node("LeftReturnRail") as StaticBody2D
	var right_return := main.get_node("RightReturnRail") as StaticBody2D
	var right_outlane := main.get_node("RightOutlaneRail") as StaticBody2D
	var launcher_divider := main.get_node("LauncherDivider") as StaticBody2D
	_expect(left_outlane.position.x < left_return.position.x, "Left outlane remains outside its playable return")
	_expect(right_return.position.x < right_outlane.position.x, "Right playable return remains inside its outlane")
	_expect(right_outlane.position.x < launcher_divider.points[0].x, "Right outlane remains separate from the launcher")
	_expect(left_return.position.x < 540.0 and right_return.position.x > 540.0, "Both returns feed their matching flipper")

	main.free()
	await process_frame

	var left_exit := await _sample_return_exit(Vector2(240, 1330))
	var right_exit := await _sample_return_exit(Vector2(770, 1330))
	_expect(left_exit.x >= 300.0 and left_exit.x <= 480.0, "Left inlane delivers the ball over the left flipper (got %.1f)" % left_exit.x)
	_expect(right_exit.x >= 600.0 and right_exit.x <= 780.0, "Right inlane delivers the ball over the right flipper (got %.1f)" % right_exit.x)


func _sample_return_exit(start_position: Vector2) -> Vector2:
	var packed_scene := load("res://scenes/app/Main.tscn") as PackedScene
	var main := packed_scene.instantiate()
	root.add_child(main)
	await process_frame
	main.start_game()
	var ball: RigidBody2D = main.balls[0]
	ball.input_enabled = false
	ball.reset_ball(start_position)
	# Let the frozen pose reach the server before enabling shape-cast CCD.
	await physics_frame
	await physics_frame
	ball.freeze = false
	ball.linear_velocity = Vector2(0, 120)
	var exit_position := Vector2(-1, -1)
	for frame in 200:
		await physics_frame
		if ball.global_position.y >= 1620.0:
			exit_position = ball.global_position
			break
	main.free()
	await process_frame
	return exit_position


func _test_weighted_pinball_feel() -> void:
	var packed_scene := load("res://scenes/app/Main.tscn") as PackedScene
	_expect(packed_scene != null, "Weighted feel table loads")
	if packed_scene == null:
		return

	var main := packed_scene.instantiate()
	root.add_child(main)
	await process_frame
	main.start_game()
	var ball: RigidBody2D = main.balls[0]
	var ball_material := ball.physics_material_override
	_expect(ball.mass >= 1.35, "Ball keeps deliberate collision mass")
	_expect(ball.custom_integrator and is_zero_approx(ball.gravity_scale), "Ball rolls on the deck without global free-fall gravity")
	_expect(ball_material != null and ball_material.bounce <= 0.15, "Ball no longer rebounds like rubber")
	_expect(ball_material != null and ball_material.friction >= 0.45, "Ball keeps traction on contacts")
	_expect(ball.has_node("ContactShadow") and ball.get_node("Visual").texture != null, "Ball has readable table contact and chrome volume")

	var guide := main.get_node("UpperLeftGuide") as StaticBody2D
	var flipper := main.get_node("LeftFlipper") as AnimatableBody2D
	_expect(guide.physics_material_override != null and guide.physics_material_override.bounce <= 0.05, "Passive guides absorb excess rebound")
	_expect(flipper.physics_material_override != null and flipper.physics_material_override.bounce < 0.3, "Flipper rubber absorbs a catch instead of bouncing like a bumper")
	_expect(flipper.tuning != null, "Flipper motor response uses shared tuning")

	ball.input_enabled = false
	ball.reset_ball(Vector2(540, 900))
	await physics_frame
	await physics_frame
	ball.freeze = false
	var fall_frames := 0
	while ball.global_position.y < 1300.0 and fall_frames < 140:
		await physics_frame
		fall_frames += 1
	_expect(fall_frames <= 104, "Ball crosses the middle table on the measured slope (got %d frames)" % fall_frames)
	_expect(ball.linear_velocity.y >= 850.0, "Ball accelerates consistently along the inclined deck")

	main.free()
	await process_frame


func _test_final_show_multiball_and_blackout() -> void:
	var packed_scene := load("res://scenes/app/Main.tscn") as PackedScene
	_expect(packed_scene != null, "Main scene loads for Final Show")
	if packed_scene == null:
		return

	var main := packed_scene.instantiate()
	main.blackout_duration = 0.01
	root.add_child(main)
	await process_frame
	await physics_frame
	main.show_flow.final_show_duration = 0.1
	main.start_game()
	main._launch_or_restart()
	_expect_equal(main.show_flow.state, ShowFlowManagerNode.State.BUILD, "Launching the first ball enters Build")
	_complete_cue_stack(main)

	var rig_targets := main.get_tree().get_nodes_in_group("rig_targets")
	for target in rig_targets:
		main._on_rig_target_hit(target, target.family_id, target.display_name, target.score_value, target.flow_value)
	_expect(main.show_flow.can_start_final_show(), "A complete Rig arms Final Show")

	var balls_before: int = main.remaining_balls
	main._on_scoop_completed(&"console_scoop", 500, 80)
	await process_frame
	_expect(main.multiball_active, "Console starts Final Show multiball")
	_expect_equal(main.show_flow.state, ShowFlowManagerNode.State.FINAL_SHOW, "Show state reports Final Show")
	_expect_equal(main._active_multiball_balls().size(), 3, "Final Show launches exactly three balls")
	_expect_equal(main.remaining_balls, balls_before, "Bonus multiball does not consume numbered balls")
	_expect(main.final_show_label.visible, "Final Show exposes its score multiplier")

	var score_before: int = main.score_manager.score
	var expected_delta: int = 10 * main.flow_manager.multiplier * main.show_flow.final_show_score_multiplier
	main._add_score_with_flow(10)
	_expect_equal(main.score_manager.score - score_before, expected_delta, "Final Show doubles the active Flow score")

	main.balls[1].mark_drained()
	_expect(main.multiball_active, "Final Show continues with two balls")
	main.balls[2].mark_drained()
	_expect(not main.multiball_active, "Final Show ends when one ball remains")
	_expect_equal(main.remaining_balls, balls_before, "Ending Final Show preserves the three-ball session")
	_expect_equal(main.show_flow.state, ShowFlowManagerNode.State.BLACKOUT, "Multiball resolves into Blackout")
	_expect(main.blackout_overlay.visible, "Blackout is visible on the playfield")
	_expect_equal(main._active_multiball_balls().size(), 1, "Blackout keeps one playable survivor")

	for frame in 12:
		await physics_frame
	_expect(not main.blackout_overlay.visible, "Blackout clears after its configured duration")
	_expect_equal(main.show_flow.state, ShowFlowManagerNode.State.FLOW, "Completed show returns to Flow")
	main._on_scoop_completed(&"console_scoop", 500, 80)
	_expect(not main.multiball_active, "Console cannot repeat Final Show in one session")

	for frame in 12:
		await physics_frame
	main.free()
	await process_frame


func _test_stage_identity_and_music_stems() -> void:
	var packed_scene := load("res://scenes/app/Main.tscn") as PackedScene
	_expect(packed_scene != null, "Main scene loads for stage identity")
	if packed_scene == null:
		return

	var main := packed_scene.instantiate()
	root.add_child(main)
	await process_frame
	main.start_game()
	_expect(main.audio_service.transport_playing, "Starting a game starts the music transport")
	_expect_equal(main.audio_service.stem_set.streams().size(), 8, "The stage loop exposes eight synchronized stems")
	_expect(main.audio_service.stem_levels[&"atmosphere"] > 0.0, "Preset opens with atmosphere")
	_expect_equal(main.stage_visuals.show_state, ShowFlowManagerNode.State.PRESET, "Stage visuals follow Preset")

	main._launch_or_restart()
	_complete_cue_stack(main)
	var rig_targets := main.get_tree().get_nodes_in_group("rig_targets")
	for index in 5:
		var target: Node = rig_targets[index]
		main._on_rig_target_hit(target, target.family_id, target.display_name, target.score_value, target.flow_value)
	_expect(main.audio_service.stem_levels[&"kick"] > 0.0, "Two Rig families introduce the kick")
	_expect(main.audio_service.stem_levels[&"bass"] > 0.0, "Three Rig families introduce the bass")
	_expect(main.audio_service.stem_levels[&"percussion"] > 0.0, "Four Rig families introduce percussion")
	_expect(main.audio_service.stem_levels[&"arp"] > 0.0, "Five Rig families introduce the arpeggiator")
	_expect_equal(main.stage_visuals.rig_count, 5, "Five lit fixtures are reflected by the stage rig")

	var final_target: Node = rig_targets[5]
	main._on_rig_target_hit(final_target, final_target.family_id, final_target.display_name, final_target.score_value, final_target.flow_value)
	_expect_equal(main.stage_visuals.show_state, ShowFlowManagerNode.State.FLOW, "Completed Rig moves the visual stage to Flow")
	_expect(main.show_flow.start_final_show(), "Armed Showflow can enter Final Show for presentation testing")
	_expect(main.audio_service.stem_levels[&"lead"] > 0.0, "Final Show introduces the lead")
	_expect(main.audio_service.stem_levels[&"impact"] > 0.0, "Final Show introduces the impact stem")
	_expect_equal(main.stage_visuals.show_state, ShowFlowManagerNode.State.FINAL_SHOW, "Stage visuals follow Final Show")

	main.show_flow.start_blackout()
	_expect_equal(main.audio_service.stem_levels[&"atmosphere"], 0.0, "Blackout mutes the stem mix")
	_expect_equal(main.stage_visuals.show_state, ShowFlowManagerNode.State.BLACKOUT, "Stage visuals follow Blackout")
	main.free()
	await process_frame


func _test_stagecraft_visual_language() -> void:
	var packed_scene := load("res://scenes/app/Main.tscn") as PackedScene
	_expect(packed_scene != null, "Main scene loads for the stagecraft visual pass")
	if packed_scene == null:
		return

	var main := packed_scene.instantiate()
	root.add_child(main)
	await process_frame

	var playfield_art := main.get_node_or_null("PlayfieldArt") as Node2D
	_expect(playfield_art != null, "The playfield exposes its dedicated vector-art layer")
	if playfield_art != null:
		_expect(playfield_art.z_index < main.stage_visuals.z_index, "Reactive beams render above the static deck")
	_expect(main.get_node_or_null("UpperLeftGuide/Visual/MetalFace") != null, "Guide rails have a readable metal face")
	_expect(main.get_node_or_null("LeftFlipper/Visual/MetalSpine") != null, "Flippers expose their mechanical spine")
	_expect(main.get_node_or_null("KickBumper/Visual/Lens") != null, "Bumpers read as stage-light lenses")
	_expect(main.get_node_or_null("FrontWashTarget/Indicator") != null, "Rig targets expose a persistent status indicator")
	_expect(main.get_node_or_null("WarmRamp/Visual/Deck") != null, "Ramps expose a distinct physical deck")
	_expect(main.get_node_or_null("ConsoleScoop/Visual/GoStrip") != null, "The Console exposes a dedicated GO strip")
	var regions: Dictionary = {}
	for target in get_nodes_in_group("rig_targets"):
		var texture: AtlasTexture = target.get_node("Visual/MetalFrame").texture
		_expect(texture != null and texture.atlas.get_size() == Vector2(960, 112), "Fixture atlas imports at its bounded size")
		regions[texture.region] = true
	_expect_equal(regions.size(), 6, "Six rig families have distinct original fixture silhouettes")
	var warm: Node2D = main.get_node("WarmRamp/PhysicalRoute")
	var cold: Node2D = main.get_node("ColdRamp/PhysicalRoute")
	var orbit: Node2D = main.get_node("UniverseOrbit/PhysicalRoute")
	_expect(warm.z_index + 1 < cold.z_index and cold.z_index + 1 < orbit.z_index, "Crossings reserve a separate visual height for every deck and rider")
	for target in get_nodes_in_group("rig_targets"):
		_expect(target.get_node("Label").z_index > orbit.z_index + 1 and target.get_node("Indicator").z_index > orbit.z_index + 1, "Objective annotations stay readable above crossing rails")
	_expect(main.get_node("ConsoleScoop/Label").z_index > orbit.z_index + 1, "The Console annotation cannot be masked by a return wire")
	var ball: RigidBody2D = main.balls[0]
	main.start_game()
	for route in [warm, cold, orbit]:
		var art := route.get_node("RouteArt") as RouteVisual
		_expect(art._left.size() == route.centerline.size() and art._right.size() == route.centerline.size(), "Art keeps every baked physical rail point")
		ball.freeze = false
		var velocity := Vector2(315, -721)
		ball.linear_velocity = velocity
		_expect(ball.enter_route(route, route.definition.collision_layer), "Rider accepts its visual height")
		_expect_equal(ball.z_index, route.z_index + 1, "Rider draws above its own deck and below higher decks")
		_expect_equal(ball.linear_velocity, velocity, "Presentation does not change physical velocity")
		ball.leave_route()
		_expect_equal(ball.z_index, 0, "Leaving every route restores the base visual plane")
	ball.freeze = true
	var bumper := main.get_node("KickBumper")
	bumper.set_objective_highlight(true)
	bumper._process(0.4)
	_expect_equal(bumper.visual.scale, Vector2.ONE, "Objective light never inflates a mechanical bumper")
	bumper.set_flashing_effects(&"off")
	_expect(not bumper.is_processing(), "Off mode keeps the fixture static")
	_expect(bumper.get_node("Visual/Bezel").texture != null, "Original lens artwork imports in Godot")

	var right_flipper := main.get_node("RightFlipper")
	_expect(right_flipper.get_node("ContactShadow").scale.x < 0.0, "Right flipper art and contact shadow mirror together")
	var start_overlay := main.get_node("Interface/StartOverlay") as Control
	_expect(start_overlay.theme != null, "Menus use the shared stage-control theme")

	main.free()
	await process_frame


func _test_sync_bonus_integration() -> void:
	var packed_scene := load("res://scenes/app/Main.tscn") as PackedScene
	_expect(packed_scene != null, "Main scene loads for Sync Bonus")
	if packed_scene == null:
		return

	var main := packed_scene.instantiate()
	root.add_child(main)
	await process_frame
	main.start_game()
	main._launch_or_restart()
	main.audio_service.seek_transport(8.04)
	main._on_bumper_hit(100, &"KickBumper")

	_expect_equal(main.sync_bonus_manager.awards, 1, "A timed gameplay hit awards Sync once")
	_expect_equal(main.sync_bonus_manager.perfect_awards, 1, "The central window records Perfect Sync")
	_expect_equal(main.score_manager.score, 300, "Perfect Sync adds its score without replacing base points")
	_expect_equal(main.flow_manager.flow_points, 135, "Perfect Sync adds Flow on top of the physical hit")
	_expect(main.sync_feedback_label.visible, "Sync exposes a readable on-table feedback label")
	_expect("PERFECT SYNC" in main.sync_feedback_label.text, "Perfect timing is named, not colour-only")
	_expect_equal(main.audio_service.last_sfx_id, &"sync", "Sync requests its dedicated audible feedback")

	main._on_bumper_hit(100, &"KickBumper")
	_expect_equal(main.sync_bonus_manager.awards, 1, "Multiple contacts cannot farm one musical pulse")
	var score_before_offbeat: int = main.score_manager.score
	main.audio_service.seek_transport(8.50)
	main._on_slingshot_hit(75, 15, &"LeftSlingshot")
	_expect(main.score_manager.score > score_before_offbeat, "Off-beat shots keep all normal gameplay points")
	_expect_equal(main.sync_bonus_manager.awards, 1, "Off-beat shots do not create a hidden award")

	main.restart_game()
	_expect_equal(main.sync_bonus_manager.awards, 0, "Restart clears Sync Bonus state")
	_expect(not main.sync_feedback_label.visible, "Restart clears transient Sync feedback")
	main.free()
	await process_frame


func _test_audio_settings_menu() -> void:
	var save_path := "user://tests/audio_settings_menu.json"
	_remove_test_file(save_path)
	var packed_scene := load("res://scenes/app/Main.tscn") as PackedScene
	_expect(packed_scene != null, "Main scene loads for audio settings")
	if packed_scene == null:
		return

	var main := packed_scene.instantiate()
	main.get_node("SettingsStore").save_path = save_path
	root.add_child(main)
	await process_frame

	_expect(main.settings_button.visible, "Audio settings are available from the main menu")
	main._open_audio_settings()
	_expect(
		main.settings_panel.visible and not main.start_menu.visible,
		"Audio settings open without leaving the menu"
	)
	main.master_slider.value = 65.0
	main.music_slider.value = 40.0
	main.sfx_slider.value = 20.0
	_expect(
		is_equal_approx(main.audio_service.master_volume_db, SettingsStoreNode.percent_to_db(65.0)),
		"Master slider applies its mix immediately"
	)
	main._close_audio_settings()
	_expect(main.start_menu.visible and not main.settings_panel.visible, "Back returns to the main menu")
	_expect(FileAccess.file_exists(save_path), "Leaving audio settings writes a local save")

	var reloaded := SettingsStoreNode.new()
	reloaded.save_path = save_path
	_expect(reloaded.load_settings(), "Menu audio settings reload from local storage")
	_expect_equal(reloaded.master_percent, 65.0, "Menu persists Master volume")
	_expect_equal(reloaded.music_percent, 40.0, "Menu persists Music volume")
	_expect_equal(reloaded.sfx_percent, 20.0, "Menu persists SFX volume")
	main.restart_game()
	_expect(
		is_equal_approx(main.audio_service.sfx_volume_db, SettingsStoreNode.percent_to_db(20.0)),
		"Restart keeps the player's audio mix"
	)

	reloaded.free()
	main.free()
	await process_frame
	_remove_test_file(save_path)


func _test_flashing_effects_accessibility() -> void:
	var save_path := "user://tests/flashing_effects_settings.json"
	_remove_test_file(save_path)
	var packed_scene := load("res://scenes/app/Main.tscn") as PackedScene
	_expect(packed_scene != null, "Main scene loads for flashing effects accessibility")
	if packed_scene == null:
		return

	var main := packed_scene.instantiate()
	main.get_node("SettingsStore").save_path = save_path
	root.add_child(main)
	await process_frame

	_expect_equal(main.flashing_effects_option.item_count, 3, "Settings expose Full, Reduced and Off")
	main._on_flashing_effects_selected(1)
	_expect_equal(main.settings_store.flashing_effects, &"reduced", "Reduced mode applies immediately")
	_expect_equal(main.stage_visuals.flashing_effects, &"reduced", "Stage visuals receive Reduced mode")
	main.stage_visuals.trigger_hit(Color.WHITE)
	_expect(main.stage_visuals.hit_flash <= 0.3, "Reduced mode limits the full-screen hit flash")

	var visual_groups: Array[StringName] = [
		&"score_bumpers",
		&"show_ramps",
		&"rig_targets",
		&"table_lanes",
		&"slingshots",
	]
	for group_name in visual_groups:
		for visual_node in main.get_tree().get_nodes_in_group(group_name):
			if visual_node.has_method("set_flashing_effects"):
				_expect_equal(
					visual_node.flashing_effects,
					&"reduced",
					"Reduced mode reaches each reactive playfield element"
				)

	main._show_blackout_feedback()
	_expect(
		main.blackout_overlay.visible and main.blackout_overlay.color.a <= 0.38,
		"Reduced mode softens Blackout without removing its label"
	)
	main._on_flashing_effects_selected(2)
	main.stage_visuals.trigger_hit(Color.WHITE)
	_expect_equal(main.stage_visuals.hit_flash, 0.0, "Off mode suppresses the hit flash")
	main._show_blackout_feedback()
	_expect(not main.blackout_overlay.visible, "Off mode suppresses the full-screen Blackout")
	_expect(main.stage_visuals.has_method("set_beat_position"), "Off mode keeps the readable Sync clock contract")

	var reloaded := SettingsStoreNode.new()
	reloaded.save_path = save_path
	_expect(reloaded.load_settings(), "Flashing effects choice reloads from local storage")
	_expect_equal(reloaded.flashing_effects, &"off", "Off mode survives a reload")

	reloaded.free()
	main.free()
	await process_frame
	_remove_test_file(save_path)


func _test_how_to_play_menu() -> void:
	var packed_scene := load("res://scenes/app/Main.tscn") as PackedScene
	_expect(packed_scene != null, "Main scene loads for How to Play")
	if packed_scene == null:
		return

	var main := packed_scene.instantiate()
	root.add_child(main)
	await process_frame

	_expect(main.how_to_play_button.visible, "How to Play is available from the main menu")
	main._open_how_to_play()
	var panel = main.how_to_play_panel
	_expect(panel.visible and not main.start_menu.visible, "How to Play opens above the main menu")
	_expect(not main.gameplay_active, "Opening the guide never starts gameplay")
	_expect_equal(panel.current_page, 0, "The guide always opens on controls")
	_expect(panel.previous_button.disabled, "The first page cannot navigate backward")
	_expect_equal(panel.diagram.page, 0, "The controls diagram matches the first page")

	panel.show_next_page()
	_expect("RIG" in panel.title_label.text, "The second page explains the Rig")
	panel.show_next_page()
	_expect("CUES" in panel.title_label.text, "The third page explains the Cue Stack")
	panel.show_next_page()
	_expect("FINAL SHOW" in panel.title_label.text, "The fourth page explains the Final Show")
	_expect_equal(panel.next_button.text, "TERMINER", "The final action clearly closes the guide")
	_expect_equal(panel.diagram.page, 3, "The Final Show diagram matches the final page")
	panel.show_next_page()
	_expect(not panel.visible and main.start_menu.visible, "Finishing the guide returns to the menu")
	_expect(not main.gameplay_active, "Closing the guide still leaves gameplay stopped")

	main.free()
	await process_frame


func _test_alpha_candidate_player_journey() -> void:
	var packed_scene := load("res://scenes/app/Main.tscn") as PackedScene
	_expect(packed_scene != null, "Alpha candidate loads for the complete player journey")
	if packed_scene == null:
		return

	var main := packed_scene.instantiate()
	main.respawn_delay = 0.01
	main.blackout_duration = 0.01
	root.add_child(main)
	await process_frame
	await physics_frame

	_expect(main.start_menu.visible, "Complete journey starts on the main menu")
	_expect(not main.audio_service.transport_playing, "Main menu remains silent before Play")
	main.start_game()
	_expect_equal(main.session_state, MainNode.SessionState.READY, "Play starts on a ready first ball")
	_expect(main.status_label.text.begins_with("BILLE 1 / 3"), "First-ball instruction uses final French copy")
	main._launch_or_restart()
	_expect_equal(main.session_state, MainNode.SessionState.PLAYING, "Launch enters active gameplay")
	_expect_equal(main.show_flow.state, ShowFlowManagerNode.State.BUILD, "Launch begins the Build")

	_complete_cue_stack(main)
	var rig_targets := main.get_tree().get_nodes_in_group("rig_targets")
	for target in rig_targets:
		main._on_rig_target_hit(
			target,
			target.family_id,
			target.display_name,
			target.score_value,
			target.flow_value
		)
	_expect(main.cue_manager.is_stack_completed(), "Complete journey finishes the Cue Stack")
	_expect_equal(main._active_rig_family_count(), 6, "Complete journey lights all six Rig families")
	_expect_equal(main.show_flow.state, ShowFlowManagerNode.State.FLOW, "Rig plus Cue Stack arms Flow")
	_expect_equal(
		main.status_label.text,
		"FINAL SHOW ARMÉ — VISEZ LA CONSOLE",
		"Armed Final Show exposes one clear action"
	)

	main.show_flow.final_show_duration = 60.0
	main._on_scoop_completed(&"console_scoop", 500, 80)
	await process_frame
	_expect(main.multiball_active, "Complete journey reaches the three-ball Final Show")
	_expect("3 BILLES" in main.final_show_label.text, "Final Show banner uses consistent ball terminology")
	main._finish_final_show("FINAL SHOW TERMINÉ")
	_expect_equal(main.show_flow.state, ShowFlowManagerNode.State.BLACKOUT, "Complete journey reaches Blackout")
	for frame in 12:
		await physics_frame
	_expect_equal(main.show_flow.state, ShowFlowManagerNode.State.FLOW, "Blackout returns to playable Flow")

	for drain_index in 3:
		var ball: RigidBody2D = main.balls[main.active_ball_index]
		ball.ball_save_used = true
		if main.session_state == MainNode.SessionState.READY:
			main._launch_or_restart()
		main._resolve_ball_drain(ball)
		await process_frame
		if drain_index < 2:
			for frame in 20:
				if main.session_state == MainNode.SessionState.READY:
					break
				await physics_frame

	_expect_equal(main.remaining_balls, 0, "Complete journey consumes exactly three numbered balls")
	_expect_equal(main.session_state, MainNode.SessionState.GAME_OVER, "Complete journey ends in Game Over state")
	_expect(main.game_over_overlay.visible, "Complete journey exposes the final score overlay")
	_expect_equal(main.status_label.text, "PARTIE TERMINÉE", "End state uses final French copy")
	_expect(not main.audio_service.transport_playing, "Game over stops the music transport")
	_expect_equal(main.playtest_recorder.events.numbered_balls_lost, 3, "Qualification report distinguishes the three numbered losses from bonus multiball")
	_expect_equal(main.playtest_recorder.events.cues_completed, 3, "Qualification report counts completed cues")
	_expect_equal(main.playtest_recorder.events.rig_activations, 6, "Qualification report counts unique Rig activations")
	_expect_equal(main.playtest_recorder.events.final_shows, 1, "Qualification report counts Final Show entry")
	_expect_equal(main.playtest_recorder.events.games_finished, 1, "Qualification report records the completed game")

	main.free()
	await process_frame


func _test_guided_launcher_and_go() -> void:
	var scene := load("res://scenes/app/Main.tscn") as PackedScene
	var main := scene.instantiate()
	root.add_child(main)
	await physics_frame
	_expect(not main.launch_button.visible, "GO is absent from the menu")
	main.start_game()
	await physics_frame
	_expect(main.launch_button.visible, "GO is visible when a numbered ball is ready")
	var top_touch := InputEventScreenTouch.new()
	top_touch.index = 12
	top_touch.pressed = true
	top_touch.position = Vector2(540, 600)
	main._unhandled_input(top_touch)
	_expect_equal(main.session_state, MainNode.SessionState.READY, "Touching the upper table no longer launches")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = main.launch_button.get_global_rect().get_center()
	root.push_input(click, true)
	click = click.duplicate()
	click.pressed = false
	root.push_input(click, true)
	_expect_equal(main.session_state, MainNode.SessionState.PLAYING, "A real GUI press on GO launches the ball")
	main._launch_or_restart()
	_expect_equal(main.playtest_recorder.launches, 1, "Repeated GO cannot launch an active ball twice")
	await physics_frame
	_expect(not main.launch_button.visible, "GO leaves the right flipper touch zone free during play")
	var left_touch := InputEventScreenTouch.new()
	left_touch.index = 20
	left_touch.pressed = true
	left_touch.position = Vector2(200, 1600)
	var right_touch := left_touch.duplicate() as InputEventScreenTouch
	right_touch.index = 21
	right_touch.position = Vector2(800, 1600)
	main._unhandled_input(left_touch)
	main._unhandled_input(right_touch)
	_expect(Input.is_action_pressed(&"flipper_left") and Input.is_action_pressed(&"flipper_right"), "Both flippers can be held by independent touches")
	left_touch.pressed = false
	right_touch.pressed = false
	main._input(left_touch)
	main._input(right_touch)
	_expect(not Input.is_action_pressed(&"flipper_left") and not Input.is_action_pressed(&"flipper_right"), "GUI-independent releases do not leave a flipper stuck")
	main._on_reset_pressed()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	main._unhandled_input(key)
	_expect_equal(main.session_state, MainNode.SessionState.PLAYING, "Space still launches through the shared action")
	main._on_reset_pressed()
	var gamepad := InputEventJoypadButton.new()
	gamepad.button_index = JOY_BUTTON_A
	gamepad.pressed = true
	main._unhandled_input(gamepad)
	_expect_equal(main.session_state, MainNode.SessionState.PLAYING, "Gamepad A still launches through the shared action")
	main.free()
	await process_frame

	# Actual rigid bodies must negotiate the curve from varied shooter positions
	# and strengths. No scoring signal, position correction or rescue is injected.
	for sample in [
		Vector2(950, 0.95), Vector2(950, 1.0), Vector2(950, 1.05),
		Vector2(960, 0.95), Vector2(960, 1.0), Vector2(960, 1.05),
		Vector2(970, 0.95), Vector2(970, 1.0), Vector2(970, 1.05),
	]:
		main = scene.instantiate()
		root.add_child(main)
		await physics_frame
		main.start_game()
		var ball: RigidBody2D = main.balls[0]
		ball.reset_ball(Vector2(sample.x, 1650))
		ball.launch_force *= sample.y
		main._launch_or_restart()
		var entered_playfield := false
		var touched_curve := false
		for _frame in 480:
			await physics_frame
			if "--trace-launch" in OS.get_cmdline_user_args() and _frame % 30 == 0:
				print("LAUNCH ", sample, " t=", _frame, " pos=", ball.global_position, " velocity=", ball.linear_velocity)
			for body in ball.get_colliding_bodies():
				if body == main.get_node("LauncherOuterGuide") and ball.global_position.y < 650.0:
					touched_curve = true
			if ball.global_position.x < 620.0 and ball.global_position.y < 700.0:
				entered_playfield = true
				break
			if main.session_state != MainNode.SessionState.PLAYING:
				break
		_expect(touched_curve, "Launcher is physically steered by the curved guide (%s)" % sample)
		_expect(entered_playfield, "Guided launch reaches the upper playfield (%s, end %s)" % [sample, ball.global_position])
		_expect_equal(main.remaining_balls, 3, "Guided launch does not consume a ball")
		_expect_equal(main.playtest_recorder.ball_saves, 0, "Guided launch needs no safety teleport")
		if entered_playfield:
			ball.ball_save_used = true
			var played := await _play_physical_return(main, ball, &"", 1440)
			_expect(played.returned, "Launch first return can be caught or struck back into play (%s, %s)" % [sample, played])
		main.free()
		await process_frame


func _test_flipper_return_control() -> void:
	for sample in [
		[Vector2(240, 1330), Vector2(0, 120), &"flipper_left"],
		[Vector2(270, 1400), Vector2(40, 180), &"flipper_left"],
		[Vector2(770, 1330), Vector2(0, 120), &"flipper_right"],
		[Vector2(735, 1400), Vector2(-40, 180), &"flipper_right"],
		[Vector2(495, 1500), Vector2(0, 120), &"flipper_left"],
		[Vector2(585, 1500), Vector2(0, 120), &"flipper_right"],
	]:
		var result := await _sample_flipper_control(sample[0], sample[1], sample[2])
		_expect(result.contacted, "Return makes physical contact with its flipper (%s): %s" % [sample[0], result])
		_expect(result.returned, "Timed flipper strike returns the ball into play (%s): %s" % [sample[0], result])

	# A deliberate straight centre drain remains possible: no invisible assist
	# or safety teleport is allowed to make the positive trajectory tests pass.
	var scene := load("res://scenes/app/Main.tscn") as PackedScene
	var main := scene.instantiate()
	root.add_child(main)
	await physics_frame
	main.start_game()
	main._launch_or_restart()
	var ball: RigidBody2D = main.balls[0]
	ball.reset_ball(Vector2(540, 1500), false)
	ball.launch_ready = false
	ball.ball_save_used = true
	ball.freeze = false
	ball.linear_velocity = Vector2(0, 120)
	Input.action_press(&"flipper_left")
	Input.action_press(&"flipper_right")
	for _frame in 360:
		await physics_frame
		if main.remaining_balls < 3:
			break
	Input.action_release(&"flipper_left")
	Input.action_release(&"flipper_right")
	_expect_equal(main.remaining_balls, 2, "A legitimate centre drain still consumes exactly one ball")
	_expect_equal(main.playtest_recorder.ball_saves, 0, "Centre drain does not use an invisible rescue")
	main.free()
	await process_frame


func _sample_flipper_control(start_position: Vector2, velocity: Vector2, action: StringName) -> Dictionary:
	var scene := load("res://scenes/app/Main.tscn") as PackedScene
	var main := scene.instantiate()
	root.add_child(main)
	await physics_frame
	main.start_game()
	main.session_state = MainNode.SessionState.PLAYING
	var ball: RigidBody2D = main.balls[0]
	ball.reset_ball(start_position, false)
	await physics_frame
	await physics_frame
	ball.launch_ready = false
	ball.ball_save_used = true
	ball.freeze = false
	ball.linear_velocity = velocity
	var result := await _play_physical_return(main, ball, action, 900)
	main.free()
	await process_frame
	return result


func _play_physical_return(main: Node, ball: RigidBody2D, action: StringName, frames: int) -> Dictionary:
	var left: Node2D = main.get_node("LeftFlipper")
	var right: Node2D = main.get_node("RightFlipper")
	var contacted := false
	var returned := false
	var activated := false
	var released_catch := false
	var replayed := false
	var flipper: Node2D
	for _frame in frames:
		await physics_frame
		if ball.global_position.y >= 1640.0 and ball.linear_velocity.y > 0.0 and not activated:
			if action == &"":
				action = &"flipper_left" if ball.global_position.x < 540.0 else &"flipper_right"
			flipper = left if action == &"flipper_left" else right
			Input.action_press(action)
			activated = true
		for body in ball.get_colliding_bodies():
			if body == left or body == right:
				contacted = true
		if contacted and activated and not released_catch and ball.global_position.y > 1600.0 and ball.linear_velocity.length() < 80.0:
			Input.action_release(action)
			released_catch = true
		if released_catch and not replayed:
			var local_distance := (ball.global_position - flipper.global_position).rotated(-flipper.rotation).x
			if action == &"flipper_right":
				local_distance = -local_distance
			if local_distance >= 95.0:
				Input.action_press(action)
				replayed = true
		if contacted and ball.global_position.y < 1550.0 and ball.linear_velocity.y < 0.0:
			returned = true
			break
		if ball.drain_locked or main.remaining_balls != 3:
			break
	Input.action_release(&"flipper_left")
	Input.action_release(&"flipper_right")
	return {"contacted": contacted, "returned": returned, "catch_replayed": replayed, "end": ball.global_position}


func _test_rolling_dynamics() -> void:
	var tuning := PhysicsTuningResource.new()
	# With a 6.5-degree slope and 1600 px/m, an ideal rolling sphere gains
	# about 1247 px/s each second after the configured rolling resistance.
	var light := await _measure_ball_motion(tuning, Vector2.ZERO, 60, 0.7)
	var heavy := await _measure_ball_motion(tuning, Vector2.ZERO, 60, 2.8)
	_expect(absf(light.velocity.y - 624.0) < 25.0, "Inclined rolling acceleration matches the physical scale: %s" % light)
	_expect(absf(light.velocity.y - heavy.velocity.y) < 2.0, "Downhill acceleration is independent of collision mass")
	_expect(light.position.y > 145.0 and light.position.y < 175.0, "Half-second rolling displacement matches the slope: %s" % light)
	tuning.table_slope_degrees = 0.0
	var slow := await _measure_ball_motion(tuning, Vector2(600, 0), 120)
	var fast := await _measure_ball_motion(tuning, Vector2(1200, 0), 120)
	_expect(absf(slow.velocity.x - 577.6) < 3.0, "Flat deck loses speed to rolling resistance, not air drag: %s" % slow)
	_expect(absf((600.0 - slow.velocity.x) - (1200.0 - fast.velocity.x)) < 2.0, "Rolling resistance does not grow with speed like viscous drag")
	var stopped := await _measure_ball_motion(tuning, Vector2(30, 0), 240)
	_expect(stopped.velocity.length() < 0.1, "A slow ball stops on a level deck without reversing")
	var capped := await _measure_ball_motion(tuning, Vector2(3000, 0), 6)
	_expect(capped.velocity.length() <= tuning.max_speed + 0.1, "Physics integration caps excess speed safely")
	tuning.table_slope_degrees = 9.0
	var steeper := await _measure_ball_motion(tuning, Vector2.ZERO, 60)
	_expect(steeper.velocity.y > heavy.velocity.y * 1.3, "A steeper deck measurably accelerates the ball faster")
	tuning.table_slope_degrees = 6.5
	var original_tick_rate := Engine.physics_ticks_per_second
	Engine.physics_ticks_per_second = 60
	var fewer_ticks := await _measure_ball_motion(tuning, Vector2.ZERO, 30)
	Engine.physics_ticks_per_second = original_tick_rate
	_expect(absf(fewer_ticks.velocity.y - light.velocity.y) < 25.0, "Rolling speed stays consistent at 60 and 120 physics ticks")
	_expect(absf(fewer_ticks.position.y - light.position.y) < 10.0, "Rolling travel stays consistent at 60 and 120 physics ticks")


func _measure_ball_motion(tuning: Resource, velocity: Vector2, frames: int, collision_mass: float = 1.4) -> Dictionary:
	var scene := load("res://scenes/gameplay/Ball.tscn") as PackedScene
	var ball := scene.instantiate() as RigidBody2D
	ball.tuning = tuning
	ball.input_enabled = false
	root.add_child(ball)
	await physics_frame
	ball.reset_ball(Vector2.ZERO)
	await physics_frame
	await physics_frame
	ball.mass = collision_mass
	ball.freeze = false
	ball.linear_velocity = velocity
	for _frame in frames:
		await physics_frame
	var result := {"position": ball.global_position, "velocity": ball.linear_velocity}
	ball.free()
	await process_frame
	return result


func _test_flipper_motor_and_cradle_shots() -> void:
	var scene := load("res://scenes/app/Main.tscn") as PackedScene
	var main := scene.instantiate()
	root.add_child(main)
	await physics_frame
	var flipper: Node2D = main.get_node("LeftFlipper")
	Input.action_press(&"flipper_left")
	var press_frames := 0
	while absf(rad_to_deg(flipper.rotation) - flipper.active_angle_degrees) > 0.1 and press_frames < 30:
		await physics_frame
		press_frames += 1
	Input.action_release(&"flipper_left")
	var return_frames := 0
	while absf(rad_to_deg(flipper.rotation) - flipper.rest_angle_degrees) > 0.1 and return_frames < 40:
		await physics_frame
		return_frames += 1
	_expect(press_frames >= 4 and press_frames <= 15, "Coil ramps up without an instant angle jump (%d frames)" % press_frames)
	_expect(return_frames > press_frames, "Return spring is slower than the firing stroke (%d vs %d)" % [return_frames, press_frames])
	main.free()
	await process_frame
	for action in [&"flipper_left", &"flipper_right"]:
		var early := await _sample_cradle_shot(action, 95.0)
		var late := await _sample_cradle_shot(action, 145.0)
		_expect(early.held and late.held, "Held flipper physically cradles the ball on either timing (%s): %s / %s" % [action, early, late])
		_expect(early.shot and late.shot, "Release and timed re-press produce real upward shots (%s): %s / %s" % [action, early, late])
		if early.shot and late.shot:
			_expect(absf(early.crossing_x - late.crossing_x) > 80.0, "Shot timing changes the aimed route (%s): %.1f / %.1f" % [action, early.crossing_x, late.crossing_x])

	main = scene.instantiate()
	main.ball_recovery_delay = 0.35
	main.stuck_speed_threshold = 100.0
	root.add_child(main)
	await physics_frame
	main.start_game()
	main.session_state = MainNode.SessionState.PLAYING
	var stranded: RigidBody2D = main.balls[0]
	stranded.reset_ball(Vector2(960, 1720), false)
	await physics_frame
	await physics_frame
	stranded.launch_ready = false
	stranded.freeze = false
	Input.action_press(&"flipper_left")
	for _frame in 240:
		await physics_frame
		if main.session_state == MainNode.SessionState.READY:
			break
	Input.action_release(&"flipper_left")
	_expect_equal(main.session_state, MainNode.SessionState.READY, "Holding a flipper does not suppress recovery elsewhere on the table")
	_expect_equal(main.remaining_balls, 3, "Stuck-ball recovery still preserves the numbered ball")
	main.free()
	await process_frame


func _sample_cradle_shot(action: StringName, fire_distance: float, follow_routes: bool = false) -> Dictionary:
	Input.action_release(&"flipper_left")
	Input.action_release(&"flipper_right")
	var scene := load("res://scenes/app/Main.tscn") as PackedScene
	var main := scene.instantiate()
	main.ball_recovery_delay = 0.35
	main.stuck_speed_threshold = 100.0
	root.add_child(main)
	await physics_frame
	main.start_game()
	main.session_state = MainNode.SessionState.PLAYING
	var flipper: Node2D = main.get_node("LeftFlipper" if action == &"flipper_left" else "RightFlipper")
	var mirror := -1.0 if action == &"flipper_right" else 1.0
	Input.action_press(action)
	for _frame in 30:
		await physics_frame
	var ball: RigidBody2D = main.balls[0]
	ball.reset_ball(flipper.global_position + Vector2(60.0 * mirror, -100.0), false)
	await physics_frame
	await physics_frame
	ball.launch_ready = false
	ball.ball_save_used = true
	ball.freeze = false
	ball.linear_velocity = Vector2(0, 60)
	for _frame in 240:
		await physics_frame
	var held: bool = not ball.drain_locked and main.remaining_balls == 3 and ball.linear_velocity.length() < 50.0 and ball.global_position.distance_to(flipper.global_position) < 100.0
	if "--trace-physics" in OS.get_cmdline_user_args():
		print("HELD ", action, " ", fire_distance, " pos=", ball.global_position, " velocity=", ball.linear_velocity, " rotation=", rad_to_deg(flipper.rotation))
	Input.action_release(action)
	var fired := false
	var shot := false
	var crossing_x := -1.0
	var routes: Array[String] = []
	var entered: Array[String] = []
	for route_name in ["WarmRamp", "ColdRamp", "UniverseOrbit"]:
		var route: Node = main.get_node(route_name + "/PhysicalRoute")
		route.traversed.connect(func(_ball: RigidBody2D) -> void: routes.append(route_name))
	for frame in (1440 if follow_routes else 480):
		await physics_frame
		if ball.route_owner != null:
			var route_name: String = ball.route_owner.get_parent().name
			if route_name not in entered:
				entered.append(route_name)
		var local_distance := (ball.global_position - flipper.global_position).rotated(-flipper.rotation).x * mirror
		if not fired and local_distance >= fire_distance:
			Input.action_press(action)
			fired = true
		if "--trace-physics" in OS.get_cmdline_user_args() and frame % 30 == 0:
			print("CRADLE ", action, " at ", fire_distance, " f=", frame, " pos=", ball.global_position, " velocity=", ball.linear_velocity, " fired=", fired)
		if fired and not shot and ball.global_position.y <= 1400.0 and ball.linear_velocity.y < 0.0:
			shot = true
			crossing_x = ball.global_position.x
			if not follow_routes:
				break
		if follow_routes and not routes.is_empty():
			break
		if main.remaining_balls != 3:
			break
	Input.action_release(action)
	var result := {"held": held, "shot": shot, "crossing_x": crossing_x, "routes": routes, "entered": entered, "end": ball.global_position}
	main.free()
	await process_frame
	return result


func _complete_cue_stack(main: Node) -> void:
	while not main.cue_manager.is_stack_completed():
		var cue = main.cue_manager.current_cue()
		for condition in cue.conditions:
			for _repetition in cue.condition_repetitions:
				main.cue_manager.add_condition(condition)
		_expect(main.cue_manager.current_cue_ready(), "Configured cue can be armed by its required shots")
		_expect(main.cue_manager.start_current_cue(), "Console can execute each armed cue")
		_expect(main.cue_manager.complete_current_cue(), "Executed cue advances the Cue Stack")


func _remove_test_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_failures.append("%s (expected %s, got %s)" % [message, expected, actual])
