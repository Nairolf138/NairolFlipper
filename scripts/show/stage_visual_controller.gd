class_name StageVisualController
extends Node2D

const STANDBY := 0
const PRESET := 1
const BUILD := 2
const FLOW := 3
const FINAL_SHOW := 4
const BLACKOUT := 5

const CYAN := Color("00e5ff")
const MAGENTA := Color("ff2bd6")
const AMBER := Color("ffb14a")
const VIOLET := Color("7c4dff")
const COLD_WHITE := Color("eaf6ff")
const FIXTURE_COLORS: Array[Color] = [AMBER, CYAN, VIOLET, Color("42ffb8"), Color("ff5748"), COLD_WHITE]

@export_range(0.0, 1.0, 0.05) var low_intensity: float = 0.08
@export_range(0.0, 1.0, 0.05) var build_intensity: float = 0.34
@export_range(0.0, 1.0, 0.05) var final_show_intensity: float = 0.78

var show_state: int = STANDBY
var rig_count: int = 0
var flow_ratio: float = 0.0
var pulse_time: float = 0.0
var hit_flash: float = 0.0
var hit_color: Color = COLD_WHITE


func _ready() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	pulse_time += delta
	hit_flash = maxf(0.0, hit_flash - delta * 3.8)
	queue_redraw()


func set_show_state(next_state: int) -> void:
	show_state = next_state
	queue_redraw()


func set_rig_progress(active_count: int) -> void:
	rig_count = clampi(active_count, 0, FIXTURE_COLORS.size())
	queue_redraw()


func set_flow(flow_points: int, maximum_flow: int = 1000) -> void:
	flow_ratio = clampf(float(flow_points) / maxf(float(maximum_flow), 1.0), 0.0, 1.0)
	queue_redraw()


func trigger_hit(color: Color = COLD_WHITE) -> void:
	hit_color = color
	hit_flash = 1.0
	queue_redraw()


func _draw() -> void:
	_draw_stage_grid()
	_draw_truss()
	_draw_fixture_beams()
	_draw_runway()
	if hit_flash > 0.0:
		draw_circle(Vector2(540, 920), 410.0 * hit_flash, Color(hit_color, 0.045 * hit_flash), false, 18.0)


func _draw_stage_grid() -> void:
	var grid_color := Color(CYAN, 0.025 + flow_ratio * 0.025)
	for x in range(120, 1000, 80):
		draw_line(Vector2(x, 410), Vector2(x, 1680), grid_color, 1.0)
	for y in range(440, 1680, 80):
		draw_line(Vector2(100, y), Vector2(980, y), grid_color, 1.0)


func _draw_truss() -> void:
	draw_line(Vector2(135, 300), Vector2(945, 300), Color(0.36, 0.46, 0.62, 0.58), 10.0)
	draw_line(Vector2(155, 278), Vector2(925, 278), Color(0.15, 0.2, 0.3, 0.8), 4.0)
	for index in FIXTURE_COLORS.size():
		var fixture_position := Vector2(165 + index * 150, 310)
		var active := index < rig_count or show_state == FINAL_SHOW
		var fixture_color := FIXTURE_COLORS[index]
		draw_circle(fixture_position, 22.0, Color(0.025, 0.035, 0.06, 1.0))
		draw_circle(fixture_position, 15.0, Color(fixture_color, 0.95 if active else 0.14))
		draw_arc(fixture_position, 25.0, 0.0, TAU, 24, Color(fixture_color, 0.8 if active else 0.2), 3.0)


func _draw_fixture_beams() -> void:
	if show_state == BLACKOUT or show_state == STANDBY:
		return
	var base_intensity := low_intensity
	if show_state == BUILD:
		base_intensity = build_intensity
	elif show_state == FLOW:
		base_intensity = 0.46 + flow_ratio * 0.16
	elif show_state == FINAL_SHOW:
		base_intensity = final_show_intensity
	var chase := int(floor(pulse_time * (7.0 if show_state == FINAL_SHOW else 2.0)))
	for index in FIXTURE_COLORS.size():
		var active := index < rig_count or show_state in [PRESET, FINAL_SHOW]
		if not active:
			continue
		var source := Vector2(165 + index * 150, 330)
		var sway := sin(pulse_time * 1.4 + index * 0.8) * (100.0 if show_state == FINAL_SHOW else 45.0)
		var target := Vector2(315 + index * 90 + sway, 1380)
		var width := 105.0 if show_state == FINAL_SHOW else 72.0
		var intensity := base_intensity
		if show_state == FINAL_SHOW and (index + chase) % 3 == 0:
			intensity = minf(1.0, intensity + 0.2)
		var beam_color := Color(FIXTURE_COLORS[index], intensity * 0.16)
		draw_colored_polygon(PackedVector2Array([source - Vector2(8, 0), source + Vector2(8, 0), target + Vector2(width, 0), target - Vector2(width, 0)]), beam_color)
		draw_circle(target, width, Color(FIXTURE_COLORS[index], intensity * 0.035))


func _draw_runway() -> void:
	var pulse := 0.55 + sin(pulse_time * 2.0) * 0.18
	var runway_color := Color(MAGENTA.lerp(CYAN, flow_ratio), (0.18 + flow_ratio * 0.25) * pulse)
	draw_polyline(PackedVector2Array([Vector2(475, 430), Vector2(400, 1580), Vector2(680, 1580), Vector2(605, 430)]), runway_color, 4.0)
	for step in 8:
		var y := 560.0 + step * 125.0
		var half_width := 52.0 + step * 10.0
		draw_line(Vector2(540 - half_width, y), Vector2(540 + half_width, y), Color(runway_color, runway_color.a * 0.65), 2.0)
