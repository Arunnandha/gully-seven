class_name GullyPlayerVisual
extends Node2D


const PLAYER_RADIUS: float = 28.0
const SHADOW_OFFSET: float = PLAYER_RADIUS * 0.55
const SHADOW_SCALE: Vector2 = Vector2(1.05, 0.4)
const PULSE_SCALE: float = 1.18
const PULSE_UP_DURATION: float = 0.06
const PULSE_DOWN_DURATION: float = 0.12

var _fill_color: Color = Color(0.12, 0.78, 0.72, 1.0)
var _base_color: Color = Color(0.08, 0.58, 0.54, 1.0)
var _outline_color: Color = Color(0.03, 0.20, 0.19, 1.0)
var _highlight_color: Color = Color(0.75, 1.0, 0.96, 0.85)
var _marker_color: Color = Color(0.03, 0.20, 0.19, 0.9)
var _shadow_color: Color = Color(0.10, 0.06, 0.03, 0.30)
var _facing_direction: Vector2 = Vector2.DOWN
var _pulse_tween: Tween = null


func apply_theme(arena_theme: ArenaTheme) -> void:
	_fill_color = arena_theme.player_fill_color
	_base_color = arena_theme.player_fill_color.darkened(0.28)
	_outline_color = arena_theme.player_outline_color
	_highlight_color = arena_theme.player_highlight_color
	_marker_color = arena_theme.player_marker_color
	_shadow_color = arena_theme.object_shadow_color
	queue_redraw()


func set_facing_direction(direction: Vector2) -> void:
	if direction.length_squared() <= 0.0001:
		return
	_facing_direction = direction.normalized()
	queue_redraw()


func pulse() -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	scale = Vector2.ONE
	_pulse_tween = create_tween()
	_pulse_tween.set_trans(Tween.TRANS_BACK)
	_pulse_tween.tween_property(self, "scale", Vector2.ONE * PULSE_SCALE, PULSE_UP_DURATION)
	_pulse_tween.tween_property(self, "scale", Vector2.ONE, PULSE_DOWN_DURATION)


func reset_pulse() -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	scale = Vector2.ONE


func _draw() -> void:
	_draw_shadow()

	# Base/top layering gives a subtle 3D "puck" read instead of a flat disc.
	draw_circle(Vector2.ZERO, PLAYER_RADIUS, _base_color, true, -1.0, true)
	draw_circle(Vector2.ZERO, PLAYER_RADIUS * 0.86, _fill_color, true, -1.0, true)
	draw_circle(Vector2.ZERO, PLAYER_RADIUS, _outline_color, false, 4.0, true)
	draw_circle(
		Vector2(-PLAYER_RADIUS * 0.32, -PLAYER_RADIUS * 0.36), PLAYER_RADIUS * 0.30, _highlight_color, true, -1.0, true
	)

	var marker_tip: Vector2 = _facing_direction * PLAYER_RADIUS * 1.25
	var marker_base: Vector2 = _facing_direction * PLAYER_RADIUS * 0.55
	var perpendicular: Vector2 = _facing_direction.orthogonal() * PLAYER_RADIUS * 0.22
	var points: PackedVector2Array = PackedVector2Array([
		marker_tip, marker_base + perpendicular, marker_base - perpendicular,
	])
	draw_colored_polygon(points, _marker_color)


func _draw_shadow() -> void:
	draw_set_transform(Vector2(0.0, SHADOW_OFFSET), 0.0, SHADOW_SCALE)
	draw_circle(Vector2.ZERO, PLAYER_RADIUS, _shadow_color, true, -1.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
