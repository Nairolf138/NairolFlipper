class_name Ramp
extends Area2D

signal ramp_completed(ramp_id: StringName, score_value: int, flow_value: int)

@export var definition: RampDefinition
@onready var visual: Polygon2D = $Visual

var _armed := true

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_apply_definition()

func reset() -> void:
	_armed = true

func _apply_definition() -> void:
	if definition == null:
		return
	visual.color = definition.ramp_color
	$Label.text = definition.display_name

func _on_body_entered(body: Node) -> void:
	if not _armed or not body.is_in_group("balls"):
		return
	_armed = false
	ramp_completed.emit(definition.ramp_id, definition.score_value, definition.flow_value)
	# Re-arm after the ball has left the sensor, preventing duplicate hits in one pass.
	await get_tree().create_timer(0.35).timeout
	_armed = true
