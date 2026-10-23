class_name PlayfieldVisualController
extends Node2D

## Static original artwork and path-aligned cabinet materials. No frame redraw.
const STAGE_DECK = preload("res://assets/textures/stagecraft/stage_deck.svg")
const CYAN := Color("00e5ff")
const STEEL := Color("8f9b9f")


func _draw() -> void:
	_draw_cabinet()
	_draw_deck_panels()
	_draw_hud_bay()
	_draw_shot_routes()
	_draw_launcher_lane()
	_draw_drain_apron()


func _draw_cabinet() -> void:
	draw_rect(Rect2(24, 24, 1032, 1872), Color("020509"))
	for border in range(12):
		var shade := 0.14 + sin(float(border) / 12.0 * PI) * 0.26
		draw_rect(Rect2(28 + border, 28 + border, 1024 - border * 2, 1864 - border * 2), Color(shade, shade * 1.06, shade * 1.1), false, 1.0)
	draw_rect(Rect2(44, 44, 992, 1832), Color("0b1016"))
	for corner in [Vector2(58, 58), Vector2(1022, 58), Vector2(58, 1862), Vector2(1022, 1862)]:
		draw_circle(corner, 7.0, Color("050910"))
		draw_circle(corner, 4.0, Color("a8b1b5"))
		draw_line(corner - Vector2(3, 0), corner + Vector2(3, 0), Color("1c242b"), 1.5)


func _draw_hud_bay() -> void:
	draw_rect(Rect2(62, 58, 956, 140), Color(0.025, 0.035, 0.05, 0.97))
	draw_line(Vector2(72, 198), Vector2(1008, 198), Color(STEEL, 0.4), 2.0, true)
	for x in [420, 660]:
		draw_line(Vector2(x, 74), Vector2(x, 178), Color(STEEL, 0.2), 2.0)
	draw_rect(Rect2(258, 210, 564, 78), Color(0.025, 0.035, 0.045, 0.94))


func _draw_deck_panels() -> void:
	draw_texture_rect(STAGE_DECK, Rect2(76, 200, 928, 1545), false)


func _draw_shot_routes() -> void:
	# Gaffer mouth marks, not painted fake paths. Actual routes own their art.
	for marker in [Vector2(350, 1190), Vector2(730, 1190)]:
		draw_line(marker - Vector2(14, 0), marker + Vector2(14, 0), Color("b1b5a2"), 3.0, true)


func _draw_launcher_lane() -> void:
	var centerline := PackedVector2Array([
		Vector2(960, 1740), Vector2(960, 650), Vector2(951, 604),
		Vector2(925, 565), Vector2(886, 539), Vector2(840, 530), Vector2(650, 590),
	])
	# Brushed trough follows the real guided launcher; no additional collider.
	draw_polyline(centerline, Color("060c12"), 110.0, true)
	draw_polyline(centerline, Color("555f63"), 99.0, true)
	draw_polyline(centerline, Color("252e33"), 91.0, true)
	draw_polyline(centerline, Color("151d24"), 75.0, true)
	draw_polyline(centerline, Color("313a3d"), 56.0, true)
	draw_polyline(centerline, Color("424b4e"), 34.0, true)
	for y in range(760, 1621, 120):
		draw_line(Vector2(915, y), Vector2(1005, y), Color("141d24"), 2.0, true)
		draw_circle(Vector2(913, y), 3.0, STEEL)
		draw_circle(Vector2(1007, y), 3.0, STEEL)


func _draw_drain_apron() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(175, 1660), Vector2(405, 1760), Vector2(540, 1835),
		Vector2(675, 1760), Vector2(905, 1660), Vector2(905, 1870), Vector2(175, 1870),
	]), Color("11171d"))
	draw_line(Vector2(200, 1850), Vector2(880, 1850), Color("596368"), 2.0, true)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(205, 1816), "NAIROL / LIVE STAGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("9ca8ac"))
	draw_string(font, Vector2(730, 1816), "BUILD · CUE · SHOW", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("77848c"))
