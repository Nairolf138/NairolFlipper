class_name LaneTrigger
extends Area2D

const RouteDefinition = preload("res://scripts/gameplay/physical_route_definition.gd")

signal lane_completed(lane_id: StringName, display_name: String, score_value: int, flow_value: int)

const FLASHING_FULL: StringName = &"full"
const FLASHING_REDUCED: StringName = &"reduced"
const FLASHING_OFF: StringName = &"off"

@export var lane_id: StringName = &"universe_orbit"
@export var display_name: String = "UNIVERSE ORBIT"
@export var score_value: int = 500
@export var flow_value: int = 70
@export var lane_color: Color = Color(0.42, 0.72, 1.0, 1.0)
@export var route_definition: RouteDefinition

@onready var visual: Polygon2D = $Visual
@onready var label: Label = $Label

var _flash_tween: Tween
var _pulse_time: float = 0.0
var _objective_highlight: bool = false
var flashing_effects: StringName = FLASHING_FULL


func _ready() -> void:
	$PhysicalRoute.configure(route_definition)
	$PhysicalRoute.traversed.connect(_on_route_traversed)
	visual.color = Color(lane_color.r, lane_color.g, lane_color.b, 0.42)
	label.text = display_name
	label.modulate = lane_color
	set_process(false)


func _process(delta: float) -> void:
	_pulse_time += delta
	var energy := 1.08 + (sin(_pulse_time * 5.0) + 1.0) * 0.12
	if flashing_effects == FLASHING_REDUCED:
		energy = 1.08 + (sin(_pulse_time * 2.0) + 1.0) * 0.03
	visual.modulate = Color(energy, energy, energy, 1.0)


func reset() -> void:
	set_objective_highlight(false)


func set_objective_highlight(enabled: bool) -> void:
	_objective_highlight = enabled
	_pulse_time = 0.0
	set_process(enabled and flashing_effects != FLASHING_OFF)
	var static_energy := 1.1 if enabled and flashing_effects == FLASHING_OFF else 1.0
	visual.modulate = Color(static_energy, static_energy, static_energy, 1.0)
	label.text = ("▶ " if enabled else "") + display_name


func set_flashing_effects(mode: StringName) -> void:
	flashing_effects = _normalize_flashing_effects(mode)
	if is_instance_valid(_flash_tween):
		_flash_tween.kill()
	set_objective_highlight(_objective_highlight)


func _on_route_traversed(_body: RigidBody2D) -> void:
	lane_completed.emit(lane_id, display_name, score_value, flow_value)
	_flash()


func _flash() -> void:
	if is_instance_valid(_flash_tween):
		_flash_tween.kill()
	if flashing_effects == FLASHING_OFF:
		return
	var flash_energy := 1.2 if flashing_effects == FLASHING_REDUCED else 1.8
	visual.modulate = Color(flash_energy, flash_energy, flash_energy, 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_property(
		visual,
		"modulate",
		Color.WHITE,
		0.35 if flashing_effects == FLASHING_REDUCED else 0.2
	)


func _normalize_flashing_effects(mode: StringName) -> StringName:
	if mode in [FLASHING_FULL, FLASHING_REDUCED, FLASHING_OFF]:
		return mode
	return FLASHING_FULL
