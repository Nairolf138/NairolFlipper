class_name CueManager
extends Node

const CueDefinitionResource = preload("res://scripts/show/cue_definition.gd")

signal cue_started(cue_id: StringName)
signal cue_completed(cue_id: StringName)
signal stack_progress_changed(
	cue_number: int,
	total_cues: int,
	display_name: String,
	objective_text: String,
	completed_shots: int,
	required_shots: int,
	ready: bool
)
signal stack_completed()
signal light_changes_requested(changes: Dictionary)
signal audio_changes_requested(changes: Dictionary)
signal bonus_awarded(points: int)

## Session executor for data-driven cues. Rendering and audio remain consumers of signals.
@export var cues: Array[CueDefinitionResource] = []

var active_cue: CueDefinitionResource
var current_cue_index: int = 0
var _condition_counts: Dictionary = {}
var _elapsed_seconds: float = 0.0


func _process(delta: float) -> void:
	if active_cue == null or active_cue.duration_seconds <= 0.0:
		return
	_elapsed_seconds += delta
	if _elapsed_seconds >= active_cue.duration_seconds:
		complete_current_cue()


func set_conditions(conditions: Array[StringName]) -> void:
	_condition_counts.clear()
	for condition in conditions:
		_condition_counts[condition] = 1
	_emit_stack_progress()


func add_condition(condition: StringName) -> void:
	var cue := current_cue()
	if cue == null or active_cue != null or not cue.conditions.has(condition):
		return
	var current_count: int = _condition_counts.get(condition, 0)
	if current_count >= cue.condition_repetitions:
		return
	_condition_counts[condition] = current_count + 1
	_emit_stack_progress()


func current_cue() -> CueDefinitionResource:
	if current_cue_index < 0 or current_cue_index >= cues.size():
		return null
	return cues[current_cue_index]


func current_conditions() -> Array[StringName]:
	var cue := current_cue()
	return cue.conditions.duplicate() if cue != null else []


func condition_is_pending(condition: StringName) -> bool:
	var cue := current_cue()
	if cue == null or active_cue != null or not cue.conditions.has(condition):
		return false
	return _condition_counts.get(condition, 0) < cue.condition_repetitions


func current_cue_ready() -> bool:
	var cue := current_cue()
	return cue != null and active_cue == null and _conditions_met(cue)


func is_stack_completed() -> bool:
	return current_cue_index >= cues.size()


func start_current_cue() -> bool:
	var cue := current_cue()
	if cue == null:
		return false
	return start_cue(cue.cue_id)


func start_cue(cue_id: StringName) -> bool:
	if active_cue != null:
		return false
	var cue := _cue_for(cue_id)
	if cue == null or cue != current_cue() or not _conditions_met(cue):
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
	current_cue_index += 1
	_condition_counts.clear()
	cue_completed.emit(completed_id)
	if points != 0:
		bonus_awarded.emit(points)
	if is_stack_completed():
		stack_completed.emit()
	else:
		_emit_stack_progress()
	return true


func reset_state() -> void:
	active_cue = null
	current_cue_index = 0
	_condition_counts.clear()
	_elapsed_seconds = 0.0
	_emit_stack_progress()


func refresh_progress() -> void:
	_emit_stack_progress()


func _conditions_met(cue: CueDefinitionResource) -> bool:
	for condition in cue.conditions:
		if _condition_counts.get(condition, 0) < cue.condition_repetitions:
			return false
	return true


func _completed_shot_count(cue: CueDefinitionResource) -> int:
	var completed := 0
	for condition in cue.conditions:
		completed += mini(_condition_counts.get(condition, 0), cue.condition_repetitions)
	return completed


func _required_shot_count(cue: CueDefinitionResource) -> int:
	return cue.conditions.size() * cue.condition_repetitions


func _emit_stack_progress() -> void:
	var cue := current_cue()
	if cue == null:
		return
	stack_progress_changed.emit(
		current_cue_index + 1,
		cues.size(),
		cue.display_name,
		cue.objective_text,
		_completed_shot_count(cue),
		_required_shot_count(cue),
		current_cue_ready()
	)


func _cue_for(cue_id: StringName) -> CueDefinitionResource:
	for cue in cues:
		if cue != null and cue.cue_id == cue_id:
			return cue
	return null
