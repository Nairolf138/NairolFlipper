class_name AudioService
extends Node

const AudioStemSetResource = preload("res://scripts/audio/audio_stem_set.gd")

const SFX_STREAMS: Dictionary[StringName, AudioStream] = {
	&"flipper": preload("res://assets/audio/sfx/flipper.wav"),
	&"launcher": preload("res://assets/audio/sfx/launcher.wav"),
	&"kick_bumper": preload("res://assets/audio/sfx/kick_bumper.wav"),
	&"snare_bumper": preload("res://assets/audio/sfx/snare_bumper.wav"),
	&"tom_bumper": preload("res://assets/audio/sfx/tom_bumper.wav"),
	&"ramp": preload("res://assets/audio/sfx/ramp.wav"),
	&"scoop": preload("res://assets/audio/sfx/scoop.wav"),
	&"cue": preload("res://assets/audio/sfx/cue.wav"),
	&"cue_start": preload("res://assets/audio/sfx/cue.wav"),
	&"sync": preload("res://assets/audio/sfx/sync.wav"),
	&"safety": preload("res://assets/audio/sfx/safety.wav"),
	&"drain": preload("res://assets/audio/sfx/drain.wav"),
}

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
@export_range(1, 16, 1) var sfx_polyphony: int = 8
@export var stem_set: AudioStemSetResource

var stem_levels: Dictionary = {}
var transport_position_beats: float = 0.0
var transport_total_beats: float = 0.0
var transport_playing: bool = false
var last_sfx_id: StringName = &""
var _sfx_players: Array[AudioStreamPlayer] = []
var _stem_players: Dictionary[StringName, AudioStreamPlayer] = {}
var _stem_tweens: Dictionary[StringName, Tween] = {}
var _next_sfx_player := 0

signal transport_changed(position_beats: float, playing: bool)
signal transport_looped()


func _ready() -> void:
	_ensure_bus(&"Music")
	_ensure_bus(&"SFX")
	_apply_bus_levels()
	_create_sfx_pool()
	_create_stem_players()


func _process(delta: float) -> void:
	if not transport_playing or bpm <= 0.0 or loop_beats <= 0.0:
		return
	var beats_per_second := bpm / 60.0
	var beat_delta := delta * beats_per_second
	transport_position_beats += beat_delta
	transport_total_beats += beat_delta
	if transport_position_beats >= loop_beats:
		transport_position_beats = fmod(transport_position_beats, loop_beats)
		transport_looped.emit()
	transport_changed.emit(transport_position_beats, transport_playing)


func _exit_tree() -> void:
	for player in _sfx_players:
		player.stop()
		player.stream = null
	_sfx_players.clear()
	for player in _stem_players.values():
		player.stop()
		player.stream = null
	_stem_players.clear()
	_stem_tweens.clear()


func start_transport() -> void:
	transport_playing = true
	_start_stem_players()
	transport_changed.emit(transport_position_beats, transport_playing)


func stop_transport(reset_position: bool = false) -> void:
	transport_playing = false
	for player in _stem_players.values():
		player.stop()
	if reset_position:
		transport_position_beats = 0.0
		transport_total_beats = 0.0
	transport_changed.emit(transport_position_beats, transport_playing)


func seek_transport(position_beats: float) -> void:
	if loop_beats <= 0.0:
		transport_position_beats = 0.0
	else:
		transport_position_beats = fmod(maxf(position_beats, 0.0), loop_beats)
	transport_total_beats = maxf(position_beats, 0.0)
	if transport_playing:
		_start_stem_players()
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
	_apply_stem_level(stem_id)
	stems_changed.emit(stem_levels.duplicate())


func set_stem_mix(levels: Dictionary) -> void:
	var changed := false
	for stem_id in _stem_players:
		var next_level := clampf(float(levels.get(stem_id, 0.0)), 0.0, 1.0)
		if is_equal_approx(float(stem_levels.get(stem_id, 0.0)), next_level):
			continue
		stem_levels[stem_id] = next_level
		_apply_stem_level(stem_id)
		changed = true
	if changed:
		stems_changed.emit(stem_levels.duplicate())


func request_sfx(sfx_id: StringName) -> void:
	if sfx_id == StringName():
		return
	sfx_requested.emit(sfx_id)
	if not SFX_STREAMS.has(sfx_id) or _sfx_players.is_empty():
		return
	last_sfx_id = sfx_id
	if DisplayServer.get_name() == "headless":
		return
	var player := _sfx_players[_next_sfx_player]
	_next_sfx_player = (_next_sfx_player + 1) % _sfx_players.size()
	player.stop()
	player.stream = SFX_STREAMS[sfx_id]
	player.play()


func reset_state() -> void:
	stem_levels.clear()
	stems_changed.emit(stem_levels.duplicate())
	stop_transport(true)
	for player in _sfx_players:
		player.stop()
	for player in _stem_players.values():
		player.stop()
		player.volume_db = -60.0
	for tween in _stem_tweens.values():
		if is_instance_valid(tween):
			tween.kill()
	_stem_tweens.clear()
	last_sfx_id = &""


func _create_sfx_pool() -> void:
	for index in maxi(1, sfx_polyphony):
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % (index + 1)
		player.bus = &"SFX"
		add_child(player)
		_sfx_players.append(player)


func _create_stem_players() -> void:
	if stem_set == null:
		return
	for stem_id in stem_set.streams():
		var stream: AudioStream = stem_set.streams()[stem_id]
		if stream == null:
			continue
		if stream is AudioStreamOggVorbis:
			stream.loop = true
		var player := AudioStreamPlayer.new()
		player.name = "Stem%s" % String(stem_id).capitalize().replace(" ", "")
		player.bus = &"Music"
		player.stream = stream
		player.volume_db = -60.0
		add_child(player)
		_stem_players[stem_id] = player
		stem_levels[stem_id] = 0.0


func _start_stem_players() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var position_seconds := transport_position_beats * 60.0 / maxf(bpm, 1.0)
	for player in _stem_players.values():
		player.stop()
		player.play(position_seconds)


func _apply_stem_level(stem_id: StringName) -> void:
	if not _stem_players.has(stem_id):
		return
	var level := float(stem_levels.get(stem_id, 0.0))
	var target_db := linear_to_db(maxf(level, 0.001))
	var player: AudioStreamPlayer = _stem_players[stem_id]
	if DisplayServer.get_name() == "headless" or not is_node_ready():
		player.volume_db = target_db
		return
	if _stem_tweens.has(stem_id) and is_instance_valid(_stem_tweens[stem_id]):
		_stem_tweens[stem_id].kill()
	var tween := create_tween()
	tween.tween_property(player, "volume_db", target_db, 0.24)
	_stem_tweens[stem_id] = tween


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
