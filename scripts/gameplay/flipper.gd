extends AnimatableBody2D

signal activated(action_name: StringName)

@export var action_name: StringName = &"flipper_left"
@export var rest_angle_degrees: float = -20.0
@export var active_angle_degrees: float = 25.0
@export var rotation_speed_degrees: float = 900.0
@export var mirrored := false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual
@onready var contact_shadow: Polygon2D = $ContactShadow

var _was_pressed := false


func _ready() -> void:
	if mirrored:
		collision_shape.position.x = -absf(collision_shape.position.x)
		visual.scale.x = -1.0
		contact_shadow.scale.x = -1.0
	rotation = deg_to_rad(rest_angle_degrees)


func _physics_process(delta: float) -> void:
	var pressed := Input.is_action_pressed(action_name)
	if pressed and not _was_pressed:
		activated.emit(action_name)
	_was_pressed = pressed
	var target_angle_degrees := active_angle_degrees if pressed else rest_angle_degrees
	var target_rotation := deg_to_rad(target_angle_degrees)
	rotation = move_toward(rotation, target_rotation, deg_to_rad(rotation_speed_degrees) * delta)
