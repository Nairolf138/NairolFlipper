extends Area2D

signal bumper_hit(points: int, bumper_name: StringName)

@export var bumper_impulse: float = 620.0
@export var score_value: int = 100
@export var flash_color: Color = Color(1.0, 0.75, 0.2, 1.0)

@onready var visual: Polygon2D = $Visual

var _flash_tween: Tween
var _pulse_time: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	set_process(false)


func _process(delta: float) -> void:
	_pulse_time += delta
	var energy := 1.05 + (sin(_pulse_time * 6.0) + 1.0) * 0.14
	visual.scale = Vector2.ONE * energy


func set_objective_highlight(enabled: bool) -> void:
	_pulse_time = 0.0
	set_process(enabled)
	visual.scale = Vector2.ONE


func _on_body_entered(body: Node2D) -> void:
	if not body is RigidBody2D:
		return

	var ball := body as RigidBody2D
	var direction := (ball.global_position - global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.UP
	ball.apply_central_impulse(direction * bumper_impulse)
	bumper_hit.emit(score_value, name)
	flash()


func flash() -> void:
	if is_instance_valid(_flash_tween):
		_flash_tween.kill()
	visual.modulate = flash_color
	_flash_tween = create_tween()
	_flash_tween.tween_property(visual, "modulate", Color.WHITE, 0.12)
