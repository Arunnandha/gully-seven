class_name GullyBallVisual
extends Node2D


const BALL_RADIUS: float = 14.0
const SHADOW_OFFSET: float = BALL_RADIUS * 0.6
const SHADOW_SCALE: Vector2 = Vector2(1.0, 0.45)

var _fill_color: Color = Color(0.95, 0.90, 0.78, 1.0)
var _outline_color: Color = Color(0.35, 0.25, 0.12, 1.0)
var _highlight_color: Color = Color(1.0, 1.0, 0.96, 0.9)
var _shadow_color: Color = Color(0.10, 0.06, 0.03, 0.30)


func apply_theme(arena_theme: ArenaTheme) -> void:
	_fill_color = arena_theme.ball_fill_color
	_outline_color = arena_theme.ball_outline_color
	_highlight_color = arena_theme.ball_highlight_color
	_shadow_color = arena_theme.object_shadow_color
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(0.0, SHADOW_OFFSET), 0.0, SHADOW_SCALE)
	draw_circle(Vector2.ZERO, BALL_RADIUS * 1.1, _shadow_color, true, -1.0, true)
	var core_color: Color = _shadow_color
	core_color.a = minf(_shadow_color.a * 1.7, 0.6)
	draw_circle(Vector2.ZERO, BALL_RADIUS * 0.65, core_color, true, -1.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	draw_circle(Vector2.ZERO, BALL_RADIUS, _fill_color, true, -1.0, true)
	draw_circle(Vector2.ZERO, BALL_RADIUS, _outline_color, false, 3.5, true)
	draw_circle(Vector2(-BALL_RADIUS * 0.3, -BALL_RADIUS * 0.3), BALL_RADIUS * 0.28, _highlight_color, true, -1.0, true)
