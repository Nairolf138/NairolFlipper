class_name RigTarget
extends Area2D

signal target_hit(
	target: RigTarget,
	family_id: StringName,
	display_name: String,
	score_value: int,
	flow_value: int
)

const FLASHING_FULL: StringName = &"full"
const FLASHING_REDUCED: StringName = &"reduced"
const FLASHING_OFF: StringName = &"off"
const FIXTURE_ATLAS = preload("res://assets/textures/stagecraft/fixture_atlas.svg")
const FIXTURE_FAMILIES: Array[StringName] = [
	&"front_wash", &"back_wash", &"beam", &"pixel", &"blinders", &"practical",
]

@export var family_id: StringName = &"front_wash"
@export var display_name: String = "WASH"
@export var score_value: int = 250
@export var flow_value: int = 35
@export var target_color: Color = Color(1.0, 0.75, 0.3, 1.0)
@export var rearm_delay: float = 0.3

@onready var visual: Node2D = $Visual
@onready var core: Polygon2D = $Core
@onready var indicator: Polygon2D = $Indicator
@onready var label: Label = $Label

var lit: bool = false
var _armed: bool = true
var _flash_tween: Tween
var flashing_effects: StringName = FLASHING_FULL


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var fixture := AtlasTexture.new()
	fixture.atlas = FIXTURE_ATLAS
	fixture.region = Rect2(maxi(0, FIXTURE_FAMILIES.find(family_id)) * 160, 0, 160, 112)
	$Visual/MetalFrame.texture = fixture
	label.text = display_name
	_apply_visual_state()


func reset() -> void:
	lit = false
	_armed = true
	_apply_visual_state()


func set_lit(value: bool) -> void:
	lit = value
	_apply_visual_state()


func set_flashing_effects(mode: StringName) -> void:
	flashing_effects = mode if mode in [FLASHING_FULL, FLASHING_REDUCED, FLASHING_OFF] else FLASHING_FULL
	if is_instance_valid(_flash_tween):
		_flash_tween.kill()
	core.modulate = Color.WHITE


func _apply_visual_state() -> void:
	# Metal stays neutral and readable; only the optical witness carries colour.
	visual.modulate = Color.WHITE if lit else Color(0.8, 0.82, 0.85)
	core.color = target_color if lit else Color(0.08, 0.12, 0.18, 1.0)
	indicator.color = Color(target_color.r, target_color.g, target_color.b, 1.0 if lit else 0.32)
	label.modulate = Color.WHITE if lit else Color(0.68, 0.72, 0.8, 1.0)


func _on_body_entered(body: Node) -> void:
	if not _armed or not body.is_in_group("balls"):
		return
	_armed = false
	set_lit(true)
	target_hit.emit(self, family_id, display_name, score_value, flow_value)
	_flash()
	await get_tree().create_timer(rearm_delay).timeout
	_armed = true


func _flash() -> void:
	if is_instance_valid(_flash_tween):
		_flash_tween.kill()
	if flashing_effects == FLASHING_OFF:
		core.modulate = Color.WHITE
		return
	var flash_energy := 1.2 if flashing_effects == FLASHING_REDUCED else 1.8
	core.modulate = Color(flash_energy, flash_energy, flash_energy, 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_property(
		core,
		"modulate",
		Color.WHITE,
		0.35 if flashing_effects == FLASHING_REDUCED else 0.16
	)
