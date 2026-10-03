class_name CueManager
extends Node

signal cue_started(cue_id: StringName)
signal cue_completed(cue_id: StringName)
signal light_changes_requested(changes: Dictionary)
signal audio_changes_requested(changes: Dictionary)
signal bonus_awarded(points: int)

## Session executor for data-driven cues. Rendering and audio remain consumers of signals.
@export var cues: Array[CueDefinition] = []

var active_cue: CueDefinition
var _satisfied_conditions: Array[StringName] = []
var _elapsed_seconds: float = 0.0


func _process(delta: float) -> void:
	if active_cue == null or active_cue.duration_seconds <= 0.0:
		return
	_elapsed_seconds += delta
	if _elapsed_seconds >= active_cue.duration_seconds:
		complete_current_cue()


func set_conditions(conditions: Array[StringName]) -> void:
	_satisfied_conditions = conditions.duplicate()


func add_condition(condition: StringName) -> void:
	if not _satisfied_conditions.has(condition):
		_satisfied_conditions.append(condition)


func start_cue(cue_id: StringName) -> bool:
	if active_cue != null:
		return false
	var cue := _cue_for(cue_id)
	if cue == null or not _conditions_met(cue):
		return false
	active_cue = cue
	_elapsed_seconds = 0.0
	cue_started.emit(cue.cue_id)
	light_changes_requested.emit(cue.light_changes)
	audio_changes_requested.emit(cue.audio_changes)
	return true


func complete_current_cue() -> bool:
	if active_cue == null:
		return false
	var completed_id := active_cue.cue_id
	var points := active_cue.bonus_points
	active_cue = null
	_elapsed_seconds = 0.0
	cue_completed.emit(completed_id)
	if points != 0:
		bonus_awarded.emit(points)
	return true


func _conditions_met(cue: CueDefinition) -> bool:
	for condition in cue.conditions:
		if not _satisfied_conditions.has(condition):
			return false
	return true


func _cue_for(cue_id: StringName) -> CueDefinition:
	for cue in cues:
		if cue != null and cue.cue_id == cue_id:
			return cue
	return null