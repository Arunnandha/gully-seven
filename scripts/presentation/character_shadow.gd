class_name GullyCharacterShadow
extends Node2D


# Ground shadow for a character, kept as its own node so it can sit on the
# dedicated shadow layer (below the rebuild circle and stones) while the
# body draws above them. Static: redraws only on theme changes.

const SHADOW_SCALE: Vector2 = Vector2(1.0, 0.42)
const GROUND_OFFSET: Vector2 = Vector2(0.0, 2.0)

@export var shadow_radius: float = 17.0

var _color: Color = Color(0.10, 0.06, 0.03, 0.30)


func set_shadow_color(color: Color) -> void:
	if _color == color:
		return
	_color = color
	queue_redraw()


func _draw() -> void:
	draw_set_transform(GROUND_OFFSET, 0.0, SHADOW_SCALE)
	draw_circle(Vector2.ZERO, shadow_radius * 1.15, _color, true, -1.0, true)
	var core_color: Color = _color
	core_color.a = minf(_color.a * 1.7, 0.6)
	draw_circle(Vector2.ZERO, shadow_radius * 0.7, core_color, true, -1.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
