class_name GullyDefenderVisual
extends Node2D


const DEFENDER_RADIUS: float = 26.0
const FILL_COLOR: Color = Color(0.85, 0.30, 0.20, 1.0)
const OUTLINE_COLOR: Color = Color(0.30, 0.08, 0.05, 1.0)
const BAND_COLOR: Color = Color(0.98, 0.92, 0.80, 1.0)


func _draw() -> void:
	draw_circle(Vector2.ZERO, DEFENDER_RADIUS, FILL_COLOR, true, -1.0, true)
	draw_circle(Vector2.ZERO, DEFENDER_RADIUS, OUTLINE_COLOR, false, 4.0, true)
	draw_arc(Vector2.ZERO, DEFENDER_RADIUS * 0.62, PI + 0.5, TAU - 0.5, 10, BAND_COLOR, 5.0, true)
