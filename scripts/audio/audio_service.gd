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
@export_range(20.0, 240.0, 1.0) var bpm: float = 120.0
@export_range(1.0, 256.0, 1.0) var loop_beats: float = 16.0

var stem_levels: Dictionary = {}
var transport_position_beats: float = 0.0
var transport_playing: bool = false

signal transport_changed(position_beats: float, playing: bool)
signal transport_looped()


func _ready() -> void:
	_ensure_bus(&"Music")
	_ensure_bus(&"SFX")
	_apply_bus_levels()


func _process(delta: float) -> void:
	if not transport_playing or bpm <= 0.0 or loop_beats <= 0.0:
		return
	var beats_per_second := bpm / 60.0
	transport_position_beats += delta * beats_per_second
	if transport_position_beats >= loop_beats:
		transport_position_beats = fmod(transport_position_beats, loop_beats)
		transport_looped.emit()
	transport_changed.emit(transport_position_beats, transport_playing)


func start_transport() -> void:
	transport_playing = true
	transport_changed.emit(transport_position_beats, transport_playing)


func stop_transport(reset_position: bool = false) -> void:
	transport_playing = false
	if reset_position:
		transport_position_beats = 0.0
	transport_changed.emit(transport_position_beats, transport_playing)


func seek_transport(position_beats: float) -> void:
	if loop_beats <= 0.0:
		transport_position_beats = 0.0
	else:
		transport_position_beats = fmod(maxf(position_beats, 0.0), loop_beats)
	transport_changed.emit(transport_position_beats, transport_playing)


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