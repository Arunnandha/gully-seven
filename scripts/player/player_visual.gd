extends Node2D


const PLAYER_RADIUS: float = 28.0
const PLAYER_FILL: Color = Color(0.12, 0.78, 0.72, 1.0)
const PLAYER_OUTLINE: Color = Color(0.03, 0.20, 0.19, 1.0)


func _draw() -> void:
	draw_circle(Vector2.ZERO, PLAYER_RADIUS, PLAYER_FILL, true, -1.0, true)
	draw_circle(Vector2.ZERO, PLAYER_RADIUS, PLAYER_OUTLINE, false, 4.0, true)
