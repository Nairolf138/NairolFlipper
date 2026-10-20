extends Node2D

const AudioServiceNode = preload("res://scripts/audio/audio_service.gd")
const CueManagerNode = preload("res://scripts/show/cue_manager.gd")
const FlowManagerNode = preload("res://scripts/show/flow_manager.gd")
const PlaytestRecorderNode = preload("res://scripts/app/playtest_recorder.gd")
const RigModelNode = preload("res://scripts/show/rig_model.gd")

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
@onready var playtest_recorder: PlaytestRecorderNode = $PlaytestRecorder
@onready var cue_manager: CueManagerNode = $CueManager
@onready var audio_service: AudioServiceNode = $AudioService
@onready var rig_model: RigModelNode = $RigModel
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

@export var respawn_delay: float = 1.0
@export var ball_recovery_delay: float = 5.0
@export var stuck_speed_threshold: float = 18.0
@export var recovery_margin: float = 100.0

var remaining_balls: int = 3
var active_ball_index: int = 0
var game_over: bool = false
var gameplay_active: bool = false
var session_state: int = SessionState.MENU
var active_touches: Dictionary[int, StringName] = {}
var stalled_ball_time: float = 0.0
var session_generation: int = 0


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
		scoop.cue_validated.connect(_on_cue_validated)
	for target in get_tree().get_nodes_in_group("rig_targets"):
		target.target_hit.connect(_on_rig_target_hit)
	for lane in get_tree().get_nodes_in_group("table_lanes"):
		lane.lane_completed.connect(_on_lane_completed)
	for slingshot in get_tree().get_nodes_in_group("slingshots"):
		slingshot.slingshot_hit.connect(_on_slingshot_hit)
	score_manager.score_changed.connect(_on_score_changed)
	flow_manager.flow_changed.connect(_on_flow_changed)
	cue_manager.audio_changes_requested.connect(audio_service.apply_cue_changes)
	cue_manager.bonus_awarded.connect(_on_cue_bonus_awarded)
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
		stalled_ball_time = 0.0
		playtest_recorder.record_launch()
		audio_service.request_sfx(&"launcher")


func start_game() -> void:
	gameplay_active = true
	start_overlay.hide()
	game_over_overlay.hide()
	game_controls.show()
	restart_game()
	status_label.text = "BALL 1 / %d — TOUCH TOP TO LAUNCH" % balls.size()


func _show_start_menu() -> void:
	session_generation += 1
	session_state = SessionState.MENU
	gameplay_active = false
	game_over = false
	start_overlay.show()
	game_over_overlay.hide()
	game_controls.hide()
	_release_all_touches()
	_deactivate_all_balls()


func _show_game_over() -> void:
	session_state = SessionState.GAME_OVER
	game_over = true
	gameplay_active = false
	stalled_ball_time = 0.0
	_release_all_touches()
	_deactivate_all_balls()
	game_controls.hide()
	final_score_label.text = "SCORE FINAL %06d" % score_manager.score
	game_over_overlay.show()
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


func _on_ramp_completed(_ramp_id: StringName, score_value: int, flow_value: int) -> void:
	_add_score_with_flow(score_value)
	flow_manager.add_flow(flow_value)
	status_label.text = "RAMP HIT"
	audio_service.request_sfx(&"ramp")


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
		var active_count := _active_rig_family_count()
		if active_count >= get_tree().get_nodes_in_group("rig_targets").size():
			_add_score_with_flow(1500)
			flow_manager.add_flow(200)
			cue_manager.add_condition(&"rig_ready")
			status_label.text = "RIG READY — HIT CONSOLE"
			audio_service.request_sfx(&"cue")
		else:
			status_label.text = "%s ONLINE — %d / 6" % [display_name.to_upper(), active_count]
	_update_rig_progress()


func _on_lane_completed(
	lane_id: StringName,
	display_name: String,
	score_value: int,
	flow_value: int
) -> void:
	_add_score_with_flow(score_value)
	flow_manager.add_flow(flow_value)
	cue_manager.add_condition(lane_id)
	status_label.text = "%s +%d" % [display_name.to_upper(), score_value]
	audio_service.request_sfx(&"ramp")


func _on_slingshot_hit(score_value: int, flow_value: int, _slingshot_name: StringName) -> void:
	_add_score_with_flow(score_value)
	flow_manager.add_flow(flow_value)
	status_label.text = "SLINGSHOT"
	audio_service.request_sfx(&"flipper")


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
	for target in targets:
		target.set_lit(rig_model.is_family_active(target.family_id))


func _on_scoop_completed(_scoop_id: StringName, score_value: int, flow_value: int) -> void:
	_add_score_with_flow(score_value)
	flow_manager.add_flow(flow_value)
	status_label.text = "CUE VALIDATED"
	audio_service.request_sfx(&"scoop")


func _on_cue_validated(cue_id: StringName) -> void:
	cue_manager.add_condition(&"console_validated")
	cue_manager.start_cue(cue_id)


func _on_cue_bonus_awarded(points: int) -> void:
	_add_score_with_flow(points)
	audio_service.request_sfx(&"cue")


func _add_score_with_flow(points: int) -> void:
	if points <= 0:
		return
	score_manager.add_points(points * flow_manager.multiplier)


func _on_score_changed(new_score: int) -> void:
	score_label.text = "SCORE %06d" % new_score


func _on_flow_changed(flow_points: int, multiplier: int) -> void:
	flow_label.text = "FLOW %04d  x%d" % [flow_points, multiplier]


func _on_drain_body_entered(body: Node) -> void:
	if (
		session_state == SessionState.PLAYING
		and active_ball_index >= 0
		and active_ball_index < balls.size()
		and body == balls[active_ball_index]
	):
		# Area2D emits body_entered while the physics server is flushing its
		# queries. Resolve the drain once the physics step has completed.
		call_deferred("_resolve_ball_drain", body)


func _resolve_ball_drain(body: Node) -> void:
	if (
		session_state != SessionState.PLAYING
		or not is_instance_valid(body)
		or active_ball_index < 0
		or active_ball_index >= balls.size()
		or body != balls[active_ball_index]
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
	_release_all_touches()
	remaining_balls = balls.size()
	active_ball_index = 0
	game_over = false
	session_state = SessionState.READY
	stalled_ball_time = 0.0
	game_over_overlay.hide()
	score_manager.reset_score()
	flow_manager.reset_flow()
	cue_manager.reset_state()
	rig_model.reset_state()
	audio_service.reset_state()
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
	_update_rig_progress()
	_deactivate_all_balls()
	balls[active_ball_index].reset_ball(balls[active_ball_index].spawn_position)
	status_label.text = "BALL 1 / %d" % balls.size()


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
