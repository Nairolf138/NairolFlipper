extends SceneTree

const CueDefinitionResource = preload("res://scripts/show/cue_definition.gd")
const CueManagerNode = preload("res://scripts/show/cue_manager.gd")
const FlowManagerNode = preload("res://scripts/show/flow_manager.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_flow_decay_and_multiplier()
	_test_cue_bonus_and_reset()
	await _test_main_scene_scoring_and_reset()
	await _test_physics_drain_lifecycle()
	await _test_android_playtest_regressions()
	# Give the audio server and deferred frees time to release stream references.
	await process_frame
	await process_frame

	if _failures.is_empty():
		print("Godot behavioral tests: 5 passed")
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


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_failures.append("%s (expected %s, got %s)" % [message, expected, actual])
