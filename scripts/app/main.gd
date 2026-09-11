extends Node2D

@onready var score_manager = $ScoreManager
@onready var score_label: Label = $ScoreLabel
@onready var balls: Array[Node] = [$BallOne, $BallTwo, $BallThree]
@onready var drain: Area2D = $Drain
@onready var status_label: Label = $StatusLabel

@export var respawn_delay: float = 1.0

var remaining_balls: int = 3
var active_ball_index: int = 0
var game_over: bool = false
var active_touches: Dictionary[int, StringName] = {}


func _ready() -> void:
	for ball in balls:
		ball.ball_drained.connect(_on_ball_drained)
		ball.input_enabled = false
	drain.body_entered.connect(_on_drain_body_entered)
	for bumper in get_tree().get_nodes_in_group("score_bumpers"):
		bumper.bumper_hit.connect(_on_bumper_hit)
	score_manager.score_changed.connect(_on_score_changed)
	restart_game()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("launch_ball"):
		_launch_or_restart()
	elif event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event)


func _launch_or_restart() -> void:
	if game_over:
		restart_game()
	else:
		balls[active_ball_index].launch_ball()


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
	score_manager.add_points(points)


func _on_score_changed(new_score: int) -> void:
	score_label.text = "SCORE %06d" % new_score


func _on_drain_body_entered(body: Node) -> void:
	if body in balls:
		body.mark_drained()


func _on_ball_drained(_ball: RigidBody2D) -> void:
	if game_over:
		return
	remaining_balls -= 1
	if remaining_balls <= 0:
		game_over = true
		status_label.text = "GAME OVER — PRESS SPACE"
		return
	active_ball_index = 3 - remaining_balls
	status_label.text = "BALL %d / 3" % (active_ball_index + 1)
	await get_tree().create_timer(respawn_delay).timeout
	if not game_over:
		balls[active_ball_index].reset_ball(balls[active_ball_index].spawn_position)


func restart_game() -> void:
	remaining_balls = 3
	active_ball_index = 0
	game_over = false
	score_manager.reset_score()
	status_label.text = "BALL 1 / 3"
	for index in balls.size():
		var ball: Node = balls[index]
		ball.reset_ball(ball.spawn_position)
		ball.visible = index == active_ball_index
