extends RigidBody2D

signal ball_drained(ball: RigidBody2D)

@export var spawn_position: Vector2 = Vector2(960, 1650)
@export var launch_force: float = 1250.0
@export var tuning: PhysicsTuning
@export var ball_save_duration: float = 4.0

var launch_ready: bool = true
var input_enabled: bool = true
var drain_locked: bool = false
var ball_save_remaining: float = 0.0
var ball_save_used: bool = false


func _ready() -> void:
	_apply_tuning()
	reset_ball(spawn_position)


func _physics_process(_delta: float) -> void:
	ball_save_remaining = maxf(0.0, ball_save_remaining - _delta)
	if tuning != null and linear_velocity.length() > tuning.max_speed:
		linear_velocity = linear_velocity.limit_length(tuning.max_speed)
	if input_enabled and Input.is_action_just_pressed("launch_ball"):
		launch_ball()


func _apply_tuning() -> void:
	if tuning == null:
		return
	mass = tuning.mass
	gravity_scale = tuning.gravity_scale
	linear_damp = tuning.linear_damp
	angular_damp = tuning.angular_damp
	launch_force = tuning.launch_force
	var material := PhysicsMaterial.new()
	material.friction = tuning.friction
	material.bounce = tuning.bounce
	physics_material_override = material


func reset_ball(target_position: Vector2) -> void:
	global_position = target_position
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	freeze = true
	launch_ready = true
	drain_locked = false
	ball_save_remaining = 0.0
	ball_save_used = false
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
	ball_save_remaining = ball_save_duration
	ball_save_used = false
	apply_central_impulse(Vector2.UP * launch_force)
	return true


func try_ball_save() -> bool:
	if ball_save_used or ball_save_remaining <= 0.0:
		return false
	ball_save_used = true
	ball_save_remaining = 0.0
	return true
