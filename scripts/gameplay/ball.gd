extends RigidBody2D

@export var spawn_position: Vector2 = Vector2(900, 1650)


func _ready() -> void:
	reset_ball(spawn_position)


func reset_ball(target_position: Vector2) -> void:
	global_position = target_position
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
