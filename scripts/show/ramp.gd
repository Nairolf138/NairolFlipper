class_name Ramp
extends Area2D

const RampDefinitionResource = preload("res://scripts/show/ramp_definition.gd")

signal ramp_completed(ramp_id: StringName, score_value: int, flow_value: int)

@export var definition: RampDefinitionResource
@onready var visual: Polygon2D = $Visual

var _armed := true
var _pulse_time := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_apply_definition()
	set_process(false)

func _process(delta: float) -> void:
	_pulse_time += delta
	var energy := 1.08 + (sin(_pulse_time * 5.0) + 1.0) * 0.12
	visual.modulate = Color(energy, energy, energy, 1.0)

func reset() -> void:
	_armed = true
	set_objective_highlight(false)

func set_objective_highlight(enabled: bool) -> void:
	_pulse_time = 0.0
	set_process(enabled)
	visual.modulate = Color.WHITE
	if definition != null:
		$Label.text = ("▶ " if enabled else "") + definition.display_name

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
