extends AnimatableBody2D

const FlipperTuningResource = preload("res://scripts/gameplay/flipper_tuning.gd")

signal activated(action_name: StringName)

@export var action_name: StringName = &"flipper_left"
@export var rest_angle_degrees: float = -20.0
@export var active_angle_degrees: float = 25.0
@export var tuning: FlipperTuningResource
@export var mirrored := false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual
@onready var contact_shadow: Polygon2D = $ContactShadow

var _was_pressed := false
var _motor_velocity := 0.0
var _coil_drive := 0.0
var _motor_angle := 0.0


func _ready() -> void:
	if mirrored:
		collision_shape.position.x = -absf(collision_shape.position.x)
		var outline := collision_shape.shape as ConvexPolygonShape2D
		if outline != null:
			var mirrored_points := outline.points
			for index in mirrored_points.size():
				mirrored_points[index].x = -mirrored_points[index].x
			var mirrored_shape := ConvexPolygonShape2D.new()
			mirrored_shape.points = mirrored_points
			collision_shape.shape = mirrored_shape
		visual.scale.x = -1.0
		contact_shadow.scale.x = -1.0
	reset_flipper()


func reset_flipper() -> void:
	_motor_velocity = 0.0
	_coil_drive = 0.0
	_was_pressed = false
	_motor_angle = deg_to_rad(rest_angle_degrees)
	rotation = _motor_angle


func is_held() -> bool:
	return _was_pressed and is_equal_approx(_motor_angle, deg_to_rad(active_angle_degrees))


func _physics_process(delta: float) -> void:
	var pressed := Input.is_action_pressed(action_name)
	if pressed and not _was_pressed:
		activated.emit(action_name)
	_was_pressed = pressed
	if tuning == null:
		return
	var target_angle_degrees := active_angle_degrees if pressed else rest_angle_degrees
	var target_rotation := deg_to_rad(target_angle_degrees)
	# AnimatableBody2D may report the previous synced transform during the tick.
	# Keep motor integration independent of that one-frame presentation delay.
	var distance := target_rotation - _motor_angle
	if is_zero_approx(distance):
		_motor_velocity = 0.0
		return
	var acceleration := tuning.return_acceleration_degrees
	var maximum_speed := tuning.return_speed_degrees
	if pressed:
		_coil_drive = minf(1.0, _coil_drive + delta / maxf(tuning.coil_ramp_seconds, delta))
		acceleration = tuning.press_acceleration_degrees * _coil_drive
		maximum_speed = tuning.press_speed_degrees
	else:
		_coil_drive = 0.0
	_motor_velocity = move_toward(
		_motor_velocity, signf(distance) * deg_to_rad(maximum_speed), deg_to_rad(acceleration) * delta
	)
	var step := _motor_velocity * delta
	if signf(step) == signf(distance) and absf(step) >= absf(distance):
		_motor_angle = target_rotation
		_motor_velocity = 0.0
	else:
		var next_rotation := _motor_angle + step
		var minimum_angle := deg_to_rad(minf(rest_angle_degrees, active_angle_degrees))
		var maximum_angle := deg_to_rad(maxf(rest_angle_degrees, active_angle_degrees))
		_motor_angle = clampf(next_rotation, minimum_angle, maximum_angle)
		if _motor_angle != next_rotation:
			_motor_velocity = 0.0
	rotation = _motor_angle
