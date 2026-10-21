class_name SettingsStore
extends Node

signal audio_levels_changed(master_percent: float, music_percent: float, sfx_percent: float)

const DEFAULT_SAVE_PATH := "user://settings.json"
const SCHEMA_VERSION := 1
const DEFAULT_MASTER_PERCENT := 100.0
const DEFAULT_MUSIC_PERCENT := 100.0
const DEFAULT_SFX_PERCENT := 100.0
const MIN_DB := -60.0

@export var save_path: String = DEFAULT_SAVE_PATH

var master_percent: float = DEFAULT_MASTER_PERCENT
var music_percent: float = DEFAULT_MUSIC_PERCENT
var sfx_percent: float = DEFAULT_SFX_PERCENT


func _ready() -> void:
	load_settings()


func load_settings() -> bool:
	_apply_audio_levels(
		DEFAULT_MASTER_PERCENT,
		DEFAULT_MUSIC_PERCENT,
		DEFAULT_SFX_PERCENT
	)
	if not FileAccess.file_exists(save_path):
		return false
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_warning("Unable to read audio settings from %s" % save_path)
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Ignoring invalid audio settings in %s" % save_path)
		return false
	var payload: Dictionary = parsed
	var audio: Variant = payload.get("audio", {})
	if typeof(audio) != TYPE_DICTIONARY:
		push_warning("Ignoring invalid audio settings in %s" % save_path)
		return false
	_apply_audio_levels(
		float(audio.get("master_percent", DEFAULT_MASTER_PERCENT)),
		float(audio.get("music_percent", DEFAULT_MUSIC_PERCENT)),
		float(audio.get("sfx_percent", DEFAULT_SFX_PERCENT))
	)
	return true


func set_audio_levels(
	master_value: float,
	music_value: float,
	sfx_value: float,
	persist: bool = true
) -> bool:
	_apply_audio_levels(master_value, music_value, sfx_value)
	if persist:
		return save_settings()
	return true


func restore_audio_defaults(persist: bool = true) -> bool:
	return set_audio_levels(
		DEFAULT_MASTER_PERCENT,
		DEFAULT_MUSIC_PERCENT,
		DEFAULT_SFX_PERCENT,
		persist
	)


func save_settings() -> bool:
	var directory_path := save_path.get_base_dir()
	if not directory_path.is_empty():
		var directory_error := DirAccess.make_dir_recursive_absolute(
			ProjectSettings.globalize_path(directory_path)
		)
		if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
			push_warning("Unable to create settings directory %s" % directory_path)
			return false
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning("Unable to save audio settings to %s" % save_path)
		return false
	var payload := {
		"schema_version": SCHEMA_VERSION,
		"audio": {
			"master_percent": master_percent,
			"music_percent": music_percent,
			"sfx_percent": sfx_percent,
		},
	}
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return true


static func percent_to_db(percent: float) -> float:
	var linear_level := clampf(percent, 0.0, 100.0) / 100.0
	if linear_level <= 0.0:
		return MIN_DB
	return maxf(linear_to_db(linear_level), MIN_DB)


static func db_to_percent(volume_db: float) -> float:
	if volume_db <= MIN_DB:
		return 0.0
	return clampf(db_to_linear(volume_db) * 100.0, 0.0, 100.0)


func _apply_audio_levels(master_value: float, music_value: float, sfx_value: float) -> void:
	master_percent = clampf(master_value, 0.0, 100.0)
	music_percent = clampf(music_value, 0.0, 100.0)
	sfx_percent = clampf(sfx_value, 0.0, 100.0)
	audio_levels_changed.emit(master_percent, music_percent, sfx_percent)
