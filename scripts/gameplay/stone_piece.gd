class_name StonePiece
extends Area2D


enum State {
	STACKED,
	SCATTERED,
	CARRIED,
	DEPOSITED,
}

const OUTLINE_COLOR: Color = Color(0.16, 0.10, 0.06, 1.0)

@export var stone_size: Vector2 = Vector2(118.0, 30.0)
@export var stone_color: Color = Color(0.50, 0.35, 0.22, 1.0)
@export_range(0, 6, 1) var stack_index: int = 0

@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

var current_state: State = State.STACKED
var _original_stack_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	set_process_input(false)


func configure(
	configured_size: Vector2,
	configured_color: Color,
	configured_stack_index: int,
	stack_position: Vector2
) -> void:
	stone_size = configured_size
	stone_color = configured_color
	stack_index = configured_stack_index
	_original_stack_position = stack_position
	_apply_collision_size()
	queue_redraw()


func reset_to_stack() -> void:
	position = _original_stack_position
	rotation = 0.0
	scale = Vector2.ONE
	current_state = State.STACKED


func _apply_collision_size() -> void:
	var capsule: CapsuleShape2D = _collision_shape.shape as CapsuleShape2D
	capsule.radius = stone_size.y * 0.5
	capsule.height = stone_size.x


func _draw() -> void:
	var vertical_scale: float = stone_size.y / stone_size.x
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, vertical_scale))
	draw_circle(Vector2.ZERO, stone_size.x * 0.5, stone_color, true, -1.0, true)
	draw_circle(Vector2.ZERO, stone_size.x * 0.5, OUTLINE_COLOR, false, 3.0, true)
