class_name SyncBonusManager
extends Node

signal sync_awarded(
	tier: StringName,
	score_bonus: int,
	flow_bonus: int,
	distance_beats: float
)

## Timing is deliberately forgiving: the ball remains physical and partly
## unpredictable, so Sync rewards a lucky or intentional pulse without ever
## turning an off-beat hit into a failure.
@export_range(0.01, 0.24, 0.01) var perfect_window_beats: float = 0.12
@export_range(0.12, 0.49, 0.01) var sync_window_beats: float = 0.28
@export var perfect_score_bonus: int = 200
@export var perfect_flow_bonus: int = 35
@export var sync_score_bonus: int = 100
@export var sync_flow_bonus: int = 18

var last_tier: StringName = &""
var last_distance_beats: float = 1.0
var awards: int = 0
var perfect_awards: int = 0
var _last_awarded_pulse: int = -1_000_000


func register_hit(total_position_beats: float, transport_playing: bool = true) -> bool:
	if not transport_playing:
		return false
	var nearest_pulse := roundi(total_position_beats)
	var distance := absf(total_position_beats - float(nearest_pulse))
	if distance > sync_window_beats or nearest_pulse == _last_awarded_pulse:
		return false

	_last_awarded_pulse = nearest_pulse
	last_distance_beats = distance
	awards += 1
	if distance <= perfect_window_beats:
		last_tier = &"perfect"
		perfect_awards += 1
		sync_awarded.emit(last_tier, perfect_score_bonus, perfect_flow_bonus, distance)
	else:
		last_tier = &"sync"
		sync_awarded.emit(last_tier, sync_score_bonus, sync_flow_bonus, distance)
	return true


func reset_state() -> void:
	last_tier = &""
	last_distance_beats = 1.0
	awards = 0
	perfect_awards = 0
	_last_awarded_pulse = -1_000_000
