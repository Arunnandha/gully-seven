class_name GullyDefenderVisual
extends Node2D


const DEFENDER_RADIUS: float = 26.0
const SHADOW_OFFSET: float = DEFENDER_RADIUS * 0.55
const SHADOW_SCALE: Vector2 = Vector2(1.05, 0.4)

var _fill_color: Color = Color(0.85, 0.30, 0.20, 1.0)
var _base_color: Color = Color(0.62, 0.18, 0.12, 1.0)
var _outline_color: Color = Color(0.30, 0.08, 0.05, 1.0)
var _grace_outline_color: Color = Color(0.95, 0.92, 0.85, 0.9)
var _band_color: Color = Color(0.98, 0.92, 0.80, 1.0)
var _marker_color: Color = Color(0.30, 0.08, 0.05, 0.95)
var _shadow_color: Color = Color(0.10, 0.06, 0.03, 0.30)
var _grace_active: bool = false
var _facing_direction: Vector2 = Vector2.LEFT


func apply_theme(arena_theme: ArenaTheme) -> void:
	_fill_color = arena_theme.defender_fill_color
	_base_color = arena_theme.defender_fill_color.darkened(0.30)
	_outline_color = arena_theme.defender_outline_color
	_grace_outline_color = arena_theme.defender_grace_outline_color
	_band_color = arena_theme.defender_band_color
	_marker_color = arena_theme.defender_marker_color
	_shadow_color = arena_theme.object_shadow_color
	queue_redraw()


func set_grace_active(active: bool) -> void:
	if _grace_active == active:
		return
	_grace_active = active
	queue_redraw()


func set_facing_direction(direction: Vector2) -> void:
	if direction.length_squared() <= 0.0001:
		return
	_facing_direction = direction.normalized()
	queue_redraw()


func _draw() -> void:
	_draw_shadow()

	draw_circle(Vector2.ZERO, DEFENDER_RADIUS, _base_color, true, -1.0, true)
	draw_circle(Vector2.ZERO, DEFENDER_RADIUS * 0.86, _fill_color, true, -1.0, true)
	var outline_color: Color = _grace_outline_color if _grace_active else _outline_color
	draw_circle(Vector2.ZERO, DEFENDER_RADIUS, outline_color, false, 4.0, true)
	draw_arc(Vector2.ZERO, DEFENDER_RADIUS * 0.62, PI + 0.5, TAU - 0.5, 10, _band_color, 5.0, true)

	var marker_tip: Vector2 = _facing_direction * DEFENDER_RADIUS * 1.2
	var marker_base: Vector2 = _facing_direction * DEFENDER_RADIUS * 0.5
	var perpendicular: Vector2 = _facing_direction.orthogonal() * DEFENDER_RADIUS * 0.22
	var points: PackedVector2Array = PackedVector2Array([
		marker_tip, marker_base + perpendicular, marker_base - perpendicular,
	])
	draw_colored_polygon(points, _marker_color)

	if _grace_active:
		_draw_grace_ring()


func _draw_grace_ring() -> void:
	var dash_count: int = 12
	var dash_angle: float = TAU / float(dash_count)
	for dash_index: int in range(dash_count):
		var start_angle: float = dash_angle * float(dash_index)
		draw_arc(
			Vector2.ZERO,
			DEFENDER_RADIUS + 8.0,
			start_angle,
			start_angle + dash_angle * 0.5,
			4,
			_grace_outline_color,
			3.0,
			true
		)


func _draw_shadow() -> void:
	draw_set_transform(Vector2(0.0, SHADOW_OFFSET), 0.0, SHADOW_SCALE)
	draw_circle(Vector2.ZERO, DEFENDER_RADIUS, _shadow_color, true, -1.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
