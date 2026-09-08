extends AnimatableBody2D

@export var action_name: StringName = &"flipper_left"
@export var rest_angle_degrees: float = -20.0
@export var active_angle_degrees: float = 25.0
@export var rotation_speed_degrees: float = 720.0


func _ready() -> void:
	rotation = deg_to_rad(rest_angle_degrees)


func _physics_process(delta: float) -> void:
	var target_angle_degrees := active_angle_degrees if Input.is_action_pressed(action_name) else rest_angle_degrees
	var target_rotation := deg_to_rad(target_angle_degrees)
	rotation = move_toward(rotation, target_rotation, deg_to_rad(rotation_speed_degrees) * delta)
