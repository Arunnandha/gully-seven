class_name GullyBallVisual
extends Node2D


const BALL_RADIUS: float = 14.0
const BALL_FILL: Color = Color(0.95, 0.90, 0.78, 1.0)
const BALL_OUTLINE: Color = Color(0.35, 0.25, 0.12, 1.0)


func _draw() -> void:
	draw_circle(Vector2.ZERO, BALL_RADIUS, BALL_FILL, true, -1.0, true)
	draw_circle(Vector2.ZERO, BALL_RADIUS, BALL_OUTLINE, false, 3.0, true)
