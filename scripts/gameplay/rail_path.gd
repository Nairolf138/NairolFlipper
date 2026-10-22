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
	draw_polyline(points, Color("02050a"), thickness + 8.0, true)
	draw_polyline(points, Color("52677b"), thickness, true)
	draw_polyline(points, edge_color, 3.0, true)
