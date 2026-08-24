class_name GameEffect
extends Node2D


enum Style {
	RING,
	SPARKLE,
	DUST,
	BURST,
}

const DEFAULT_DURATION: float = 0.3

var _elapsed: float = 0.0
var _duration: float = DEFAULT_DURATION
var _color: Color = Color.WHITE
var _style: Style = Style.RING
var _start_scale: float = 0.55
var _end_scale: float = 1.45


func _ready() -> void:
	visible = false
	set_process(false)


func play(
	effect_position: Vector2,
	style: Style,
	color: Color,
	duration: float = DEFAULT_DURATION,
	start_scale: float = 0.55,
	end_scale: float = 1.45
) -> void:
	global_position = effect_position
	_style = style
	_color = color
	_duration = maxf(duration, 0.01)
	_start_scale = start_scale
	_end_scale = end_scale
	_elapsed = 0.0
	scale = Vector2.ONE * _start_scale
	modulate = Color.WHITE
	visible = true
	set_process(true)
	queue_redraw()


func stop() -> void:
	set_process(false)
	visible = false
	modulate = Color.WHITE


func _process(delta: float) -> void:
	_elapsed += delta
	var progress: float = minf(_elapsed / _duration, 1.0)
	scale = Vector2.ONE * lerpf(_start_scale, _end_scale, progress)
	modulate.a = 1.0 - progress
	queue_redraw()
	if progress >= 1.0:
		stop()


func _draw() -> void:
	match _style:
		Style.RING:
			draw_circle(Vector2.ZERO, 22.0, _color, false, 4.0, true)
		Style.BURST:
			draw_circle(Vector2.ZERO, 22.0, _color, false, 4.0, true)
			draw_line(Vector2(-34.0, 0.0), Vector2(-18.0, 0.0), _color, 4.0, true)
			draw_line(Vector2(34.0, 0.0), Vector2(18.0, 0.0), _color, 4.0, true)
			draw_line(Vector2(0.0, -34.0), Vector2(0.0, -18.0), _color, 4.0, true)
			draw_line(Vector2(0.0, 34.0), Vector2(0.0, 18.0), _color, 4.0, true)
		Style.SPARKLE:
			for spark_index: int in range(5):
				var angle: float = TAU * float(spark_index) / 5.0
				var tip: Vector2 = Vector2.RIGHT.rotated(angle) * 20.0
				draw_line(Vector2.ZERO, tip, _color, 3.0, true)
				draw_circle(tip, 3.0, _color, true, -1.0, true)
		Style.DUST:
			for puff_index: int in range(4):
				var angle: float = TAU * float(puff_index) / 4.0 + 0.4
				var puff_center: Vector2 = Vector2.RIGHT.rotated(angle) * 16.0
				draw_circle(puff_center, 8.0, _color, true, -1.0, true)
