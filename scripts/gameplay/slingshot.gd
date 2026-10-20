class_name Slingshot
extends Area2D

signal slingshot_hit(score_value: int, flow_value: int, slingshot_name: StringName)

@export var kick_direction: Vector2 = Vector2(-0.65, -1.0)
@export var kick_impulse: float = 520.0
@export var score_value: int = 75
@export var flow_value: int = 15
@export var flash_color: Color = Color(1.0, 0.28, 0.65, 1.0)
@export var rearm_delay: float = 0.2

@onready var visual: Polygon2D = $Visual

var _armed: bool = true
var _flash_tween: Tween


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func reset() -> void:
	_armed = true


func _on_body_entered(body: Node) -> void:
	if not _armed or not body is RigidBody2D or not body.is_in_group("balls"):
		return
	_armed = false
	var ball := body as RigidBody2D
	var direction := kick_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.UP
	ball.apply_central_impulse(direction * kick_impulse)
	slingshot_hit.emit(score_value, flow_value, name)
	_flash()
	await get_tree().create_timer(rearm_delay).timeout
	_armed = true


func _flash() -> void:
	if is_instance_valid(_flash_tween):
		_flash_tween.kill()
	visual.modulate = flash_color
	_flash_tween = create_tween()
	_flash_tween.tween_property(visual, "modulate", Color.WHITE, 0.14)
