class_name PhysicsTuning
extends Resource

## Shared ball parameters keep feel changes data-driven and easy to playtest.
@export var mass: float = 1.4
@export_range(0.0, 12.0, 0.1) var table_slope_degrees: float = 6.5
@export var pixels_per_meter: float = 1600.0
@export_range(0.0, 0.05, 0.001) var rolling_resistance: float = 0.002
@export var friction: float = 0.48
@export var bounce: float = 0.1
@export var spin_damping: float = 0.2
@export var max_speed: float = 2300.0
@export var launch_force: float = 2700.0
@export var launch_direction: Vector2 = Vector2.UP

# Solid sphere rolling without slipping: I/(m*r²) = 2/5. The 2D projection
# models motion on the deck, not vertical airborne motion or full 3D spin.
const ROLLING_FACTOR := 5.0 / 7.0
const GRAVITY_MPS2 := 9.81


func downhill_acceleration() -> float:
	return GRAVITY_MPS2 * pixels_per_meter * sin(deg_to_rad(table_slope_degrees)) * ROLLING_FACTOR


func rolling_deceleration() -> float:
	return GRAVITY_MPS2 * pixels_per_meter * cos(deg_to_rad(table_slope_degrees)) * rolling_resistance * ROLLING_FACTOR


func advance_velocity(velocity: Vector2, delta: float) -> Vector2:
	velocity.y += downhill_acceleration() * delta
	return velocity.move_toward(Vector2.ZERO, rolling_deceleration() * delta).limit_length(max_speed)
