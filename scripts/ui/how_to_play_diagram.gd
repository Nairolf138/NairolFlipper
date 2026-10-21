class_name HowToPlayDiagram
extends Control

const CYAN := Color("00e5ff")
const MAGENTA := Color("ff2bd6")
const AMBER := Color("ffca4a")
const ICE := Color("eaf6ff")
const DIM := Color("39506b")
const DECK := Color("071526")

var page: int = 0


func set_page(next_page: int) -> void:
	page = clampi(next_page, 0, 3)
	queue_redraw()


func _draw() -> void:
	if size.x < 10.0 or size.y < 10.0:
		return
	var board := Rect2(size.x * 0.17, size.y * 0.04, size.x * 0.66, size.y * 0.9)
	draw_rect(board, DECK, true)
	draw_rect(board, Color("6685a6"), false, 4.0, true)
	match page:
		0:
			_draw_controls(board)
		1:
			_draw_rig(board)
		2:
			_draw_cues(board)
		3:
			_draw_final_show(board)


func _draw_controls(board: Rect2) -> void:
	var top_zone := Rect2(board.position, Vector2(board.size.x, board.size.y * 0.55))
	var left_zone := Rect2(
		board.position + Vector2(0.0, board.size.y * 0.55),
		Vector2(board.size.x * 0.5, board.size.y * 0.45)
	)
	var right_zone := Rect2(
		board.position + Vector2(board.size.x * 0.5, board.size.y * 0.55),
		Vector2(board.size.x * 0.5, board.size.y * 0.45)
	)
	draw_rect(top_zone, Color(CYAN, 0.18), true)
	draw_rect(left_zone, Color(MAGENTA, 0.2), true)
	draw_rect(right_zone, Color(AMBER, 0.18), true)
	_draw_ball(board.get_center() + Vector2(board.size.x * 0.32, board.size.y * 0.32))
	draw_line(
		board.get_center() + Vector2(board.size.x * 0.32, board.size.y * 0.26),
		board.get_center() + Vector2(board.size.x * 0.16, -board.size.y * 0.27),
		CYAN,
		8.0,
		true
	)
	_draw_flippers(board)
	_draw_centered_text("TOUCHER POUR LANCER", top_zone.get_center(), 24, CYAN)
	_draw_centered_text("FLIPPER G", left_zone.get_center() + Vector2(0.0, board.size.y * 0.1), 22, ICE)
	_draw_centered_text("FLIPPER D", right_zone.get_center() + Vector2(0.0, board.size.y * 0.1), 22, ICE)


func _draw_rig(board: Rect2) -> void:
	var colors: Array[Color] = [AMBER, Color("5f9dff"), Color("a56cff"), CYAN, Color("ff665d"), ICE]
	for index in colors.size():
		var column := index % 3
		var row := index / 3.0
		var position := board.position + Vector2(
			board.size.x * (0.23 + column * 0.27),
			board.size.y * (0.38 + row * 0.22)
		)
		draw_rect(Rect2(position - Vector2(42.0, 28.0), Vector2(84.0, 56.0)), colors[index], false, 6.0, true)
		draw_circle(position, 10.0, colors[index])
	_draw_centered_text("RIG  6 / 6", board.position + Vector2(board.size.x * 0.5, board.size.y * 0.14), 30, Color("59ffae"))
	_draw_centered_text("6 FAMILLES EN LIGNE", board.position + Vector2(board.size.x * 0.5, board.size.y * 0.82), 22, ICE)


func _draw_cues(board: Rect2) -> void:
	var warm_path := PackedVector2Array([
		board.position + Vector2(board.size.x * 0.16, board.size.y * 0.78),
		board.position + Vector2(board.size.x * 0.3, board.size.y * 0.5),
		board.position + Vector2(board.size.x * 0.2, board.size.y * 0.18),
	])
	var cold_path := PackedVector2Array([
		board.position + Vector2(board.size.x * 0.84, board.size.y * 0.78),
		board.position + Vector2(board.size.x * 0.7, board.size.y * 0.5),
		board.position + Vector2(board.size.x * 0.8, board.size.y * 0.18),
	])
	draw_polyline(warm_path, AMBER, 12.0, true)
	draw_polyline(cold_path, CYAN, 12.0, true)
	var console_rect := Rect2(
		board.position + Vector2(board.size.x * 0.28, board.size.y * 0.66),
		Vector2(board.size.x * 0.44, board.size.y * 0.14)
	)
	draw_rect(console_rect, Color("102b55"), true)
	draw_rect(console_rect, ICE, false, 4.0, true)
	_draw_centered_text("CONSOLE", console_rect.get_center(), 24, ICE)
	_draw_centered_text("1  →  2  →  3", board.position + Vector2(board.size.x * 0.5, board.size.y * 0.12), 30, MAGENTA)


func _draw_final_show(board: Rect2) -> void:
	for pulse_index in 4:
		var pulse_position := board.position + Vector2(
			board.size.x * (0.26 + pulse_index * 0.16),
			board.size.y * 0.14
		)
		draw_circle(pulse_position, 13.0, AMBER if pulse_index == 0 else DIM)
	var ball_positions: Array[Vector2] = [
		board.position + Vector2(board.size.x * 0.34, board.size.y * 0.48),
		board.position + Vector2(board.size.x * 0.52, board.size.y * 0.36),
		board.position + Vector2(board.size.x * 0.68, board.size.y * 0.55),
	]
	for ball_position in ball_positions:
		_draw_ball(ball_position)
	_draw_flippers(board)
	_draw_centered_text("FINAL SHOW", board.position + Vector2(board.size.x * 0.5, board.size.y * 0.76), 32, MAGENTA)
	_draw_centered_text("3 BILLES  •  SCORE x2", board.position + Vector2(board.size.x * 0.5, board.size.y * 0.85), 22, ICE)


func _draw_flippers(board: Rect2) -> void:
	var y := board.position.y + board.size.y * 0.82
	draw_line(
		Vector2(board.position.x + board.size.x * 0.2, y),
		Vector2(board.position.x + board.size.x * 0.43, y + 35.0),
		MAGENTA,
		20.0,
		true
	)
	draw_line(
		Vector2(board.position.x + board.size.x * 0.8, y),
		Vector2(board.position.x + board.size.x * 0.57, y + 35.0),
		MAGENTA,
		20.0,
		true
	)


func _draw_ball(position: Vector2) -> void:
	draw_circle(position + Vector2(5.0, 7.0), 18.0, Color(0.0, 0.0, 0.0, 0.55))
	draw_circle(position, 17.0, ICE)
	draw_circle(position - Vector2(5.0, 6.0), 5.0, Color.WHITE)


func _draw_centered_text(text: String, center: Vector2, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(
		font,
		center + Vector2(-text_size.x * 0.5, text_size.y * 0.32),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		color
	)
