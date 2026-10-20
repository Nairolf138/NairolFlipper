extends SceneTree

const CueDefinitionResource = preload("res://scripts/show/cue_definition.gd")
const CueManagerNode = preload("res://scripts/show/cue_manager.gd")
const FlowManagerNode = preload("res://scripts/show/flow_manager.gd")
const ShowFlowManagerNode = preload("res://scripts/show/show_flow_manager.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_flow_decay_and_multiplier()
	_test_cue_bonus_and_reset()
	_test_show_flow_state_machine()
	await _test_main_scene_scoring_and_reset()
	await _test_physics_drain_lifecycle()
	await _test_android_playtest_regressions()
	await _test_three_ball_game_over_and_recovery()
	await _test_table_2_objectives_and_routes()
	await _test_final_show_multiball_and_blackout()
	# Give the audio server and deferred frees time to release stream references.
	await process_frame
	await process_frame

	if _failures.is_empty():
		print("Godot behavioral tests: 9 passed")
		quit(0)
		return

	for failure in _failures:
		printerr("FAILED: %s" % failure)
	printerr("Godot behavioral tests: %d failure(s)" % _failures.size())
	quit(1)


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


func _test_cue_bonus_and_reset() -> void:
	var manager := CueManagerNode.new()
	var cue := CueDefinitionResource.new()
	cue.cue_id = &"test_cue"
	cue.conditions = [&"ready"]
	cue.bonus_points = 250
	manager.cues = [cue]

	var awarded_points: Array[int] = []
	manager.bonus_awarded.connect(func(points: int) -> void: awarded_points.append(points))
	manager.add_condition(&"ready")
	_expect(manager.start_cue(&"test_cue"), "Eligible cue starts")
	_expect(manager.complete_current_cue(), "Active cue completes")
	_expect_equal(awarded_points, [250], "Cue completion emits its configured bonus")

	manager.add_condition(&"ready")
	_expect(manager.start_cue(&"test_cue"), "Cue can start again before reset")
	manager.reset_state()
	_expect(manager.active_cue == null, "Cue reset clears the active cue")
	_expect(not manager.start_cue(&"test_cue"), "Cue reset clears satisfied conditions")
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

	main.cue_manager.add_condition(&"console_validated")
	_expect(main.cue_manager.start_cue(&"first_hit"), "Configured first cue starts")
	main.cue_manager.complete_current_cue()
	_expect_equal(main.score_manager.score, 520, "Cue bonus reaches ScoreManager with Flow multiplier")

	_expect(main.rig_model.activate_family(&"front_wash"), "Rig family activates")
	main.audio_service.set_stem_level(&"piano", 1.0)
	main.audio_service.seek_transport(4.0)
	main.audio_service.start_transport()
	main.restart_game()

	_expect_equal(main.score_manager.score, 0, "Restart resets score")
	_expect_equal(main.flow_manager.flow_points, 0, "Restart resets Flow")
	_expect_equal(main.flow_manager.multiplier, 1, "Restart resets multiplier")
	_expect(main.cue_manager.active_cue == null, "Restart clears the active cue")
	_expect(not main.cue_manager.start_cue(&"first_hit"), "Restart clears cue conditions")
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
	for frame in 12:
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
	var minimum_x := start_position.x
	var minimum_y := start_position.y
	for frame in 60:
		await physics_frame
		minimum_x = minf(minimum_x, ball.global_position.x)
		minimum_y = minf(minimum_y, ball.global_position.y)
	_expect(minimum_y < start_position.y - 300.0, "Launcher sends the ball upward")
	_expect(minimum_x < start_position.x - 60.0, "Launcher feeds the ball left into the playfield")
	_expect_equal(main.audio_service.last_sfx_id, &"launcher", "Launcher requests audible feedback")

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
			for frame in 20:
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
	_expect(main.status_label.text.begins_with("BALL RECOVERED"), "Recovery explains how to relaunch")

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

	var rig_targets := main.get_tree().get_nodes_in_group("rig_targets")
	_expect_equal(rig_targets.size(), 6, "Table 2.0 exposes six readable Rig targets")
	_expect(main.get_node("UniverseOrbit") != null, "Table 2.0 exposes the Universe Orbit")
	_expect(main.get_node("LeftSlingshot") != null and main.get_node("RightSlingshot") != null, "Table 2.0 exposes two active slingshots")
	_expect(main.get_node("LeftOutlaneRail") is StaticBody2D, "Table 2.0 left outlane has physical guidance")
	_expect(main.get_node("LauncherDivider") is StaticBody2D, "Table 2.0 launcher is physically separated")

	var starting_score: int = main.score_manager.score
	for target in rig_targets:
		main._on_rig_target_hit(target, target.family_id, target.display_name, target.score_value, target.flow_value)
	_expect_equal(main._active_rig_family_count(), 6, "Every Rig family can be activated from the table")
	_expect_equal(main.rig_progress_label.text, "RIG 6 / 6", "Rig objective reports complete progress")
	_expect_equal(main.status_label.text, "FINAL SHOW ARMED — HIT CONSOLE", "Completing the Rig reveals the next shot")
	_expect(main.score_manager.score > starting_score + 1500, "Rig targets and completion award score")
	for target in rig_targets:
		_expect(target.lit, "Activated Rig targets remain visibly lit")

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


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_failures.append("%s (expected %s, got %s)" % [message, expected, actual])
