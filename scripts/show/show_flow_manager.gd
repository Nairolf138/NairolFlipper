class_name ShowFlowManager
extends Node

signal state_changed(state: int, display_name: String)
signal final_show_started(duration_seconds: float, score_multiplier: int)
signal final_show_ended()

enum State {
	STANDBY,
	PRESET,
	BUILD,
	FLOW,
	FINAL_SHOW,
	BLACKOUT,
}

@export_range(5.0, 60.0, 1.0) var final_show_duration: float = 20.0
@export_range(1, 8, 1) var final_show_score_multiplier: int = 2

var state: int = State.STANDBY
var final_show_completed: bool = false


func reset_show() -> void:
	final_show_completed = false
	_set_state(State.PRESET)


func enter_standby() -> void:
	_set_state(State.STANDBY)


func begin_build() -> bool:
	if state != State.PRESET:
		return false
	_set_state(State.BUILD)
	return true


func arm_final_show() -> bool:
	if final_show_completed or state not in [State.BUILD, State.FLOW]:
		return false
	_set_state(State.FLOW)
	return true


func can_start_final_show() -> bool:
	return state == State.FLOW and not final_show_completed


func start_final_show() -> bool:
	if not can_start_final_show():
		return false
	_set_state(State.FINAL_SHOW)
	final_show_started.emit(final_show_duration, final_show_score_multiplier)
	return true


func start_blackout() -> bool:
	if state != State.FINAL_SHOW:
		return false
	final_show_completed = true
	_set_state(State.BLACKOUT)
	final_show_ended.emit()
	return true


func finish_blackout() -> bool:
	if state != State.BLACKOUT:
		return false
	_set_state(State.FLOW)
	return true


func display_name() -> String:
	match state:
		State.STANDBY:
			return "STANDBY"
		State.PRESET:
			return "PRESET"
		State.BUILD:
			return "BUILD"
		State.FLOW:
			return "FLOW"
		State.FINAL_SHOW:
			return "FINAL SHOW"
		State.BLACKOUT:
			return "BLACKOUT"
	return "UNKNOWN"


func _set_state(next_state: int) -> void:
	if state == next_state:
		return
	state = next_state
	state_changed.emit(state, display_name())
