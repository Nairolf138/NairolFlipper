extends SceneTree

const Main = preload("res://scripts/app/main.gd")
const Recorder = preload("res://scripts/app/playtest_recorder.gd")
var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_local_report()
	await _test_pause_on_physical_route()
	await _test_paused_gameplay_timers()
	await _test_pending_drain_during_pause()
	for message in _failures:
		printerr("FAILED: ", message)
	print("Godot qualification tests: %s" % ("4 passed" if _failures.is_empty() else "%d failures" % _failures.size()))
	quit(0 if _failures.is_empty() else 1)


func _expect(value: bool, message: String) -> void:
	if not value:
		_failures.append(message)


func _test_local_report() -> void:
	var content := Image.create(4, 8, false, Image.FORMAT_RGBA8)
	content.fill(Color.RED)
	var framed: Image = preload("res://tests/godot/capture_frame.gd").with_black_margins(content, Vector2i(8, 8))
	_expect(framed.get_size() == Vector2i(8, 8) and content.get_size() == Vector2i(4, 8), "Capture margins never rescale the original viewport pixels")
	_expect(framed.get_pixel(0, 0) == Color.BLACK and framed.get_pixel(2, 0) == Color.RED and framed.get_pixel(5, 7) == Color.RED and framed.get_pixel(6, 7) == Color.BLACK, "KEEP capture centering preserves exact pixels with black bars")
	var path := "user://tests/qualification_recorder.json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var recorder := Recorder.new()
	recorder.save_path = path
	root.add_child(recorder)
	recorder.set_process(false)
	for hit in 100:
		recorder.record_bumper_hit(100)
	recorder.record_launch()
	recorder.record_event(&"warm_ramp")
	recorder.record_score(12345)
	_expect(not FileAccess.file_exists(path), "Impacts do not synchronously write to disk")
	for frame in 59:
		recorder.sample_frame_usec(16667)
	recorder.sample_frame_usec(100000)
	recorder.set_phase(true)
	recorder.sample_frame_usec(33334)
	recorder.sample_frame_usec(100000)
	var before: Dictionary = recorder.snapshot()
	_expect(before.frames.samples == 62 and before.frames.p95_ms_capped_250 == 17, "Frame cadence uses a bounded millisecond histogram")
	_expect(before.frames.over_50_ms == 2 and before.frames.final_show.over_50_ms == 1, "Final Show has separate cadence counters")
	_expect(absf(before.frames.final_show.average_fps - 15.0) < 0.01, "Final Show FPS is derived from observed wall time")
	before.events.warm_ramp = 99
	_expect(recorder.events.warm_ramp == 1, "Report snapshots cannot mutate live counters")
	recorder.set_capture_frames(false)
	recorder._process(Recorder.FLUSH_INTERVAL)
	_expect(recorder.snapshot().frames.samples == 62, "Menu and pause frames are excluded")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	_expect(saved.launches == 1 and saved.bumper_hits == 100 and saved.current_score == 12345, "Throttled flush preserves exact counters and real score")
	_expect(saved.build.qualification == "device_playtest_pending", "Automation cannot certify a device playtest")
	_expect("pas encore mesurée" not in recorder.report_text(), "Measured cadence is readable in the report summary")
	recorder.free()
	var reloaded := Recorder.new()
	reloaded.save_path = path
	root.add_child(reloaded)
	reloaded.set_process(false)
	_expect(reloaded.previous_session.launches == 1, "Previous opening remains consultable after relaunch")
	_expect("pas encore mesurée" in reloaded.report_text(), "An unmeasured new opening does not claim zero FPS")
	reloaded.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	await process_frame


func _new_main() -> Node2D:
	var main: Node2D = load("res://scenes/app/Main.tscn").instantiate()
	main.get_node("SettingsStore").save_path = "user://tests/qualification_settings.json"
	main.get_node("PlaytestRecorder").save_path = "user://tests/qualification_runtime.json"
	root.add_child(main)
	return main


func _test_pause_on_physical_route() -> void:
	var main := _new_main()
	await physics_frame
	main._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await process_frame
	_expect(not paused and not main.gameplay_active, "Losing focus in the menu does not start or pause a game")
	main.start_game()
	main._launch_or_restart()
	var route: Node2D = main.get_node("WarmRamp/PhysicalRoute")
	var ball: RigidBody2D = main.balls[0]
	var tangent: Vector2 = route._endpoint_tangent(route.entry_index)
	ball.reset_ball(route.to_global(route.centerline[route.entry_index]) - tangent * 80.0, false)
	await physics_frame
	await physics_frame
	ball.launch_ready = false
	ball.freeze = false
	ball.linear_velocity = tangent * 1800.0
	for frame in 60:
		await physics_frame
		if ball.route_owner == route:
			break
	_expect(ball.route_owner == route and route._riders.has(ball), "Physical ball is admitted through the real route gate")
	Input.action_press(&"flipper_left")
	Input.action_press(&"flipper_right")
	main.active_touches[4] = &"flipper_left"
	main._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	await process_frame
	await process_frame
	_expect(paused and main.game_paused and main.playtest_overlay.visible, "Background notification opens an explicit pause")
	_expect(main.active_touches.is_empty() and not Input.is_action_pressed(&"flipper_left") and not Input.is_action_pressed(&"flipper_right"), "Pause clears touch and keyboard/controller action state")
	var position_before := ball.global_position
	var velocity_before := ball.linear_velocity
	var music_before: float = main.audio_service.transport_total_beats
	var flow_before: int = main.flow_manager.flow_points
	var frames_before: int = main.playtest_recorder.snapshot().frames.samples
	await create_timer(0.16, true).timeout
	_expect(ball.global_position == position_before and ball.linear_velocity == velocity_before, "Position and velocity remain unchanged during pause")
	_expect(ball.route_owner == route and route._riders.has(ball), "Pause retains route plane and progress")
	_expect(main.audio_service.transport_total_beats == music_before and main.flow_manager.flow_points == flow_before, "Music transport and Flow do not advance while paused")
	_expect(main.playtest_recorder.snapshot().frames.samples == frames_before, "Suspension is not misreported as slow rendering")
	main._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	_expect(paused, "Focus gain never resumes the ball automatically")
	main.playtest_overlay.get_node("Panel/PauseMenu/ReportButton").pressed.emit()
	_expect(paused and main.playtest_overlay.report_menu.visible, "Report is usable while the tree is paused")
	_expect(main.playtest_overlay.report.text.contains("warm_ramp") and main.playtest_overlay.report.text.contains("Build :"), "Report includes progression and exact build identity")
	main.playtest_overlay.return_button.pressed.emit()
	_expect(paused and main.playtest_overlay.pause_menu.visible, "Back from report keeps the game paused")
	main.playtest_overlay.get_node("Panel/PauseMenu/ResumeButton").pressed.emit()
	_expect(not paused and not main.game_paused, "Resume works through the always-processing overlay")
	for frame in 900:
		await physics_frame
		if ball.route_owner == null:
			break
	_expect(main.playtest_recorder.events.warm_ramp == 1, "A real route completion still scores exactly once after interruption")
	main._request_pause()
	main.playtest_overlay.get_node("Panel/PauseMenu/MenuButton").pressed.emit()
	_expect(not paused and main.start_menu.visible and not ball.visible and ball.route_owner == null, "Returning to menu cancels pause and clears the routed ball")
	main._open_playtest_report()
	main.playtest_overlay.return_button.pressed.emit()
	_expect(not main.playtest_overlay.visible and not main.gameplay_active, "Menu report closes without implicit gameplay")
	main.free()
	await process_frame


func _test_paused_gameplay_timers() -> void:
	var main := _new_main()
	await physics_frame
	main.blackout_duration = 0.08
	main.respawn_delay = 0.08
	main.show_flow.final_show_duration = 0.08
	main.start_game()
	main._launch_or_restart()
	main.show_flow.arm_final_show()
	main._start_final_show()
	for ball in main.balls:
		ball.freeze = true
	main._request_pause()
	await create_timer(0.18, true).timeout
	_expect(main.multiball_active and main.show_flow.state == main.show_flow.State.FINAL_SHOW, "Final Show duration cannot expire in the background")
	main._resume_game()
	for frame in 60:
		await physics_frame
		if main.show_flow.state == main.show_flow.State.BLACKOUT:
			break
	_expect(main.show_flow.state == main.show_flow.State.BLACKOUT, "Final Show timer resumes normally")
	main._request_pause()
	await create_timer(0.18, true).timeout
	_expect(main.show_flow.state == main.show_flow.State.BLACKOUT, "Blackout cannot finish during pause")
	main._resume_game()
	for frame in 60:
		await physics_frame
		if main.show_flow.state == main.show_flow.State.FLOW:
			break
	_expect(main.show_flow.state == main.show_flow.State.FLOW, "Blackout returns to Flow after resume")
	main.session_state = Main.SessionState.PLAYING
	var ball: RigidBody2D = main.balls[main.active_ball_index]
	ball.ball_save_used = true
	main._resolve_ball_drain(ball)
	_expect(main.session_state == Main.SessionState.RESPAWNING, "Real drain arms the numbered-ball respawn delay")
	main._request_pause()
	await create_timer(0.18, true).timeout
	_expect(main.session_state == Main.SessionState.RESPAWNING and main.remaining_balls == 2, "Respawn delay and three-ball accounting survive pause")
	main._resume_game()
	for frame in 60:
		await physics_frame
		if main.session_state == Main.SessionState.READY:
			break
	_expect(main.session_state == Main.SessionState.READY and main.launch_button.visible, "Respawn resumes with GO and exactly two remaining balls")
	main._request_pause()
	main.restart_game()
	_expect(not paused and main.remaining_balls == 3 and main.session_state == Main.SessionState.READY, "Restart cannot strand the next game in a paused tree")
	var start := InputEventJoypadButton.new()
	start.button_index = JOY_BUTTON_START
	start.pressed = true
	_expect(start.is_action_pressed("pause"), "Controller Start is mapped to the common pause action")
	main._unhandled_input(start)
	_expect(paused, "The controller can pause a ready numbered ball")
	main._resume_game()
	main.free()
	await process_frame


func _test_pending_drain_during_pause() -> void:
	var main := _new_main()
	await physics_frame
	main.start_game()
	main._launch_or_restart()
	var ball: RigidBody2D = main.balls[0]
	ball.freeze = true
	ball.ball_save_used = true
	# Reproduce an Area2D drain signal queued immediately before OS suspension.
	main._on_drain_body_entered(ball)
	main._request_pause()
	await process_frame
	await process_frame
	_expect(main.remaining_balls == 3 and main.session_state == Main.SessionState.PLAYING, "An already queued drain must not consume a ball during pause")
	main._resume_game()
	await process_frame
	await process_frame
	_expect(main.remaining_balls == 2, "The pending drain resolves exactly once after resume")
	main.restart_game()
	main._launch_or_restart()
	ball.freeze = true
	ball.ball_save_used = true
	main._on_drain_body_entered(ball)
	main._request_pause()
	await process_frame
	main._resume_game()
	# Reset and GO in the same frame must invalidate the old queued callback.
	main.restart_game()
	main._launch_or_restart()
	ball.freeze = true
	ball.ball_save_used = true
	await process_frame
	await process_frame
	_expect(main.remaining_balls == 3 and not ball.drain_locked, "A stale pre-pause drain cannot affect a reset and relaunched ball")
	main.free()
	await process_frame
