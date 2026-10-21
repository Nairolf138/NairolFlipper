class_name LaneTrigger
extends Area2D

signal lane_completed(lane_id: StringName, display_name: String, score_value: int, flow_value: int)

@export var lane_id: StringName = &"universe_orbit"
@export var display_name: String = "UNIVERSE ORBIT"
@export var score_value: int = 500
@export var flow_value: int = 70
@export var lane_color: Color = Color(0.42, 0.72, 1.0, 1.0)
@export var rearm_delay: float = 0.45

@onready var visual: Polygon2D = $Visual
@onready var label: Label = $Label

var _armed: bool = true
var _flash_tween: Tween
var _pulse_time: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	visual.color = Color(lane_color.r, lane_color.g, lane_color.b, 0.42)
	label.text = display_name
	label.modulate = lane_color
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
	label.text = ("▶ " if enabled else "") + display_name


func _on_body_entered(body: Node) -> void:
	if not _armed or not body.is_in_group("balls"):
		return
	_armed = false
	lane_completed.emit(lane_id, display_name, score_value, flow_value)
	_flash()
	await get_tree().create_timer(rearm_delay).timeout
	_armed = true


func _flash() -> void:
	if is_instance_valid(_flash_tween):
		_flash_tween.kill()
	visual.modulate = Color(1.8, 1.8, 1.8, 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_property(visual, "modulate", Color.WHITE, 0.2)
