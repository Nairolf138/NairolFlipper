class_name FlowManager
extends Node

signal flow_changed(flow_points: int, multiplier: int)
signal multiplier_changed(multiplier: int)

## Session Flow: a forgiving progression multiplier for varied show actions.
@export var thresholds: Array[int] = [0, 100, 250, 450, 700, 1000]
@export var multipliers: Array[int] = [1, 2, 3, 4, 6, 8]
@export var decay_per_second: float = 8.0

var flow_points: int = 0
var multiplier: int = 1
var _decay_accumulator: float = 0.0


func add_flow(points: int) -> void:
	if points <= 0:
		return
	flow_points += points
	_update_multiplier()


func decay_flow(delta: float) -> void:
	if delta <= 0.0 or flow_points <= 0:
		return
	_decay_accumulator += delta * decay_per_second
	var points_to_remove := floori(_decay_accumulator)
	if points_to_remove <= 0:
		return
	_decay_accumulator -= points_to_remove
	flow_points = maxi(0, flow_points - points_to_remove)
	if flow_points == 0:
		_decay_accumulator = 0.0
	_update_multiplier()


func reset_flow() -> void:
	flow_points = 0
	_decay_accumulator = 0.0
	_update_multiplier()


func _process(delta: float) -> void:
	decay_flow(delta)


func _update_multiplier() -> void:
	var previous_multiplier := multiplier
	multiplier = _multiplier_for_points(flow_points)
	flow_changed.emit(flow_points, multiplier)
	if multiplier != previous_multiplier:
		multiplier_changed.emit(multiplier)


func _multiplier_for_points(points: int) -> int:
	var result := multipliers[0] if not multipliers.is_empty() else 1
	var count := mini(thresholds.size(), multipliers.size())
	for index in count:
		if points >= thresholds[index]:
			result = multipliers[index]
	return result
