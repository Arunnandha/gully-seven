class_name StonePiece
extends Area2D


enum State {
	STACKED,
	SCATTERED,
	CARRIED,
	DEPOSITED,
}

signal stone_settled(piece: StonePiece)

const OUTLINE_COLOR: Color = Color(0.16, 0.10, 0.06, 1.0)
const SCATTER_FRICTION: float = 360.0
const ANGULAR_FRICTION: float = 5.0
const SETTLE_SPEED: float = 18.0
const SETTLE_ANGULAR_SPEED: float = 0.25

@export var stone_size: Vector2 = Vector2(118.0, 30.0)
@export var stone_color: Color = Color(0.50, 0.35, 0.22, 1.0)
@export_range(0, 6, 1) var stack_index: int = 0

@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

var current_state: State = State.STACKED
var _original_stack_position: Vector2 = Vector2.ZERO
var _scatter_velocity: Vector2 = Vector2.ZERO
var _scatter_angular_velocity: float = 0.0
var _viewport_size: Vector2 = Vector2.ZERO
var _scatter_active: bool = false


func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	_update_viewport_size()
	get_viewport().size_changed.connect(_update_viewport_size)


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
	set_physics_process(false)
	_scatter_active = false
	_scatter_velocity = Vector2.ZERO
	_scatter_angular_velocity = 0.0
	top_level = false
	position = _original_stack_position
	rotation = 0.0
	scale = Vector2.ONE
	current_state = State.STACKED


func start_scatter(initial_velocity: Vector2, initial_angular_velocity: float) -> void:
	var starting_global_position: Vector2 = global_position
	top_level = true
	global_position = starting_global_position
	current_state = State.SCATTERED
	_scatter_velocity = initial_velocity
	_scatter_angular_velocity = initial_angular_velocity
	_scatter_active = true
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if not _scatter_active:
		set_physics_process(false)
		return

	global_position += _scatter_velocity * delta
	rotation += _scatter_angular_velocity * delta
	_resolve_viewport_boundaries()

	_scatter_velocity = _scatter_velocity.move_toward(Vector2.ZERO, SCATTER_FRICTION * delta)
	_scatter_angular_velocity = move_toward(
		_scatter_angular_velocity,
		0.0,
		ANGULAR_FRICTION * delta
	)

	if (
		_scatter_velocity.length_squared() <= SETTLE_SPEED * SETTLE_SPEED
		and absf(_scatter_angular_velocity) <= SETTLE_ANGULAR_SPEED
	):
		_finish_scatter()


func _resolve_viewport_boundaries() -> void:
	var half_width: float = stone_size.x * 0.5
	var half_height: float = stone_size.y * 0.5
	var cosine: float = cos(rotation)
	var sine: float = sin(rotation)
	var extent_x: float = sqrt(
		half_width * half_width * cosine * cosine
		+ half_height * half_height * sine * sine
	)
	var extent_y: float = sqrt(
		half_width * half_width * sine * sine
		+ half_height * half_height * cosine * cosine
	)
	var stone_position: Vector2 = global_position

	if stone_position.x < extent_x:
		stone_position.x = extent_x
		_scatter_velocity.x = maxf(_scatter_velocity.x, 0.0)
	elif stone_position.x > _viewport_size.x - extent_x:
		stone_position.x = _viewport_size.x - extent_x
		_scatter_velocity.x = minf(_scatter_velocity.x, 0.0)

	if stone_position.y < extent_y:
		stone_position.y = extent_y
		_scatter_velocity.y = maxf(_scatter_velocity.y, 0.0)
	elif stone_position.y > _viewport_size.y - extent_y:
		stone_position.y = _viewport_size.y - extent_y
		_scatter_velocity.y = minf(_scatter_velocity.y, 0.0)

	global_position = stone_position


func get_separation_radius() -> float:
	return (stone_size.x + stone_size.y) * 0.25


func _finish_scatter() -> void:
	if not _scatter_active:
		return
	_scatter_active = false
	_scatter_velocity = Vector2.ZERO
	_scatter_angular_velocity = 0.0
	set_physics_process(false)
	stone_settled.emit(self)


func _update_viewport_size() -> void:
	_viewport_size = get_viewport_rect().size


func _apply_collision_size() -> void:
	var capsule: CapsuleShape2D = _collision_shape.shape as CapsuleShape2D
	capsule.radius = stone_size.y * 0.5
	capsule.height = stone_size.x


func _draw() -> void:
	var vertical_scale: float = stone_size.y / stone_size.x
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, vertical_scale))
	draw_circle(Vector2.ZERO, stone_size.x * 0.5, stone_color, true, -1.0, true)
	draw_circle(Vector2.ZERO, stone_size.x * 0.5, OUTLINE_COLOR, false, 3.0, true)
