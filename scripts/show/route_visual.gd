class_name RouteVisual
extends Node2D

## Static 2.5D materials baked from the same edges as the collision rails.
## Acrylic on the climb, open chrome wireform on the return; no motion authority.
var _left := PackedVector2Array()
var _right := PackedVector2Array()
var _glass := PackedVector2Array()
var _ties: Array[PackedVector2Array] = []
var _supports := PackedVector2Array()
var _entries: Array[PackedVector2Array] = []
var _exits: Array[PackedVector2Array] = []
var _accent := Color.WHITE
var _rail_width := 10.0


func configure(route: PhysicalRoute) -> void:
	_accent = route.definition.route_color
	_rail_width = route.definition.rail_thickness
	var edges: Array[PackedVector2Array] = []
	for child in route.get_children():
		if child.has_meta("edge"):
			edges.append(child.get_meta("edge"))
	_left = edges[0]
	_right = edges[1]
	var control_index := clampi(route.definition.wire_start_point_index, 0, route.definition.points.size() - 1)
	var wire_index := route._baked_point_index(control_index)
	if wire_index > 0:
		_glass = _left.slice(0, wire_index + 1)
		var reverse := _right.slice(0, wire_index + 1)
		reverse.reverse()
		_glass.append_array(reverse)
	for offset in range(50, int(route.curve.get_baked_length()) - 40, 150):
		var point := route.curve.sample_baked(float(offset))
		var normal := (route.curve.sample_baked(float(offset) + 4.0) - point).normalized().orthogonal()
		var index := route._baked_point_index_for_position(point)
		var half_width := route._width_at(index) * 0.5
		_ties.append(PackedVector2Array([point - normal * half_width, point + normal * half_width]))
		if offset % 450 == 50:
			_supports.append(point + normal * (half_width + 5.0))
	_add_gate(route, route.entry_index, false, true)
	_add_gate(route, route.centerline.size() - 1, false, false)
	if route.definition.bidirectional:
		_add_gate(route, route.reverse_entry_index, true, true)
		_add_gate(route, 0, true, false)
	queue_redraw()


func _add_gate(route: PhysicalRoute, index: int, reverse: bool, entry: bool) -> void:
	var center := route.centerline[index]
	var tangent := route._endpoint_tangent(index) * (-1.0 if reverse else 1.0)
	var normal := tangent.orthogonal()
	if entry:
		_entries.append(PackedVector2Array([
			center - tangent * 18.0 + normal * 14.0,
			center + tangent * 4.0, center - tangent * 18.0 - normal * 14.0,
		]))
	else:
		var width := route._width_at(index) * 0.5
		_exits.append(PackedVector2Array([center - normal * width, center + normal * width]))


func _draw() -> void:
	if _left.is_empty():
		return
	# Contact feet and short columns establish height without an opaque ribbon.
	for point in _supports:
		var foot := point + Vector2(11, 22)
		draw_circle(foot + Vector2(3, 4), 12.0, Color(0, 0, 0, 0.24))
		draw_circle(foot, 9.0, Color("222a30"))
		draw_circle(foot, 7.0, Color("687177"), false, 2.0, true)
		draw_line(foot, point, Color("131a20"), 8.0, true)
		draw_line(foot - Vector2(2, 0), point - Vector2(2, 0), Color("8a9599"), 2.0, true)
		draw_circle(point, 3.0, Color(_accent, 0.85))
	if not _glass.is_empty():
		draw_colored_polygon(_glass, Color(0.24, 0.38, 0.42, 0.16))
	for tie in _ties:
		draw_polyline(tie, Color(0, 0, 0, 0.42), 7.0, true)
		draw_polyline(tie, Color("66757d"), 3.0, true)
	for edge in [_left, _right]:
		# Transform the draw, not the collider. The edge itself remains the datum.
		draw_set_transform(Vector2(9, 16))
		draw_polyline(edge, Color(0, 0, 0, 0.26), _rail_width + 9.0, true)
		draw_set_transform(Vector2.ZERO)
		draw_polyline(edge, Color("0a1118"), _rail_width + 4.0, true)
		draw_polyline(edge, Color("66727a"), _rail_width, true)
		draw_polyline(edge, Color("bac6ca"), _rail_width * 0.42, true)
		draw_set_transform(Vector2(-1.5, -1.5))
		draw_polyline(edge, Color("f0f3e8"), 1.5, true)
		draw_set_transform(Vector2.ZERO)
	for arrow in _entries:
		draw_polyline(arrow, Color("0b131b"), 8.0, true)
		draw_polyline(arrow, Color(_accent, 0.9), 3.0, true)
	for lip in _exits:
		draw_polyline(lip, Color("111922"), 9.0, true)
		draw_polyline(lip, Color("c2cece"), 4.0, true)
