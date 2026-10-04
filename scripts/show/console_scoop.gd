class_name ConsoleScoop
extends Area2D

signal scoop_completed(scoop_id: StringName, score_value: int, flow_value: int)
signal cue_validated(cue_id: StringName)

@export var scoop_id: StringName = &"console_scoop"
@export var cue_id: StringName = &"first_hit"
@export var score_value: int = 500
@export var flow_value: int = 80
@export var rearm_delay: float = 0.5

var _armed := true

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func reset() -> void:
	_armed = true

func _on_body_entered(body: Node) -> void:
	if not _armed or not body.is_in_group("balls"):
		return
	_armed = false
	scoop_completed.emit(scoop_id, score_value, flow_value)
	cue_validated.emit(cue_id)
	await get_tree().create_timer(rearm_delay).timeout
	_armed = true
