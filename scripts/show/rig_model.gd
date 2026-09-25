class_name RigModel
extends Node

signal rig_family_activated(family_id: StringName)

## Session state for the six fixture families. Rendering stays with the scene.
@export var families: Array[RigDefinition] = []

var _activation_counts: Dictionary = {}


func _ready() -> void:
	for definition in families:
		if definition == null or definition.family_id == &"":
			continue
		_activation_counts[definition.family_id] = 0


func activate_family(family_id: StringName) -> bool:
	var definition := _definition_for(family_id)
	if definition == null:
		return false
	var count: int = _activation_counts.get(family_id, 0)
	if count >= definition.activation_target:
		return false
	_activation_counts[family_id] = count + 1
	rig_family_activated.emit(family_id)
	return true


func is_family_active(family_id: StringName) -> bool:
	var definition := _definition_for(family_id)
	if definition == null:
		return false
	return _activation_counts.get(family_id, 0) >= definition.activation_target


func _definition_for(family_id: StringName) -> RigDefinition:
	for definition in families:
		if definition != null and definition.family_id == family_id:
			return definition
	return null