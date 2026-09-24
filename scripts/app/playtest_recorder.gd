class_name PlaytestRecorder
extends Node

## Local-only counters make feel sessions reviewable without telemetry or accounts.
const SAVE_PATH := "user://playtest/latest.json"
const SCHEMA_VERSION := 1

var session_started_msec: int = 0
var launches: int = 0
var bumper_hits: int = 0
var drains: int = 0
var ball_saves: int = 0
var restarts: int = 0
var score_points: int = 0


func _ready() -> void:
	session_started_msec = Time.get_ticks_msec()
	tree_exiting.connect(save_session)


func record_launch() -> void:
	launches += 1
	save_session()


func record_bumper_hit(score: int) -> void:
	bumper_hits += 1
	score_points += score
	save_session()


func record_drain() -> void:
	drains += 1
	save_session()


func record_ball_save() -> void:
	ball_saves += 1
	save_session()


func record_restart() -> void:
	restarts += 1
	save_session()


func save_session() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://playtest"))
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	var session := {
		"schema_version": SCHEMA_VERSION,
		"duration_seconds": (Time.get_ticks_msec() - session_started_msec) / 1000.0,
		"launches": launches,
		"bumper_hits": bumper_hits,
		"drains": drains,
		"ball_saves": ball_saves,
		"restarts": restarts,
		"score_points": score_points,
	}
	file.store_string(JSON.stringify(session, "  "))
	file.close()
