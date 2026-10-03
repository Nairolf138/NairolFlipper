class_name RampDefinition
extends Resource

## Data for one scoring ramp; visuals and collision live in Ramp.tscn.
@export var ramp_id: StringName
@export var display_name: String = ""
@export var ramp_color: Color = Color.WHITE
@export var score_value: int = 250
@export var flow_value: int = 40
