class_name GullyAimVisual
extends Node2D


# Drag-to-aim indicator: band-coloured aim line and dots (green weak, amber
# medium, red-orange strong) plus a small power ring around the ball that
# fills with drag strength. Below the cancel threshold everything renders in
# a neutral grey so a tiny drag clearly reads as "no throw".

const LINE_WIDTH: float = 4.0
const DOT_RADIUS: float = 5.0
const DOT_COUNT: int = 6
const DOT_SPACING: float = 24.0
const POWER_RING_RADIUS: float = 24.0
const POWER_RING_WIDTH: float = 5.0
const POWER_RING_POINTS: int = 20

const CANCEL_COLOR: Color = Color(0.75, 0.73, 0.68, 0.55)
const RING_TRACK_COLOR: Color = Color(0.15, 0.12, 0.08, 0.45)
const WEAK_COLOR: Color = Color(0.38, 0.82, 0.36, 0.9)
const MEDIUM_COLOR: Color = Color(0.96, 0.75, 0.24, 0.9)
const STRONG_COLOR: Color = Color(0.95, 0.42, 0.20, 0.95)

var _active: bool = false
var _origin: Vector2 = Vector2.ZERO
var _target: Vector2 = Vector2.ZERO
var _strength: float = 0.0
var _clamped_distance: float = 0.0


func show_aim(origin: Vector2) -> void:
	_active = true
	_origin = origin
	_target = origin
	_strength = 0.0
	_clamped_distance = 0.0
	queue_redraw()


func update_aim(
	origin: Vector2, pointer_position: Vector2, strength: float, clamped_distance: float
) -> void:
	_origin = origin
	_target = pointer_position
	_strength = strength
	_clamped_distance = clamped_distance
	queue_redraw()


func clear_aim() -> void:
	_active = false
	queue_redraw()


func _draw() -> void:
	if not _active:
		return

	var displacement: Vector2 = _target - _origin
	var distance: float = displacement.length()
	if distance < 1.0:
		return

	var direction: Vector2 = displacement / distance
	var will_throw: bool = distance >= ThrowBall.MIN_DRAG_DISTANCE
	var color: Color = _get_power_color() if will_throw else CANCEL_COLOR
	var dot_color: Color = Color(color.r, color.g, color.b, color.a * 0.75)

	# Aim line, clamped to the maximum effective drag so overshooting the
	# clamp is visible instead of implying extra power.
	draw_line(_origin, _origin + direction * _clamped_distance, color, LINE_WIDTH, true)
	for dot_index: int in range(DOT_COUNT):
		var dot_distance: float = DOT_SPACING * float(dot_index + 1)
		if dot_distance > _clamped_distance:
			break
		draw_circle(_origin + direction * dot_distance, DOT_RADIUS, dot_color, true, -1.0, true)

	# Power ring gauge around the ball.
	draw_arc(
		_origin, POWER_RING_RADIUS, 0.0, TAU, POWER_RING_POINTS,
		RING_TRACK_COLOR, POWER_RING_WIDTH, true
	)
	if will_throw and _strength > 0.01:
		draw_arc(
			_origin,
			POWER_RING_RADIUS,
			-PI * 0.5,
			-PI * 0.5 + TAU * _strength,
			POWER_RING_POINTS,
			color,
			POWER_RING_WIDTH,
			true
		)


func _get_power_color() -> Color:
	match ThrowBall.get_power_band(_strength):
		ThrowBall.PowerBand.WEAK:
			return WEAK_COLOR
		ThrowBall.PowerBand.MEDIUM:
			return MEDIUM_COLOR
		_:
			return STRONG_COLOR
