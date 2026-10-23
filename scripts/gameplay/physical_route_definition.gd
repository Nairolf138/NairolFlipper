class_name PhysicalRouteDefinition
extends Resource

## Presentation only; independent of collision planes and trajectory tuning.
@export var draw_layer: int = 2
@export var wire_start_point_index: int = 6

## Centerline, collision and deck drawing share the same authored geometry.
@export var points: PackedVector2Array
@export var width: float = 112.0
@export var entry_width: float = 150.0
@export var funnel_length: float = 260.0
@export var rail_thickness: float = 10.0
@export var collision_layer: int = 4
@export var bidirectional: bool = false
@export var entry_point_index: int = 0
@export var reverse_entry_point_index: int = -1
@export var route_color: Color = Color("ffb14a")
@export var smoothing: float = 0.2
@export var bake_interval: float = 16.0
@export var rail_friction: float = 0.02
@export var rail_absorption: float = 0.1
