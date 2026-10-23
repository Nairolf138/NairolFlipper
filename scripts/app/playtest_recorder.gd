class_name PlaytestRecorder
extends Node

## Local-only counters make feel sessions reviewable without telemetry or accounts.
const SAVE_PATH := "user://playtest/latest.json"
const SCHEMA_VERSION := 3
const FLUSH_INTERVAL := 5.0
const FRAME_BINS := 251 # Milliseconds, with an overflow bucket at 250+.

@export var save_path: String = SAVE_PATH

var session_started_msec: int = 0
var launches: int = 0
var bumper_hits: int = 0
var drains: int = 0
var ball_saves: int = 0
var restarts: int = 0
var score_points: int = 0
var sync_awards: int = 0
var perfect_syncs: int = 0
var events: Dictionary = {
	"games_started": 0, "games_finished": 0, "numbered_balls_lost": 0,
	"warm_ramp": 0, "cold_ramp": 0, "universe_orbit": 0,
	"rig_activations": 0, "cues_completed": 0, "final_shows": 0,
	"pauses": 0, "stuck_recoveries": 0, "out_of_bounds": 0,
}
var current_score: int = 0
var peak_score: int = 0
var build_info: Dictionary = {}
var previous_session: Dictionary = {}
var _in_final_show := false
var _final_frames := 0
var _final_usec := 0
var _final_slow_frames := 0
var _capture_frames := false
var _previous_frame_usec: int = 0
var _frame_histogram := PackedInt64Array()
var _frame_count: int = 0
var _frame_usec: int = 0
var _slow_frames: int = 0
var _dirty := false
var _flush_elapsed := 0.0


func _ready() -> void:
	session_started_msec = Time.get_ticks_msec()
	_frame_histogram.resize(FRAME_BINS)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/build_info.json"))
	if parsed is Dictionary:
		build_info = parsed
	if FileAccess.file_exists(save_path):
		var previous: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
		if previous is Dictionary:
			previous_session = previous
	tree_exiting.connect(save_session)
	set_capture_frames(false)


func _process(delta: float) -> void:
	if _capture_frames:
		var now := Time.get_ticks_usec()
		if _previous_frame_usec > 0:
			sample_frame_usec(now - _previous_frame_usec)
		_previous_frame_usec = now
	_flush_elapsed += delta
	if _dirty and _flush_elapsed >= FLUSH_INTERVAL:
		save_session()


func set_capture_frames(enabled: bool) -> void:
	_capture_frames = enabled
	_previous_frame_usec = 0 # Never include menu / pause time in the next frame.


func set_phase(final_show: bool) -> void:
	_in_final_show = final_show
	_previous_frame_usec = 0


func sample_frame_usec(elapsed: int) -> void:
	if elapsed <= 0:
		return
	_frame_count += 1
	_frame_usec += elapsed
	_frame_histogram[mini(ceili(elapsed / 1000.0), FRAME_BINS - 1)] += 1
	if elapsed > 50000:
		_slow_frames += 1
	if _in_final_show:
		_final_frames += 1
		_final_usec += elapsed
		if elapsed > 50000:
			_final_slow_frames += 1
	_dirty = true


func record_event(event: StringName) -> void:
	if events.has(String(event)):
		events[String(event)] += 1
		_dirty = true


func record_score(value: int) -> void:
	current_score = value
	peak_score = maxi(peak_score, value)
	_dirty = true


func record_launch() -> void:
	launches += 1
	_dirty = true


func record_bumper_hit(score: int) -> void:
	bumper_hits += 1
	score_points += score
	_dirty = true


func record_drain() -> void:
	drains += 1
	_dirty = true


func record_ball_save() -> void:
	ball_saves += 1
	_dirty = true


func record_restart() -> void:
	restarts += 1
	_dirty = true


func record_sync(tier: StringName) -> void:
	sync_awards += 1
	if tier == &"perfect":
		perfect_syncs += 1
	_dirty = true


func save_session() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(save_path.get_base_dir()))
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(snapshot(), "  "))
	file.close()
	_dirty = false
	_flush_elapsed = 0.0


func build_label() -> String:
	return "%s • %s" % [ProjectSettings.get_setting("application/config/version"), String(build_info.get("source_commit", "local")).left(8)]


func snapshot() -> Dictionary:
	var p95_ms := 0
	var cumulative := 0
	for index in _frame_histogram.size():
		cumulative += _frame_histogram[index]
		if _frame_count > 0 and cumulative >= ceili(_frame_count * 0.95):
			p95_ms = index
			break
	return {
		"schema_version": SCHEMA_VERSION,
		"version": ProjectSettings.get_setting("application/config/version"),
		"build": build_info.duplicate(true),
		"platform": OS.get_name(),
		"display": DisplayServer.get_name(),
		"window_pixels": [get_window().size.x, get_window().size.y],
		"engine": Engine.get_version_info().string,
		"duration_seconds": (Time.get_ticks_msec() - session_started_msec) / 1000.0,
		"launches": launches,
		"bumper_hits": bumper_hits,
		"drains": drains,
		"ball_saves": ball_saves,
		"restarts": restarts,
		"bumper_base_points": score_points,
		"sync_awards": sync_awards,
		"perfect_syncs": perfect_syncs,
		"events": events.duplicate(true),
		"current_score": current_score,
		"peak_score": peak_score,
		"frames": {
			"samples": _frame_count,
			"observed_seconds": _frame_usec / 1000000.0,
			"average_fps": _frame_count * 1000000.0 / _frame_usec if _frame_usec > 0 else 0.0,
			"p95_ms_capped_250": p95_ms,
			"over_50_ms": _slow_frames,
			"final_show": {
				"samples": _final_frames,
				"average_fps": _final_frames * 1000000.0 / _final_usec if _final_usec > 0 else 0.0,
				"over_50_ms": _final_slow_frames,
			},
			"note": "Cadence murale en jeu uniquement ; ni temps GPU ni mesure de chauffe.",
		},
	}


func report_text() -> String:
	var data := snapshot()
	var cadence := "pas encore mesurée"
	if _frame_count > 0:
		cadence = "%.1f i/s • p95 %d ms (plafonné à 250)" % [data.frames.average_fps, data.frames.p95_ms_capped_250]
	var final_cadence := "pas encore mesurée"
	if _final_frames > 0:
		final_cadence = "%.1f i/s • %d images > 50 ms" % [data.frames.final_show.average_fps, _final_slow_frames]
	var text := "NAIROLFLIPPER — RAPPORT LOCAL\nBuild : %s\nPlateforme : %s\nCadence en jeu : %s\nFinal Show : %s\n\nDepuis cette ouverture de l'application.\nQualification appareil : EN ATTENTE DU PLAYTEST HUMAIN.\nAucun envoi automatique ; aucun identifiant personnel.\n\n" % [build_label(), OS.get_name(), cadence, final_cadence]
	text += JSON.stringify(data, "  ")
	if not previous_session.is_empty():
		text += "\n\nOUVERTURE PRÉCÉDENTE (dernier enregistrement local)\n" + JSON.stringify(previous_session, "  ")
	return text
