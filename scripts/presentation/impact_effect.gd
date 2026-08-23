class_name GullyImpactEffect
extends Node2D


const DURATION: float = 0.24
const START_SCALE: float = 0.55
const END_SCALE: float = 1.45
const EFFECT_COLOR: Color = Color(1.0, 0.88, 0.56, 0.92)

var _elapsed: float = 0.0


func _ready() -> void:
	visible = false
	set_process(false)


func play_at(impact_position: Vector2) -> void:
	global_position = impact_position
	_elapsed = 0.0
	scale = Vector2.ONE * START_SCALE
	modulate = Color.WHITE
	visible = true
	set_process(true)


func stop() -> void:
	set_process(false)
	visible = false
	_elapsed = 0.0
	modulate = Color.WHITE


func _process(delta: float) -> void:
	_elapsed += delta
	var progress: float = minf(_elapsed / DURATION, 1.0)
	var effect_scale: float = lerpf(START_SCALE, END_SCALE, progress)
	scale = Vector2.ONE * effect_scale
	modulate.a = 1.0 - progress
	if progress >= 1.0:
		stop()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 22.0, EFFECT_COLOR, false, 4.0, true)
	draw_line(Vector2(-34.0, 0.0), Vector2(-18.0, 0.0), EFFECT_COLOR, 4.0, true)
	draw_line(Vector2(34.0, 0.0), Vector2(18.0, 0.0), EFFECT_COLOR, 4.0, true)
	draw_line(Vector2(0.0, -34.0), Vector2(0.0, -18.0), EFFECT_COLOR, 4.0, true)
	draw_line(Vector2(0.0, 34.0), Vector2(0.0, 18.0), EFFECT_COLOR, 4.0, true)
