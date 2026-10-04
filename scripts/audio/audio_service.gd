class_name AudioService
extends Node

signal mix_changed(master_db: float, music_db: float, sfx_db: float)
signal stems_changed(levels: Dictionary)
signal sfx_requested(sfx_id: StringName)

## Logical audio mixer shared by cues and future stream players.
## No gameplay path depends on an audio device being available.
@export_range(-60.0, 6.0, 0.5) var master_volume_db: float = 0.0
@export_range(-60.0, 6.0, 0.5) var music_volume_db: float = 0.0
@export_range(-60.0, 6.0, 0.5) var sfx_volume_db: float = 0.0

var stem_levels: Dictionary = {}


func _ready() -> void:
	_ensure_bus(&"Music")
	_ensure_bus(&"SFX")
	_apply_bus_levels()


func set_mix(master_db: float, music_db: float, sfx_db: float) -> void:
	master_volume_db = clampf(master_db, -60.0, 6.0)
	music_volume_db = clampf(music_db, -60.0, 6.0)
	sfx_volume_db = clampf(sfx_db, -60.0, 6.0)
	_apply_bus_levels()
	mix_changed.emit(master_volume_db, music_volume_db, sfx_volume_db)


func apply_cue_changes(changes: Dictionary) -> void:
	if changes.has("master_db") or changes.has("music_db") or changes.has("sfx_db"):
		set_mix(
			float(changes.get("master_db", master_volume_db)),
			float(changes.get("music_db", music_volume_db)),
			float(changes.get("sfx_db", sfx_volume_db))
		)
	if changes.has("stems") and changes["stems"] is Dictionary:
		for stem_id in changes["stems"]:
			set_stem_level(StringName(stem_id), float(changes["stems"][stem_id]))
	if changes.has("sfx"):
		request_sfx(StringName(changes["sfx"]))


func set_stem_level(stem_id: StringName, level: float) -> void:
	stem_levels[stem_id] = clampf(level, 0.0, 1.0)
	stems_changed.emit(stem_levels.duplicate())


func request_sfx(sfx_id: StringName) -> void:
	if sfx_id == StringName():
		return
	sfx_requested.emit(sfx_id)


func _ensure_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	AudioServer.set_bus_send(AudioServer.bus_count - 1, &"Master")


func _apply_bus_levels() -> void:
	var master_index := AudioServer.get_bus_index(&"Master")
	if master_index >= 0:
		AudioServer.set_bus_volume_db(master_index, master_volume_db)
	var music_index := AudioServer.get_bus_index(&"Music")
	if music_index >= 0:
		AudioServer.set_bus_volume_db(music_index, music_volume_db)
	var sfx_index := AudioServer.get_bus_index(&"SFX")
	if sfx_index >= 0:
		AudioServer.set_bus_volume_db(sfx_index, sfx_volume_db)