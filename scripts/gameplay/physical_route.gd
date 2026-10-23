class_name PhysicalRoute
extends Node2D

signal traversed(ball: RigidBody2D)

const RouteDefinition = preload("res://scripts/gameplay/physical_route_definition.gd")
const RouteArt = preload("res://scripts/show/route_visual.gd")
const BALL_RADIUS := 22.0

var definition: RouteDefinition
var curve := Curve2D.new()
var centerline := PackedVector2Array()
var entry_index: int = 0
var reverse_entry_index: int = 0
var _offsets := PackedFloat32Array()
var _previous: Dictionary = {}
var _riders: Dictionary = {}


func configure(profile: RouteDefinition) -> void:
	definition = profile
	if definition == null or definition.points.size() < 3:
		set_physics_process(false)
		return
	curve.bake_interval = definition.bake_interval
	for index in definition.points.size():
		var tangent := (definition.points[1] - definition.points[0]) / 3.0
		if index > 0 and index < definition.points.size() - 1:
			tangent = (definition.points[index + 1] - definition.points[index - 1]) * definition.smoothing
		elif index == definition.points.size() - 1:
			tangent = (definition.points[index] - definition.points[index - 1]) / 3.0
		curve.add_point(definition.points[index], -tangent, tangent)
	centerline = curve.get_baked_points()
	entry_index = _baked_point_index(definition.entry_point_index)
	reverse_entry_index = _baked_point_index(definition.reverse_entry_point_index)
	var offset := 0.0
	for index in centerline.size():
		if index > 0:
			offset += centerline[index].distance_to(centerline[index - 1])
		_offsets.append(offset)
	var material := PhysicsMaterial.new()
	material.friction = definition.rail_friction
	material.bounce = definition.rail_absorption
	material.absorbent = true
	for side in [-1.0, 1.0]:
		var edge := PackedVector2Array()
		var visible_edge := PackedVector2Array()
		for index in centerline.size():
			var before := centerline[maxi(index - 1, 0)]
			var after := centerline[mini(index + 1, centerline.size() - 1)]
			var normal := (after - before).normalized().orthogonal()
			var width := _width_at(index)
			edge.append(centerline[index] + normal * (width - definition.rail_thickness) * 0.5 * side)
			visible_edge.append(centerline[index] + normal * width * 0.5 * side)
		var rail := StaticBody2D.new()
		rail.physics_material_override = material
		rail.collision_layer = definition.collision_layer
		rail.collision_mask = definition.collision_layer
		# Continuous static segments avoid capsule end caps scattering fast shots.
		var segments := PackedVector2Array()
		for index in edge.size() - 1:
			segments.append(edge[index])
			segments.append(edge[index + 1])
		var shape := ConcavePolygonShape2D.new()
		shape.segments = segments
		var collider := CollisionShape2D.new()
		collider.shape = shape
		rail.add_child(collider)
		add_child(rail)
		rail.set_meta("edge", visible_edge)
	z_index = definition.draw_layer
	var art := RouteArt.new()
	art.name = "RouteArt"
	add_child(art)
	art.configure(self)


func _physics_process(_delta: float) -> void:
	if definition == null:
		return
	for ball in get_tree().get_nodes_in_group("balls"):
		var current := to_local(ball.global_position)
		var sample: Dictionary = _previous.get(ball, {"position": current, "epoch": ball.route_epoch})
		var previous: Vector2 = sample.position
		_previous[ball] = {"position": current, "epoch": ball.route_epoch}
		if sample.epoch != ball.route_epoch:
			_riders.erase(ball)
			continue
		if ball.freeze or ball.drain_locked:
			_riders.erase(ball)
			continue
		if ball.route_owner == self:
			_update_rider(ball, previous, current)
		elif ball.route_owner == null:
			if _crosses_gate(previous, current, entry_index, false):
				_admit(ball, 1)
			elif definition.bidirectional and _crosses_gate(previous, current, reverse_entry_index, true):
				_admit(ball, -1)
	# Do not retain nodes freed by a scene or a test fixture.
	for ball in _previous.keys():
		if not is_instance_valid(ball):
			_previous.erase(ball)
			_riders.erase(ball)


func _admit(ball: RigidBody2D, direction: int) -> void:
	if ball.enter_route(self, definition.collision_layer):
		_riders[ball] = {"direction": direction, "checkpoint": 1}


func _update_rider(ball: RigidBody2D, previous: Vector2, current: Vector2) -> void:
	if not _riders.has(ball):
		return
	var rider: Dictionary = _riders[ball]
	var forward: bool = rider.direction == 1
	var progress := curve.get_closest_offset(current) / curve.get_baked_length()
	if not forward:
		progress = 1.0 - progress
	# Ordered progress prevents a mouth touch or a reverse/side exit scoring.
	if rider.checkpoint <= 3 and progress >= float(rider.checkpoint) * 0.25:
		rider.checkpoint += 1
	var end_index := centerline.size() - 1 if forward else 0
	var start_index := entry_index if forward else reverse_entry_index
	if _crosses_gate(previous, current, end_index, not forward, true):
		var complete: bool = rider.checkpoint == 4
		ball.leave_route()
		_riders.erase(ball)
		if complete:
			traversed.emit(ball)
	elif _crosses_gate(previous, current, start_index, forward, true):
		ball.leave_route()
		_riders.erase(ball)


func _crosses_gate(previous: Vector2, current: Vector2, index: int, reverse: bool, exiting: bool = false) -> bool:
	var tangent := _endpoint_tangent(index)
	if reverse:
		tangent = -tangent
	var from := (previous - centerline[index]).dot(tangent)
	var to := (current - centerline[index]).dot(tangent)
	if from >= 0.0 or to < 0.0:
		return false
	var crossing := previous.lerp(current, -from / (to - from))
	var clearance := BALL_RADIUS + definition.rail_thickness * 0.5
	var half_width := _width_at(index) * 0.5 + clearance if exiting else _width_at(index) * 0.5 - clearance
	return absf((crossing - centerline[index]).dot(tangent.orthogonal())) <= half_width


func _endpoint_tangent(index: int) -> Vector2:
	if index == 0:
		return (centerline[1] - centerline[0]).normalized()
	if index < centerline.size() - 1:
		return (centerline[index + 1] - centerline[index - 1]).normalized()
	return (centerline[index] - centerline[index - 1]).normalized()


func _baked_point_index(control_index: int) -> int:
	var point: Vector2 = definition.points[control_index]
	return _baked_point_index_for_position(point)


func _baked_point_index_for_position(point: Vector2) -> int:
	var closest := 0
	for index in centerline.size():
		if centerline[index].distance_squared_to(point) < centerline[closest].distance_squared_to(point):
			closest = index
	return closest


func _width_at(index: int) -> float:
	var distance := absf(_offsets[index] - _offsets[entry_index])
	if definition.bidirectional:
		distance = minf(distance, absf(_offsets[index] - _offsets[reverse_entry_index]))
	var taper := smoothstep(0.0, definition.funnel_length, distance)
	return lerpf(definition.entry_width, definition.width, taper)
