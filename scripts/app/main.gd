extends Node2D

const AudioServiceNode = preload("res://scripts/audio/audio_service.gd")
const CueManagerNode = preload("res://scripts/show/cue_manager.gd")
const FlowManagerNode = preload("res://scripts/show/flow_manager.gd")
const PlaytestRecorderNode = preload("res://scripts/app/playtest_recorder.gd")
const RigModelNode = preload("res://scripts/show/rig_model.gd")
const ShowFlowManagerNode = preload("res://scripts/show/show_flow_manager.gd")
const StageVisualControllerNode = preload("res://scripts/show/stage_visual_controller.gd")
const SyncBonusManagerNode = preload("res://scripts/show/sync_bonus_manager.gd")

enum SessionState {
	MENU,
	READY,
	PLAYING,
	RESPAWNING,
	GAME_OVER,
}

@onready var score_manager = $ScoreManager
@onready var flow_manager: FlowManagerNode = $FlowManager
@onready var score_label: Label = $ScoreLabel
@onready var flow_label: Label = $FlowLabel
@onready var balls: Array[Node] = [$BallOne, $BallTwo, $BallThree]
@onready var drain: Area2D = $Drain
@onready var status_label: Label = $StatusLabel
@onready var rig_progress_label: Label = $RigProgressLabel
@onready var show_state_label: Label = $ShowStateLabel
@onready var cue_progress_label: Label = $Interface/GameControls/CueProgressLabel
@onready var stage_visuals: StageVisualControllerNode = $StageVisuals
@onready var playtest_recorder: PlaytestRecorderNode = $PlaytestRecorder
@onready var cue_manager: CueManagerNode = $CueManager
@onready var audio_service: AudioServiceNode = $AudioService
@onready var rig_model: RigModelNode = $RigModel
@onready var show_flow: ShowFlowManagerNode = $ShowFlowManager
@onready var sync_bonus_manager: SyncBonusManagerNode = $SyncBonusManager
@onready var start_overlay: Control = $Interface/StartOverlay
@onready var game_controls: Control = $Interface/GameControls
@onready var play_button: Button = $Interface/StartOverlay/Menu/PlayButton
@onready var menu_quit_button: Button = $Interface/StartOverlay/Menu/QuitButton
@onready var reset_button: Button = $Interface/GameControls/ResetButton
@onready var game_quit_button: Button = $Interface/GameControls/QuitButton
@onready var game_over_overlay: Control = $Interface/GameOverOverlay
@onready var final_score_label: Label = $Interface/GameOverOverlay/Menu/FinalScoreLabel
@onready var replay_button: Button = $Interface/GameOverOverlay/Menu/ReplayButton
@onready var game_over_menu_button: Button = $Interface/GameOverOverlay/Menu/MenuButton
@onready var final_show_label: Label = $Interface/GameControls/FinalShowLabel
@onready var sync_feedback_label: Label = $Interface/GameControls/SyncFeedbackLabel
@onready var blackout_overlay: Control = $Interface/BlackoutOverlay

@export var respawn_delay: float = 1.0
@export var ball_recovery_delay: float = 5.0
@export var stuck_speed_threshold: float = 18.0
@export var recovery_margin: float = 100.0
@export var blackout_duration: float = 1.1

var remaining_balls: int = 3
var active_ball_index: int = 0
var game_over: bool = false
var gameplay_active: bool = false
var session_state: int = SessionState.MENU
var active_touches: Dictionary[int, StringName] = {}
var stalled_ball_time: float = 0.0
var session_generation: int = 0
var multiball_active: bool = false
var show_generation: int = 0
var _sync_feedback_tween: Tween


func _ready() -> void:
	for ball in balls:
		ball.ball_drained.connect(_on_ball_drained)
		ball.input_enabled = false
	for flipper in [$LeftFlipper, $RightFlipper]:
		flipper.activated.connect(_on_flipper_activated)
	drain.body_entered.connect(_on_drain_body_entered)
	for bumper in get_tree().get_nodes_in_group("score_bumpers"):
		bumper.bumper_hit.connect(_on_bumper_hit)
	for ramp in get_tree().get_nodes_in_group("show_ramps"):
		ramp.ramp_completed.connect(_on_ramp_completed)
	for scoop in get_tree().get_nodes_in_group("console_scoops"):
		scoop.scoop_completed.connect(_on_scoop_completed)
	for target in get_tree().get_nodes_in_group("rig_targets"):
		target.target_hit.connect(_on_rig_target_hit)
	for lane in get_tree().get_nodes_in_group("table_lanes"):
		lane.lane_completed.connect(_on_lane_completed)
	for slingshot in get_tree().get_nodes_in_group("slingshots"):
		slingshot.slingshot_hit.connect(_on_slingshot_hit)
	score_manager.score_changed.connect(_on_score_changed)
	flow_manager.flow_changed.connect(_on_flow_changed)
	cue_manager.audio_changes_requested.connect(audio_service.apply_cue_changes)
	cue_manager.cue_started.connect(_on_cue_started)
	cue_manager.cue_completed.connect(_on_cue_completed)
	cue_manager.bonus_awarded.connect(_on_cue_bonus_awarded)
	cue_manager.stack_progress_changed.connect(_on_cue_stack_progress_changed)
	cue_manager.stack_completed.connect(_on_cue_stack_completed)
	show_flow.state_changed.connect(_on_show_state_changed)
	sync_bonus_manager.sync_awarded.connect(_on_sync_awarded)
	audio_service.transport_changed.connect(_on_transport_changed)
	play_button.pressed.connect(start_game)
	menu_quit_button.pressed.connect(_on_quit_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	game_quit_button.pressed.connect(_on_quit_pressed)
	replay_button.pressed.connect(start_game)
	game_over_menu_button.pressed.connect(_show_start_menu)
	restart_game()
	_show_start_menu()


func _physics_process(delta: float) -> void:
	if session_state != SessionState.PLAYING:
		stalled_ball_time = 0.0
		return
	if multiball_active:
		for candidate in balls:
			if candidate.visible and not candidate.freeze and not candidate.drain_locked:
				if _is_ball_outside_playfield(candidate.global_position):
					candidate.mark_drained()
		return
	if active_ball_index < 0 or active_ball_index >= balls.size():
		return
	var ball: RigidBody2D = balls[active_ball_index]
	if ball.freeze or ball.drain_locked:
		return
	if _is_ball_outside_playfield(ball.global_position):
		_recover_active_ball("BALL RECOVERED — TOUCH TOP")
		return
	if ball.linear_velocity.length() <= stuck_speed_threshold:
		stalled_ball_time += delta
	else:
		stalled_ball_time = 0.0
	if stalled_ball_time >= ball_recovery_delay:
		_recover_active_ball("BALL RECOVERED — TOUCH TOP")


func _unhandled_input(event: InputEvent) -> void:
	if not gameplay_active:
		return
	if event.is_action_pressed("launch_ball"):
		_launch_or_restart()
	elif event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event)


func _launch_or_restart() -> void:
	if not gameplay_active or session_state != SessionState.READY:
		return
	if balls[active_ball_index].launch_ball():
		session_state = SessionState.PLAYING
		show_flow.begin_build()
		stalled_ball_time = 0.0
		playtest_recorder.record_launch()
		audio_service.request_sfx(&"launcher")


func start_game() -> void:
	gameplay_active = true
	start_overlay.hide()
	game_over_overlay.hide()
	game_controls.show()
	cue_progress_label.show()
	restart_game()
	status_label.text = "BALL 1 / %d — TOUCH TOP TO LAUNCH" % balls.size()


func _show_start_menu() -> void:
	session_generation += 1
	session_state = SessionState.MENU
	gameplay_active = false
	game_over = false
	show_generation += 1
	multiball_active = false
	show_flow.enter_standby()
	audio_service.stop_transport(true)
	start_overlay.show()
	game_over_overlay.hide()
	blackout_overlay.hide()
	final_show_label.hide()
	sync_feedback_label.hide()
	game_controls.hide()
	_release_all_touches()
	_deactivate_all_balls()


func _show_game_over() -> void:
	session_state = SessionState.GAME_OVER
	game_over = true
	show_generation += 1
	multiball_active = false
	show_flow.enter_standby()
	audio_service.stop_transport(true)
	gameplay_active = false
	stalled_ball_time = 0.0
	_release_all_touches()
	_deactivate_all_balls()
	game_controls.hide()
	final_score_label.text = "SCORE FINAL %06d" % score_manager.score
	game_over_overlay.show()
	blackout_overlay.hide()
	final_show_label.hide()
	sync_feedback_label.hide()
	status_label.text = "GAME OVER"


func _on_reset_pressed() -> void:
	if not gameplay_active:
		return
	playtest_recorder.record_restart()
	restart_game()
	status_label.text = "BALL 1 / %d — TOUCH TOP TO LAUNCH" % balls.size()


func _on_quit_pressed() -> void:
	playtest_recorder.save_session()
	get_tree().quit()


func _on_flipper_activated(_action_name: StringName) -> void:
	if gameplay_active and session_state in [SessionState.READY, SessionState.PLAYING]:
		audio_service.request_sfx(&"flipper")


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if event.position.y < get_viewport_rect().size.y * 0.65:
			_launch_or_restart()
			return
		var action := _flipper_action_for_position(event.position)
		active_touches[event.index] = action
		Input.action_press(action)
	else:
		_release_touch(event.index)


func _handle_touch_drag(event: InputEventScreenDrag) -> void:
	if not active_touches.has(event.index):
		return
	var previous_action: StringName = active_touches[event.index]
	var action := _flipper_action_for_position(event.position)
	if action == previous_action:
		return
	Input.action_release(previous_action)
	Input.action_press(action)
	active_touches[event.index] = action


func _release_touch(touch_index: int) -> void:
	if not active_touches.has(touch_index):
		return
	Input.action_release(active_touches[touch_index])
	active_touches.erase(touch_index)


func _flipper_action_for_position(touch_position: Vector2) -> StringName:
	if touch_position.x < get_viewport_rect().size.x * 0.5:
		return &"flipper_left"
	return &"flipper_right"


func _on_bumper_hit(points: int, _bumper_name: StringName) -> void:
	_add_score_with_flow(points)
	flow_manager.add_flow(points)
	cue_manager.add_condition(&"bumper_hit")
	playtest_recorder.record_bumper_hit(points)
	audio_service.request_sfx(StringName(String(_bumper_name).to_snake_case()))
	stage_visuals.trigger_hit(Color("ff2bd6"))
	_register_sync_hit()


func _on_ramp_completed(ramp_id: StringName, score_value: int, flow_value: int) -> void:
	_add_score_with_flow(score_value)
	flow_manager.add_flow(flow_value)
	cue_manager.add_condition(ramp_id)
	status_label.text = "CUE READY — HIT CONSOLE" if cue_manager.current_cue_ready() else "RAMP HIT"
	audio_service.request_sfx(&"ramp")
	stage_visuals.trigger_hit(Color("ffb14a") if ramp_id == &"warm_ramp" else Color("00e5ff"))
	_register_sync_hit()


func _on_rig_target_hit(
	target: Node,
	family_id: StringName,
	display_name: String,
	score_value: int,
	flow_value: int
) -> void:
	_add_score_with_flow(score_value)
	flow_manager.add_flow(flow_value)
	var activated := rig_model.activate_family(family_id)
	if activated:
		target.set_lit(true)
		stage_visuals.trigger_hit(target.target_color)
		var active_count := _active_rig_family_count()
		if active_count >= get_tree().get_nodes_in_group("rig_targets").size():
			_add_score_with_flow(1500)
			flow_manager.add_flow(200)
			if not _try_arm_final_show():
				status_label.text = "RIG READY — COMPLETE CUE STACK"
			audio_service.request_sfx(&"cue")
		else:
			status_label.text = "%s ONLINE — %d / 6" % [display_name.to_upper(), active_count]
	_update_rig_progress()
	_register_sync_hit()


func _on_lane_completed(
	lane_id: StringName,
	display_name: String,
	score_value: int,
	flow_value: int
) -> void:
	_add_score_with_flow(score_value)
	flow_manager.add_flow(flow_value)
	cue_manager.add_condition(lane_id)
	status_label.text = (
		"CUE READY — HIT CONSOLE"
		if cue_manager.current_cue_ready()
		else "%s +%d" % [display_name.to_upper(), score_value]
	)
	audio_service.request_sfx(&"ramp")
	stage_visuals.trigger_hit(Color("7c4dff"))
	_register_sync_hit()


func _on_slingshot_hit(score_value: int, flow_value: int, _slingshot_name: StringName) -> void:
	_add_score_with_flow(score_value)
	flow_manager.add_flow(flow_value)
	status_label.text = "SLINGSHOT"
	audio_service.request_sfx(&"flipper")
	stage_visuals.trigger_hit(Color("ff2bd6"))
	_register_sync_hit()


func _active_rig_family_count() -> int:
	var count := 0
	for target in get_tree().get_nodes_in_group("rig_targets"):
		if rig_model.is_family_active(target.family_id):
			count += 1
	return count


func _update_rig_progress() -> void:
	var targets := get_tree().get_nodes_in_group("rig_targets")
	var active_count := _active_rig_family_count()
	rig_progress_label.text = "RIG %d / %d" % [active_count, targets.size()]
	stage_visuals.set_rig_progress(active_count)
	for target in targets:
		target.set_lit(rig_model.is_family_active(target.family_id))
	_update_stage_identity()


func _on_scoop_completed(_scoop_id: StringName, score_value: int, flow_value: int) -> void:
	_add_score_with_flow(score_value)
	flow_manager.add_flow(flow_value)
	audio_service.request_sfx(&"scoop")
	stage_visuals.trigger_hit(Color("eaf6ff"))
	_register_sync_hit()
	if show_flow.can_start_final_show():
		_start_final_show()
		return
	if cue_manager.start_current_cue():
		return
	if cue_manager.active_cue != null:
		status_label.text = "CUE RUNNING"
	elif cue_manager.is_stack_completed():
		status_label.text = "CUE STACK READY — COMPLETE RIG"
	else:
		var cue = cue_manager.current_cue()
		status_label.text = "CUE INCOMPLETE — %s" % cue.objective_text


func _on_cue_started(_cue_id: StringName) -> void:
	var cue = cue_manager.active_cue
	if cue == null:
		return
	cue_progress_label.text = "GO  •  %s" % cue.display_name
	status_label.text = "GO — %s" % cue.display_name
	_update_cue_shot_highlights()
	stage_visuals.trigger_hit(Color("eaf6ff"))


func _on_cue_completed(_cue_id: StringName) -> void:
	status_label.text = "CUE COMPLETE"
	stage_visuals.trigger_hit(Color("7c4dff"))


func _on_cue_stack_progress_changed(
	cue_number: int,
	total_cues: int,
	display_name: String,
	objective_text: String,
	completed_shots: int,
	required_shots: int,
	ready: bool
) -> void:
	var instruction := "HIT CONSOLE" if ready else objective_text
	cue_progress_label.text = "CUE %d / %d  •  %s\n%s  %d / %d" % [
		cue_number,
		total_cues,
		display_name,
		instruction,
		completed_shots,
		required_shots,
	]
	if ready:
		status_label.text = "CUE READY — HIT CONSOLE"
	_update_cue_shot_highlights()


func _on_cue_stack_completed() -> void:
	var cue_count := cue_manager.cues.size()
	cue_progress_label.text = "CUE STACK  %d / %d  •  COMPLETE" % [cue_count, cue_count]
	_update_cue_shot_highlights()
	if not _try_arm_final_show():
		status_label.text = "CUE STACK READY — COMPLETE RIG"


func _try_arm_final_show() -> bool:
	var rig_complete := _active_rig_family_count() >= get_tree().get_nodes_in_group("rig_targets").size()
	if not rig_complete or not cue_manager.is_stack_completed():
		return false
	if show_flow.can_start_final_show():
		return true
	if not show_flow.arm_final_show():
		return false
	status_label.text = "FINAL SHOW ARMED — HIT CONSOLE"
	audio_service.request_sfx(&"cue")
	return true


func _update_cue_shot_highlights() -> void:
	for ramp in get_tree().get_nodes_in_group("show_ramps"):
		if ramp.has_method("set_objective_highlight"):
			ramp.set_objective_highlight(cue_manager.condition_is_pending(ramp.definition.ramp_id))
	for lane in get_tree().get_nodes_in_group("table_lanes"):
		if lane.has_method("set_objective_highlight"):
			lane.set_objective_highlight(cue_manager.condition_is_pending(lane.lane_id))
	var bumpers_are_objective := cue_manager.condition_is_pending(&"bumper_hit")
	for bumper in get_tree().get_nodes_in_group("score_bumpers"):
		if bumper.has_method("set_objective_highlight"):
			bumper.set_objective_highlight(bumpers_are_objective)


func _on_cue_bonus_awarded(points: int) -> void:
	_add_score_with_flow(points)
	audio_service.request_sfx(&"cue")


func _register_sync_hit() -> void:
	if (
		not gameplay_active
		or session_state != SessionState.PLAYING
		or show_flow.state == ShowFlowManagerNode.State.BLACKOUT
	):
		return
	sync_bonus_manager.register_hit(
		audio_service.transport_total_beats,
		audio_service.transport_playing
	)


func _on_sync_awarded(
	tier: StringName,
	score_bonus: int,
	flow_bonus: int,
	_distance_beats: float
) -> void:
	var show_multiplier := show_flow.final_show_score_multiplier if multiball_active else 1
	score_manager.add_points(score_bonus * show_multiplier)
	flow_manager.add_flow(flow_bonus)
	playtest_recorder.record_sync(tier)
	audio_service.request_sfx(&"sync")
	var perfect := tier == &"perfect"
	var label := "PERFECT SYNC" if perfect else "SYNC"
	sync_feedback_label.text = "%s  +%d  •  FLOW +%d" % [label, score_bonus * show_multiplier, flow_bonus]
	sync_feedback_label.add_theme_color_override(
		"font_color",
		Color("ffca4a") if perfect else Color("00e5ff")
	)
	sync_feedback_label.modulate = Color.WHITE
	sync_feedback_label.show()
	stage_visuals.trigger_hit(Color("ffca4a") if perfect else Color("00e5ff"))
	if is_instance_valid(_sync_feedback_tween):
		_sync_feedback_tween.kill()
	_sync_feedback_tween = create_tween()
	_sync_feedback_tween.tween_interval(0.45)
	_sync_feedback_tween.tween_property(sync_feedback_label, "modulate", Color(1, 1, 1, 0), 0.35)
	_sync_feedback_tween.tween_callback(sync_feedback_label.hide)


func _on_transport_changed(position_beats: float, playing: bool) -> void:
	stage_visuals.set_beat_position(position_beats, playing)


func _add_score_with_flow(points: int) -> void:
	if points <= 0:
		return
	var show_multiplier := show_flow.final_show_score_multiplier if multiball_active else 1
	score_manager.add_points(points * flow_manager.multiplier * show_multiplier)


func _on_show_state_changed(state: int, display_name: String) -> void:
	show_state_label.text = "SHOW  %s" % display_name
	stage_visuals.set_show_state(state)
	_update_stage_identity()


func _update_stage_identity() -> void:
	if not is_node_ready() or not gameplay_active:
		return
	var levels: Dictionary = {
		&"atmosphere": 0.0,
		&"piano": 0.0,
		&"kick": 0.0,
		&"percussion": 0.0,
		&"bass": 0.0,
		&"arp": 0.0,
		&"lead": 0.0,
		&"impact": 0.0,
	}
	var active_count := _active_rig_family_count()
	match show_flow.state:
		ShowFlowManagerNode.State.PRESET:
			levels[&"atmosphere"] = 0.5
			levels[&"piano"] = 0.16
		ShowFlowManagerNode.State.BUILD:
			levels[&"atmosphere"] = 0.58
			levels[&"piano"] = 0.34
			levels[&"kick"] = 0.42 if active_count >= 2 else 0.0
			levels[&"bass"] = 0.38 if active_count >= 3 else 0.0
			levels[&"percussion"] = 0.34 if active_count >= 4 else 0.0
			levels[&"arp"] = 0.32 if active_count >= 5 else 0.0
		ShowFlowManagerNode.State.FLOW:
			levels[&"atmosphere"] = 0.62
			levels[&"piano"] = 0.42
			levels[&"kick"] = 0.5
			levels[&"percussion"] = 0.42
			levels[&"bass"] = 0.45
			levels[&"arp"] = 0.38
			levels[&"lead"] = 0.16 if flow_manager.multiplier >= 3 else 0.0
		ShowFlowManagerNode.State.FINAL_SHOW:
			levels = {
				&"atmosphere": 0.68,
				&"piano": 0.5,
				&"kick": 0.65,
				&"percussion": 0.58,
				&"bass": 0.58,
				&"arp": 0.52,
				&"lead": 0.46,
				&"impact": 0.65,
			}
	audio_service.set_stem_mix(levels)


func _start_final_show() -> void:
	if multiball_active or not show_flow.start_final_show():
		return
	multiball_active = true
	show_generation += 1
	var generation := show_generation
	stalled_ball_time = 0.0
	final_show_label.text = "FINAL SHOW  •  3 BALLS  •  SCORE x%d" % show_flow.final_show_score_multiplier
	cue_progress_label.hide()
	final_show_label.show()
	blackout_overlay.hide()
	_add_score_with_flow(3000)
	audio_service.request_sfx(&"cue")
	var spawn_offsets: Array[Vector2] = [Vector2(0, -180), Vector2(0, -90), Vector2.ZERO]
	var launch_directions: Array[Vector2] = [
		Vector2(-0.32, -1.0),
		Vector2(-0.20, -1.0),
		Vector2(-0.08, -1.0),
	]
	for index in balls.size():
		var ball: RigidBody2D = balls[index]
		ball.reset_ball(ball.spawn_position + spawn_offsets[index])
		ball.ball_save_used = true
		ball.ball_save_remaining = 0.0
		ball.launch_ready = false
		ball.freeze = false
		ball.apply_central_impulse(launch_directions[index].normalized() * ball.launch_force)
	active_ball_index = 0
	status_label.text = "FINAL SHOW — KEEP 2+ BALLS ALIVE"
	_run_final_show_timer(generation)


func _run_final_show_timer(generation: int) -> void:
	await get_tree().create_timer(show_flow.final_show_duration).timeout
	if generation == show_generation and multiball_active:
		_finish_final_show("FINAL SHOW COMPLETE")


func _active_multiball_balls() -> Array[Node]:
	var active: Array[Node] = []
	for ball in balls:
		if ball.visible and not ball.drain_locked:
			active.append(ball)
	return active


func _on_multiball_ball_drained(_ball: RigidBody2D) -> void:
	var active := _active_multiball_balls()
	if active.size() <= 1:
		_finish_final_show("FINAL SHOW COMPLETE")
	else:
		status_label.text = "FINAL SHOW — %d BALLS" % active.size()


func _finish_final_show(message: String) -> void:
	if not multiball_active:
		return
	multiball_active = false
	show_generation += 1
	var survivors := _active_multiball_balls()
	var survivor: Node = survivors[0] if not survivors.is_empty() else null
	if survivor == null:
		survivor = balls[active_ball_index]
		survivor.reset_ball(survivor.spawn_position, false)
		session_state = SessionState.READY
	else:
		active_ball_index = balls.find(survivor)
		session_state = SessionState.PLAYING
	for ball in balls:
		if ball != survivor:
			ball.deactivate_ball()
	show_flow.start_blackout()
	final_show_label.hide()
	sync_feedback_label.hide()
	cue_progress_label.show()
	blackout_overlay.show()
	status_label.text = "BLACKOUT — %s" % message
	audio_service.request_sfx(&"drain")
	_run_blackout_timer(show_generation)


func _run_blackout_timer(generation: int) -> void:
	await get_tree().create_timer(blackout_duration).timeout
	if generation != show_generation or game_over:
		return
	blackout_overlay.hide()
	show_flow.finish_blackout()
	if session_state == SessionState.READY:
		status_label.text = "SHOW COMPLETE — TOUCH TOP"
	else:
		status_label.text = "SHOW COMPLETE — KEEP PLAYING"


func _on_score_changed(new_score: int) -> void:
	score_label.text = "SCORE %06d" % new_score


func _on_flow_changed(flow_points: int, multiplier: int) -> void:
	flow_label.text = "FLOW %04d  x%d" % [flow_points, multiplier]
	stage_visuals.set_flow(flow_points)
	_update_stage_identity()


func _on_drain_body_entered(body: Node) -> void:
	if (
		session_state == SessionState.PLAYING
		and body in balls
		and not body.drain_locked
		and (multiball_active or body == balls[active_ball_index])
	):
		# Area2D emits body_entered while the physics server is flushing its
		# queries. Resolve the drain once the physics step has completed.
		call_deferred("_resolve_ball_drain", body)


func _resolve_ball_drain(body: Node) -> void:
	if (
		session_state != SessionState.PLAYING
		or not is_instance_valid(body)
		or body not in balls
		or (not multiball_active and body != balls[active_ball_index])
		or body.drain_locked
	):
		return
	if body.try_ball_save():
		playtest_recorder.record_ball_save()
		audio_service.request_sfx(&"safety")
		body.reset_ball(body.spawn_position, false)
		session_state = SessionState.READY
		stalled_ball_time = 0.0
		status_label.text = "SAFETY — SAME BALL — TOUCH TOP"
		return
	playtest_recorder.record_drain()
	audio_service.request_sfx(&"drain")
	body.mark_drained()


func _on_ball_drained(ball: RigidBody2D) -> void:
	if multiball_active:
		_on_multiball_ball_drained(ball)
		return
	if (
		session_state != SessionState.PLAYING
		or active_ball_index < 0
		or active_ball_index >= balls.size()
		or ball != balls[active_ball_index]
	):
		return
	session_state = SessionState.RESPAWNING
	stalled_ball_time = 0.0
	remaining_balls -= 1
	if remaining_balls <= 0:
		_show_game_over()
		return
	active_ball_index = balls.size() - remaining_balls
	status_label.text = "BALL %d / %d" % [active_ball_index + 1, balls.size()]
	var generation := session_generation
	await get_tree().create_timer(respawn_delay).timeout
	if generation == session_generation and session_state == SessionState.RESPAWNING:
		balls[active_ball_index].reset_ball(balls[active_ball_index].spawn_position)
		session_state = SessionState.READY
		status_label.text = "BALL %d / %d — TOUCH TOP" % [active_ball_index + 1, balls.size()]


func restart_game() -> void:
	session_generation += 1
	show_generation += 1
	_release_all_touches()
	remaining_balls = balls.size()
	active_ball_index = 0
	game_over = false
	multiball_active = false
	session_state = SessionState.READY
	stalled_ball_time = 0.0
	game_over_overlay.hide()
	blackout_overlay.hide()
	final_show_label.hide()
	sync_feedback_label.hide()
	cue_progress_label.show()
	score_manager.reset_score()
	flow_manager.reset_flow()
	sync_bonus_manager.reset_state()
	cue_manager.reset_state()
	rig_model.reset_state()
	audio_service.reset_state()
	show_flow.reset_show()
	for ramp in get_tree().get_nodes_in_group("show_ramps"):
		if ramp.has_method("reset"):
			ramp.reset()
	for scoop in get_tree().get_nodes_in_group("console_scoops"):
		if scoop.has_method("reset"):
			scoop.reset()
	for target in get_tree().get_nodes_in_group("rig_targets"):
		target.reset()
	for lane in get_tree().get_nodes_in_group("table_lanes"):
		lane.reset()
	for slingshot in get_tree().get_nodes_in_group("slingshots"):
		slingshot.reset()
	cue_manager.refresh_progress()
	_update_rig_progress()
	_deactivate_all_balls()
	balls[active_ball_index].reset_ball(balls[active_ball_index].spawn_position)
	status_label.text = "BALL 1 / %d" % balls.size()
	if gameplay_active:
		audio_service.start_transport()
		_update_stage_identity()


func _recover_active_ball(message: String) -> void:
	if session_state != SessionState.PLAYING:
		return
	var ball: Node = balls[active_ball_index]
	ball.reset_ball(ball.spawn_position, false)
	session_state = SessionState.READY
	stalled_ball_time = 0.0
	status_label.text = message
	audio_service.request_sfx(&"safety")


func _is_ball_outside_playfield(ball_position: Vector2) -> bool:
	var viewport_size := get_viewport_rect().size
	return (
		ball_position.x < -recovery_margin
		or ball_position.x > viewport_size.x + recovery_margin
		or ball_position.y < -recovery_margin
		or ball_position.y > viewport_size.y + recovery_margin
	)


func _deactivate_all_balls() -> void:
	for ball in balls:
		ball.deactivate_ball()


func _release_all_touches() -> void:
	for action in active_touches.values():
		Input.action_release(action)
	active_touches.clear()
