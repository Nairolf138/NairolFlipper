extends RigidBody2D

signal ball_drained(ball: RigidBody2D)

@export var spawn_position: Vector2 = Vector2(960, 1650)
@export var launch_force: float = 1250.0

var launch_ready: bool = true
var input_enabled: bool = true
var drain_locked: bool = false


func _ready() -> void:
	reset_ball(spawn_position)


func _physics_process(_delta: float) -> void:
	if input_enabled and Input.is_action_just_pressed("launch_ball"):
		launch_ball()


func reset_ball(target_position: Vector2) -> void:
	global_position = target_position
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	freeze = true
	launch_ready = true
	drain_locked = false
	visible = true


func mark_drained() -> void:
	if drain_locked:
		return
	drain_locked = true
	freeze = true
	linear_velocity = Vector2.ZERO
	visible = false
	ball_drained.emit(self)


func launch_ball() -> bool:
	if not launch_ready:
		return false

	launch_ready = false
	freeze = false
	apply_central_impulse(Vector2.UP * launch_force)
	return true
