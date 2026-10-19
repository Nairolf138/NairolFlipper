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

	if _failures.is_empty():
		print("Godot behavioral tests: 3 passed")
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

	main.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_failures.append("%s (expected %s, got %s)" % [message, expected, actual])
