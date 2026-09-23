class_name PhysicsTuning
extends Resource

## Shared ball parameters keep feel changes data-driven and easy to playtest.
@export var mass: float = 1.0
@export var gravity_scale: float = 1.0
@export var friction: float = 0.2
@export var bounce: float = 0.75
@export var linear_damp: float = 0.0
@export var angular_damp: float = 0.05
@export var max_speed: float = 2600.0
@export var launch_force: float = 1250.0