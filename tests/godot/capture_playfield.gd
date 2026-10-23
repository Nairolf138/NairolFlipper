extends SceneTree

## Real GL Compatibility captures, not the headless dummy renderer.
## These frozen fixtures document art and draw order, not playability or FPS.
const OUTPUT := "res://build/visuals"
var _failed := false
var _main: Node2D
var _metrics: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Visual captures require an actual rendering display (Xvfb in CI).")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	_main = load("res://scenes/app/Main.tscn").instantiate()
	_main.pause_on_focus_loss = false # Non-interactive render fixture, not a lifecycle test.
	_main.get_node("SettingsStore").save_path = "user://tests/visual_capture_settings.json"
	root.add_child(_main)
	await process_frame
	_main.set_process(false)
	_main.set_physics_process(false)
	_main.stage_visuals.set_process(false)
	_main.playtest_recorder.set_process(false) # Posed software renders are not a device FPS test.
	_main.playtest_recorder.previous_session = {}
	for size in [Vector2i(540, 960), Vector2i(1080, 1920), Vector2i(768, 1024)]:
		# Window owns the root viewport; bypassing it through DisplayServer leaves
		# its render size stale on X11 without a window manager.
		root.size = size
		_main._show_start_menu()
		await _capture("menu", size)
		_main.start_game()
		await _capture("ready", size)
		# Deterministic, deliberately posed inspection of art in a lit show.
		_main._launch_or_restart()
		_hold_ball(Vector2(540, 1030))
		_main._request_pause()
		await _capture("pause", size)
		_main._open_playtest_report()
		await _capture("report", size)
		_main._resume_game()
		for target in get_nodes_in_group("rig_targets"):
			_main._on_rig_target_hit(target, target.family_id, target.display_name, target.score_value, target.flow_value)
		_main.stage_visuals.hit_flash = 0.0
		_main.sync_feedback_label.hide()
		_main.stage_visuals.set_beat_position(2.0, true)
		_hold_ball(Vector2(540, 1030))
		await _capture("lit_stage", size)
		# Arm directly for a rendering stress fixture, not a progression test.
		_main.show_flow.arm_final_show()
		_main._start_final_show()
		for index in 3:
			_main.balls[index].reset_ball(Vector2(430 + index * 110, 1010 + index * 130), false)
			_main.balls[index].launch_ready = false
		await _capture("final_show", size)
		_main._on_flashing_effects_selected(2)
		await _capture("effects_off", size)
		for route_name in ["WarmRamp", "ColdRamp", "UniverseOrbit"]:
			var route: Node2D = _main.get_node(route_name + "/PhysicalRoute")
			var point: Vector2 = route.curve.sample_baked(route.curve.get_baked_length() * 0.45)
			_hold_ball(route.to_global(point), route)
			await _capture("rider_" + route_name.to_snake_case(), size)
		_main._on_flashing_effects_selected(0)
	var report := FileAccess.open(OUTPUT + "/render_metrics.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({
		"renderer": RenderingServer.get_video_adapter_name(),
		"note": "Frozen art fixtures on CI software GL. Not tablet performance or physical trajectory evidence.",
		"captures": _metrics,
	}, "\t"))
	# Let already scheduled gameplay coroutines release their resources before
	# freeing the fixture. Returning to the menu invalidates their generations.
	_main._show_start_menu()
	await create_timer(_main.show_flow.final_show_duration + 0.1).timeout
	_main.free()
	await process_frame
	await process_frame
	quit(1 if _failed else 0)


func _hold_ball(point: Vector2, route: Node2D = null) -> void:
	var ball: RigidBody2D = _main.balls[0]
	ball.reset_ball(point, false)
	ball.launch_ready = false
	if route != null:
		ball.freeze = false
		if not ball.enter_route(route, route.definition.collision_layer):
			_failed = true
		ball.freeze = true
	_main.launch_button.hide()


func _capture(label: String, size: Vector2i) -> void:
	for frame in 3:
		await process_frame
		await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.is_empty() or image.get_size() != size:
		push_error("Capture invalid: %s expected %s, got %s (window %s)" % [label, size, image.get_size(), root.size])
		_failed = true
		return
	var colors: Dictionary = {}
	for y in range(0, size.y, 17):
		for x in range(0, size.x, 17):
			colors[image.get_pixel(x, y).to_html()] = true
	if colors.size() < 32:
		push_error("Capture is blank or lacks scene content: " + label)
		_failed = true
	var path := "%s/%s_%dx%d.png" % [OUTPUT, label, size.x, size.y]
	if image.save_png(path) != OK:
		_failed = true
	_metrics.append({
		"image": path.get_file(),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"texture_bytes": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
		"sampled_colors": colors.size(),
	})
	print("Visual capture: ", path, " ", _metrics.back())
