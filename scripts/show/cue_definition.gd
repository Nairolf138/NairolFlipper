class_name CueDefinition
extends Resource

## Data for one show cue; execution belongs to CueManager (T032).
@export var cue_id: StringName
@export var display_name: String = ""
@export var conditions: Array[StringName] = []
@export var light_changes: Dictionary = {}
@export var audio_changes: Dictionary = {}
@export var bonus_points: int = 0
@export var duration_seconds: float = 0.0