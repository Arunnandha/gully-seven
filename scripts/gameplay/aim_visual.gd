class_name GullyAimVisual
extends Node2D


const LINE_COLOR: Color = Color(1.0, 0.95, 0.75, 0.85)
const LINE_WIDTH: float = 4.0
const DOT_COLOR: Color = Color(1.0, 0.95, 0.75, 0.65)
const DOT_RADIUS: float = 5.0
const DOT_COUNT: int = 6
const DOT_SPACING: float = 24.0

var _active: bool = false
var _origin: Vector2 = Vector2.ZERO
var _target: Vector2 = Vector2.ZERO


func show_aim(origin: Vector2) -> void:
	_active = true
	_origin = origin
	_target = origin
	queue_redraw()


func update_aim(origin: Vector2, pointer_position: Vector2) -> void:
	_origin = origin
	_target = pointer_position
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
	draw_line(_origin, _target, LINE_COLOR, LINE_WIDTH, true)

	for dot_index: int in range(DOT_COUNT):
		var dot_distance: float = DOT_SPACING * float(dot_index + 1)
		if dot_distance > distance:
			break
		draw_circle(_origin + direction * dot_distance, DOT_RADIUS, DOT_COLOR, true, -1.0, true)
