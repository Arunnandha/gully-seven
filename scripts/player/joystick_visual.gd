class_name GullyJoystickVisual
extends Node2D


const BASE_FILL: Color = Color(1.0, 1.0, 1.0, 0.10)
const BASE_OUTLINE: Color = Color(1.0, 1.0, 1.0, 0.55)
const KNOB_FILL: Color = Color(1.0, 1.0, 1.0, 0.38)
const KNOB_OUTLINE: Color = Color(1.0, 1.0, 1.0, 0.80)
const KNOB_RADIUS: float = 30.0

var _active: bool = false
var _origin: Vector2 = Vector2.ZERO
var _knob_position: Vector2 = Vector2.ZERO
var _radius: float = 90.0


func show_joystick(origin: Vector2) -> void:
	_active = true
	_origin = origin
	_knob_position = origin
	queue_redraw()


func update_joystick(input_vector: Vector2, radius: float) -> void:
	_radius = radius
	_knob_position = _origin + input_vector * radius
	queue_redraw()


func hide_joystick() -> void:
	_active = false
	queue_redraw()


func _draw() -> void:
	if not _active:
		return

	draw_circle(_origin, _radius, BASE_FILL, true, -1.0, true)
	draw_circle(_origin, _radius, BASE_OUTLINE, false, 4.0, true)
	draw_circle(_knob_position, KNOB_RADIUS, KNOB_FILL, true, -1.0, true)
	draw_circle(_knob_position, KNOB_RADIUS, KNOB_OUTLINE, false, 3.0, true)
