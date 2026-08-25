class_name StonePiece
extends Area2D


enum State {
	STACKED,
	SCATTERED,
	CARRIED,
	DEPOSITED,
}

signal stone_settled(piece: StonePiece)
signal stone_collected(piece: StonePiece)

const SCATTER_FRICTION: float = 360.0
const ANGULAR_FRICTION: float = 5.0
const SETTLE_SPEED: float = 18.0
const SETTLE_ANGULAR_SPEED: float = 0.25
const PICKUP_PULSE_SCALE: float = 1.35
const PICKUP_PULSE_UP_DURATION: float = 0.08
const PICKUP_PULSE_DOWN_DURATION: float = 0.14
const SHADOW_OFFSET_RATIO: float = 0.12
const SHADOW_SCALE_RATIO: float = 0.88
const SAFE_RING_WIDTH: float = 2.5
const SAFE_RING_MARGIN: float = 4.0

@export var stone_size: Vector2 = Vector2(118.0, 30.0)
@export var stone_color: Color = Color(0.50, 0.35, 0.22, 1.0)
@export_range(0, 6, 1) var stack_index: int = 0

@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

var current_state: State = State.STACKED
var _original_stack_position: Vector2 = Vector2.ZERO
var _scatter_velocity: Vector2 = Vector2.ZERO
var _scatter_angular_velocity: float = 0.0
var _scatter_active: bool = false
var _pickup_tween: Tween = null
var _outline_color: Color = Color(0.16, 0.10, 0.06, 1.0)
var _highlight_color: Color = Color(1.0, 0.95, 0.85, 0.30)
var _shadow_color: Color = Color(0.10, 0.06, 0.03, 0.30)
var _safe_ring_color: Color = Color(0.98, 0.92, 0.75, 0.85)


func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	monitoring = false
	body_entered.connect(_on_body_entered)


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


func apply_theme(arena_theme: ArenaTheme) -> void:
	_outline_color = arena_theme.stone_outline_color
	_highlight_color = arena_theme.stone_highlight_color
	_shadow_color = arena_theme.object_shadow_color
	_safe_ring_color = arena_theme.stone_safe_ring_color
	queue_redraw()


func reset_to_stack() -> void:
	set_physics_process(false)
	_scatter_active = false
	_scatter_velocity = Vector2.ZERO
	_scatter_angular_velocity = 0.0
	set_deferred("monitoring", false)
	if _pickup_tween != null and _pickup_tween.is_valid():
		_pickup_tween.kill()
	top_level = false
	position = _original_stack_position
	rotation = 0.0
	scale = Vector2.ONE
	current_state = State.STACKED
	queue_redraw()


func is_collectible() -> bool:
	return current_state == State.SCATTERED and not _scatter_active


func set_collection_enabled(enabled: bool) -> void:
	set_deferred("monitoring", enabled and current_state == State.SCATTERED)


func drop_scattered(drop_position: Vector2) -> void:
	set_physics_process(false)
	_scatter_active = false
	_scatter_velocity = Vector2.ZERO
	_scatter_angular_velocity = 0.0
	if _pickup_tween != null and _pickup_tween.is_valid():
		_pickup_tween.kill()
	scale = Vector2.ONE
	top_level = true
	# Final placement guarantee: whatever the requested spot, the piece lands
	# inside the shared collectible-safe rect for its current rotation.
	global_position = PlayableArea.clamp_to_bounds(
		drop_position,
		PlayableArea.get_collectible_bounds(_get_rotated_extents(), get_pickup_radius())
	)
	current_state = State.SCATTERED
	queue_redraw()


func deposit_to_stack() -> void:
	set_physics_process(false)
	_scatter_active = false
	_scatter_velocity = Vector2.ZERO
	_scatter_angular_velocity = 0.0
	set_deferred("monitoring", false)
	top_level = false
	rotation = 0.0
	scale = Vector2.ONE
	current_state = State.DEPOSITED
	queue_redraw()
	play_pickup_feedback()


func play_pickup_feedback() -> void:
	if _pickup_tween != null and _pickup_tween.is_valid():
		_pickup_tween.kill()
	scale = Vector2.ONE
	_pickup_tween = create_tween()
	_pickup_tween.set_trans(Tween.TRANS_BACK)
	_pickup_tween.tween_property(self, "scale", Vector2.ONE * PICKUP_PULSE_SCALE, PICKUP_PULSE_UP_DURATION)
	_pickup_tween.tween_property(self, "scale", Vector2.ONE, PICKUP_PULSE_DOWN_DURATION)


func _on_body_entered(body: Node2D) -> void:
	if not (body is GullyPlayerController):
		return
	if not is_collectible():
		return
	current_state = State.CARRIED
	set_deferred("monitoring", false)
	queue_redraw()
	play_pickup_feedback()
	stone_collected.emit(self)


func start_scatter(initial_velocity: Vector2, initial_angular_velocity: float) -> void:
	var starting_global_position: Vector2 = global_position
	top_level = true
	global_position = starting_global_position
	current_state = State.SCATTERED
	_scatter_velocity = initial_velocity
	_scatter_angular_velocity = initial_angular_velocity
	_scatter_active = true
	set_physics_process(true)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not _scatter_active:
		set_physics_process(false)
		return

	global_position += _scatter_velocity * delta
	rotation += _scatter_angular_velocity * delta
	_resolve_playable_boundaries()

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


# Clamp into the shared collectible-safe rect (visible AND within the
# player's guaranteed pickup reach), zeroing any velocity component that
# still points outward so bounces can never carry the piece back out.
func _resolve_playable_boundaries() -> void:
	var bounds: Rect2 = PlayableArea.get_collectible_bounds(
		_get_rotated_extents(), get_pickup_radius()
	)
	var stone_position: Vector2 = global_position

	if stone_position.x < bounds.position.x:
		stone_position.x = bounds.position.x
		_scatter_velocity.x = maxf(_scatter_velocity.x, 0.0)
	elif stone_position.x > bounds.end.x:
		stone_position.x = bounds.end.x
		_scatter_velocity.x = minf(_scatter_velocity.x, 0.0)

	if stone_position.y < bounds.position.y:
		stone_position.y = bounds.position.y
		_scatter_velocity.y = maxf(_scatter_velocity.y, 0.0)
	elif stone_position.y > bounds.end.y:
		stone_position.y = bounds.end.y
		_scatter_velocity.y = minf(_scatter_velocity.y, 0.0)

	global_position = stone_position


func get_pickup_radius() -> float:
	return stone_size.y * 0.5


func _get_rotated_extents() -> Vector2:
	var half_width: float = stone_size.x * 0.5
	var half_height: float = stone_size.y * 0.5
	var cosine: float = cos(rotation)
	var sine: float = sin(rotation)
	return Vector2(
		sqrt(
			half_width * half_width * cosine * cosine
			+ half_height * half_height * sine * sine
		),
		sqrt(
			half_width * half_width * sine * sine
			+ half_height * half_height * cosine * cosine
		)
	)


func get_separation_radius() -> float:
	return (stone_size.x + stone_size.y) * 0.25


func get_separation_extent(world_direction: Vector2) -> float:
	var direction: Vector2 = world_direction.normalized()
	if direction.length_squared() <= 0.0:
		return stone_size.x * 0.5
	var local_direction: Vector2 = direction.rotated(-global_rotation)
	var half_width: float = stone_size.x * 0.5
	var half_height: float = stone_size.y * 0.5
	return sqrt(
		half_width * half_width * local_direction.x * local_direction.x
		+ half_height * half_height * local_direction.y * local_direction.y
	)


func apply_settle_separation(offset: Vector2) -> void:
	global_position += offset
	_resolve_playable_boundaries()


func _finish_scatter() -> void:
	if not _scatter_active:
		return
	_scatter_active = false
	_scatter_velocity = Vector2.ZERO
	_scatter_angular_velocity = 0.0
	set_physics_process(false)
	# Deterministic settle-time validation: the final rotation may differ from
	# the one active during the last bounce clamp, so re-check once here.
	_resolve_playable_boundaries()
	stone_settled.emit(self)


func _apply_collision_size() -> void:
	var capsule: CapsuleShape2D = _collision_shape.shape as CapsuleShape2D
	capsule.radius = stone_size.y * 0.5
	capsule.height = stone_size.x


func _draw() -> void:
	var vertical_scale: float = stone_size.y / stone_size.x
	_draw_shadow(vertical_scale)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, vertical_scale))
	draw_circle(Vector2.ZERO, stone_size.x * 0.5, stone_color, true, -1.0, true)
	draw_circle(Vector2.ZERO, stone_size.x * 0.5, _outline_color, false, 3.0, true)
	draw_circle(
		Vector2(-stone_size.x * 0.18, -stone_size.x * 0.18),
		stone_size.x * 0.22,
		_highlight_color,
		true,
		-1.0,
		true
	)
	if current_state == State.STACKED or current_state == State.DEPOSITED:
		draw_circle(
			Vector2.ZERO, stone_size.x * 0.5 + SAFE_RING_MARGIN, _safe_ring_color, false, SAFE_RING_WIDTH, true
		)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_shadow(vertical_scale: float) -> void:
	var shadow_scale: Vector2 = Vector2(SHADOW_SCALE_RATIO, vertical_scale * SHADOW_SCALE_RATIO * 0.85)
	draw_set_transform(Vector2(0.0, stone_size.x * SHADOW_OFFSET_RATIO), 0.0, shadow_scale)
	draw_circle(Vector2.ZERO, stone_size.x * 0.54, _shadow_color, true, -1.0, true)
	var core_color: Color = _shadow_color
	core_color.a = minf(_shadow_color.a * 1.6, 0.6)
	draw_circle(Vector2.ZERO, stone_size.x * 0.36, core_color, true, -1.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
