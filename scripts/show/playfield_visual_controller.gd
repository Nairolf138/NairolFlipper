class_name PlayfieldVisualController
extends Node2D

## Static vector art for Table 2.4. The controller deliberately avoids textures,
## particles and full-screen shaders so the visual pass stays cheap on tablets.

const DECK_TOP := 190.0
const DECK_BOTTOM := 1745.0
const CYAN := Color("00e5ff")
const MAGENTA := Color("ff2bd6")
const AMBER := Color("ffb14a")
const VIOLET := Color("7c4dff")
const STEEL := Color("8fa6bd")


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	_draw_cabinet()
	_draw_hud_bay()
	_draw_deck_panels()
	_draw_shot_routes()
	_draw_launcher_lane()
	_draw_drain_apron()


func _draw_cabinet() -> void:
	draw_rect(Rect2(24, 24, 1032, 1872), Color("02050a"), true)
	draw_rect(Rect2(28, 28, 1024, 1864), Color("52677b"), false, 7.0, true)
	draw_rect(Rect2(41, 41, 998, 1838), Color("101b28"), false, 3.0, true)
	draw_rect(Rect2(50, 50, 980, 1820), Color(0.02, 0.045, 0.075, 0.82), true)

	for corner in [Vector2(58, 58), Vector2(1022, 58), Vector2(58, 1862), Vector2(1022, 1862)]:
		draw_circle(corner, 9.0, Color("050910"))
		draw_circle(corner, 4.0, Color("b8c9d8"))


func _draw_hud_bay() -> void:
	var header := PackedVector2Array([
		Vector2(62, 58), Vector2(1018, 58), Vector2(1018, 188),
		Vector2(990, 208), Vector2(90, 208), Vector2(62, 188),
	])
	draw_colored_polygon(header, Color(0.025, 0.055, 0.095, 0.96))
	draw_polyline(PackedVector2Array([Vector2(72, 198), Vector2(1008, 198)]), Color(CYAN, 0.38), 3.0, true)
	draw_line(Vector2(420, 74), Vector2(420, 178), Color(STEEL, 0.2), 2.0)
	draw_line(Vector2(660, 74), Vector2(660, 178), Color(STEEL, 0.2), 2.0)

	var cue_bay := PackedVector2Array([
		Vector2(258, 215), Vector2(822, 215), Vector2(795, 286), Vector2(285, 286),
	])
	draw_colored_polygon(cue_bay, Color(0.03, 0.07, 0.13, 0.94))
	draw_polyline(PackedVector2Array([Vector2(285, 286), Vector2(795, 286)]), Color(VIOLET, 0.5), 3.0, true)


func _draw_deck_panels() -> void:
	var deck := PackedVector2Array([
		Vector2(76, DECK_TOP), Vector2(1004, DECK_TOP),
		Vector2(970, DECK_BOTTOM), Vector2(110, DECK_BOTTOM),
	])
	draw_colored_polygon(deck, Color("07101b"))

	# Perspective seams make the playfield read like a physical stage deck.
	for x_bottom in range(160, 961, 100):
		var x_top := lerpf(390.0, 690.0, inverse_lerp(160.0, 960.0, float(x_bottom)))
		draw_line(Vector2(x_top, 330), Vector2(x_bottom, DECK_BOTTOM), Color(STEEL, 0.075), 2.0)
	for index in range(10):
		var ratio := float(index) / 9.0
		var y := lerpf(390.0, DECK_BOTTOM, pow(ratio, 1.35))
		draw_line(Vector2(_deck_left(y), y), Vector2(_deck_right(y), y), Color(STEEL, 0.075), 2.0)

	# Two darker stage wings frame the play routes without relying on colour.
	draw_colored_polygon(PackedVector2Array([
		Vector2(78, 370), Vector2(350, 500), Vector2(315, 1550), Vector2(108, 1705),
	]), Color(0.035, 0.06, 0.09, 0.88))
	draw_colored_polygon(PackedVector2Array([
		Vector2(1002, 370), Vector2(730, 500), Vector2(765, 1550), Vector2(972, 1705),
	]), Color(0.035, 0.06, 0.09, 0.88))


func _draw_shot_routes() -> void:
	# Raised routes draw their own deck from the collision centerline.
	# Only the Console approach is painted on the base playfield.
	_draw_route(
		PackedVector2Array([Vector2(410, 1600), Vector2(540, 1260), Vector2(540, 890), Vector2(540, 350)]),
		VIOLET
	)

	# Short mouth marks guide cross-table shots into the real ramp entrances.
	for marker in [Vector2(350, 1190), Vector2(730, 1190)]:
		draw_line(marker - Vector2(18, 0), marker + Vector2(18, 0), Color("eaf6ff"), 3.0, true)


func _draw_route(points: PackedVector2Array, color: Color) -> void:
	draw_polyline(points, Color(0.0, 0.0, 0.0, 0.62), 30.0, true)
	draw_polyline(points, Color(color, 0.12), 20.0, true)
	draw_polyline(points, Color(color, 0.5), 3.0, true)


func _draw_launcher_lane() -> void:
	var centerline := PackedVector2Array([
		Vector2(960, 1740), Vector2(960, 650), Vector2(951, 604),
		Vector2(925, 565), Vector2(886, 539), Vector2(840, 530), Vector2(650, 590),
	])
	draw_polyline(centerline, Color(0.025, 0.09, 0.15, 0.9), 110.0, true)
	draw_line(Vector2(960, 1645), Vector2(960, 700), Color(CYAN, 0.2), 5.0, true)
	for index in range(4):
		var y := 1530.0 - index * 125.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(940, y + 26), Vector2(960, y), Vector2(980, y + 26), Vector2(970, y + 26),
			Vector2(960, y + 13), Vector2(950, y + 26),
		]), Color(CYAN, 0.3 + index * 0.08))


func _draw_drain_apron() -> void:
	var apron := PackedVector2Array([
		Vector2(175, 1660), Vector2(405, 1760), Vector2(540, 1835),
		Vector2(675, 1760), Vector2(905, 1660), Vector2(905, 1870),
		Vector2(175, 1870),
	])
	draw_colored_polygon(apron, Color(0.045, 0.02, 0.04, 0.78))
	draw_arc(Vector2(540, 1795), 145.0, PI, TAU, 40, Color(MAGENTA, 0.35), 4.0, true)
	for index in range(7):
		var x := 418.0 + index * 38.0
		draw_line(Vector2(x, 1810), Vector2(x + 22, 1832), Color(MAGENTA, 0.28), 8.0, true)


func _deck_left(y: float) -> float:
	return lerpf(76.0, 110.0, clampf(inverse_lerp(DECK_TOP, DECK_BOTTOM, y), 0.0, 1.0))


func _deck_right(y: float) -> float:
	return lerpf(1004.0, 970.0, clampf(inverse_lerp(DECK_TOP, DECK_BOTTOM, y), 0.0, 1.0))
