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
		if game_over:
			restart_game()
		else:
			balls[active_ball_index].launch_ball()


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
	for ball in balls:
		ball.reset_ball(ball.spawn_position)
