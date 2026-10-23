extends StaticBody2D

## One path drives both the collision and its visible steel edge.
@export var points: PackedVector2Array
@export var thickness: float = 14.0
@export var edge_color: Color = Color("8ce9ff")


func _ready() -> void:
	for index in range(points.size() - 1):
		var direction := points[index + 1] - points[index]
		var segment := CapsuleShape2D.new()
		segment.radius = thickness * 0.5
		segment.height = direction.length() + thickness
		var collider := CollisionShape2D.new()
		collider.shape = segment
		collider.position = (points[index] + points[index + 1]) * 0.5
		collider.rotation = direction.angle() + PI * 0.5
		add_child(collider)
	queue_redraw()


func _draw() -> void:
	if points.size() < 2:
		return
	draw_set_transform(Vector2(4, 7))
	draw_polyline(points, Color(0, 0, 0, 0.42), thickness + 8.0, true)
	draw_set_transform(Vector2.ZERO)
	draw_polyline(points, Color("0b1219"), thickness + 3.0, true)
	draw_polyline(points, Color("5a656d"), thickness, true)
	draw_polyline(points, Color("c1c9c9"), thickness * 0.38, true)
	draw_set_transform(Vector2(-1, -1))
	draw_polyline(points, Color("f0f1e4"), 1.5, true)
	draw_set_transform(Vector2.ZERO)
