class_name PhysicsTuning
extends Resource

## Shared ball parameters keep feel changes data-driven and easy to playtest.
@export var mass: float = 1.4
@export var gravity_scale: float = 1.55
@export var friction: float = 0.48
@export var bounce: float = 0.14
@export var linear_damp: float = 0.16
@export var angular_damp: float = 0.08
@export var max_speed: float = 2300.0
@export var launch_force: float = 3300.0
@export var launch_direction: Vector2 = Vector2.UP
