class_name StoneTower
extends Node2D


signal tower_scatter_started(impact_position: Vector2)
signal tower_scatter_finished

const STONE_COUNT: int = 7
const BOTTOM_WIDTH: float = 118.0
const BOTTOM_HEIGHT: float = 30.0
const WIDTH_STEP: float = 11.0
const HEIGHT_STEP: float = 1.25
const STACK_SPACING: float = 20.0
const StonePieceType = preload("res://scripts/gameplay/stone_piece.gd")

# Target travel distance (logical px from tower center) grows from the
# heaviest/bottom stone to the lightest/top stone, so speed differences
# fall out of the distance formula instead of being tuned separately.
const MIN_INDEX_DISTANCE: float = 140.0
const MAX_INDEX_DISTANCE: float = 230.0
const DISTANCE_SCALE_MIN: float = 0.85
const DISTANCE_SCALE_MAX: float = 1.15
const ANGLE_JITTER_MIN: float = 0.10
const ANGLE_JITTER_MAX: float = 0.30
const OUTLIER_CHANCE: float = 0.35
const OUTLIER_BONUS_MIN: float = 40.0
const OUTLIER_BONUS_MAX: float = 110.0
const EDGE_SAFETY_MARGIN: float = 40.0
const HARD_DISTANCE_CEILING: float = 340.0
const MINIMUM_DISTANCE: float = 40.0

# One fan offset per stack index (0 = bottom/heaviest .. 6 = top/lightest),
# broad enough to cover forward, sideways, and one backward-leaning stone.
const FAN_ANGLE_BY_INDEX: Array[float] = [
	0.05, -0.35, 0.40, -0.80, 0.85, -1.35, 2.05,
]

@export var stone_piece_scene: PackedScene
@export var scatter_seed: int = 73471

var _pieces: Array[StonePieceType] = []
var _scatter_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _settled_piece_count: int = 0
var _scatter_active: bool = false


func _ready() -> void:
	_create_stone_pieces()
	reset_stack()
	set_process(false)
	set_physics_process(false)
	set_process_input(false)


func reset_stack() -> void:
	_scatter_active = false
	_settled_piece_count = 0
	set_physics_process(false)
	for piece: StonePieceType in _pieces:
		piece.reset_to_stack()


func get_footprint_radius() -> float:
	return BOTTOM_WIDTH * 0.5 + 12.0


func scatter(
	impact_direction: Vector2,
	impact_speed: float,
	impact_position: Vector2
) -> void:
	if _scatter_active:
		return

	var normalized_impact: Vector2 = impact_direction.normalized()
	if normalized_impact.length_squared() <= 0.0:
		normalized_impact = Vector2.RIGHT

	var strength_t: float = clampf(impact_speed / ThrowBall.MAX_THROW_SPEED, 0.0, 1.0)
	var distance_scale: float = lerpf(DISTANCE_SCALE_MIN, DISTANCE_SCALE_MAX, strength_t)
	var angle_jitter_limit: float = lerpf(ANGLE_JITTER_MIN, ANGLE_JITTER_MAX, strength_t)
	var max_allowed_distance: float = _get_max_allowed_distance()

	_scatter_rng.seed = scatter_seed
	_settled_piece_count = 0
	_scatter_active = true
	set_physics_process(true)
	tower_scatter_started.emit(impact_position)

	for piece: StonePieceType in _pieces:
		var index_t: float = float(piece.stack_index) / float(STONE_COUNT - 1)
		var target_distance: float = lerpf(MIN_INDEX_DISTANCE, MAX_INDEX_DISTANCE, index_t)
		target_distance *= distance_scale

		if piece.stack_index == STONE_COUNT - 1 and _scatter_rng.randf() < OUTLIER_CHANCE:
			target_distance += lerpf(OUTLIER_BONUS_MIN, OUTLIER_BONUS_MAX, strength_t)

		target_distance = clampf(target_distance, MINIMUM_DISTANCE, HARD_DISTANCE_CEILING)
		target_distance = minf(target_distance, max_allowed_distance)

		var jitter: float = _scatter_rng.randf_range(-angle_jitter_limit, angle_jitter_limit)
		var direction: Vector2 = normalized_impact.rotated(
			FAN_ANGLE_BY_INDEX[piece.stack_index] + jitter
		)
		var initial_speed: float = sqrt(
			2.0 * StonePiece.SCATTER_FRICTION * target_distance
			+ StonePiece.SETTLE_SPEED * StonePiece.SETTLE_SPEED
		)
		var spin_direction: float = -1.0 if piece.stack_index % 2 == 0 else 1.0
		var angular_velocity: float = spin_direction * (
			2.0 + float(piece.stack_index) * 0.25
		) + _scatter_rng.randf_range(-0.3, 0.3)
		piece.start_scatter(direction * initial_speed, angular_velocity)


func _get_max_allowed_distance() -> float:
	var viewport_rect: Rect2 = get_viewport_rect()
	var distance_to_left: float = global_position.x - viewport_rect.position.x
	var distance_to_right: float = viewport_rect.end.x - global_position.x
	var distance_to_top: float = global_position.y - viewport_rect.position.y
	var distance_to_bottom: float = viewport_rect.end.y - global_position.y
	var closest_edge: float = minf(
		minf(distance_to_left, distance_to_right),
		minf(distance_to_top, distance_to_bottom)
	)
	return maxf(MINIMUM_DISTANCE, closest_edge - EDGE_SAFETY_MARGIN)


func _physics_process(_delta: float) -> void:
	if not _scatter_active:
		set_physics_process(false)
		return
	_resolve_piece_separation()


func _resolve_piece_separation() -> void:
	for first_index: int in range(_pieces.size()):
		for second_index: int in range(first_index + 1, _pieces.size()):
			_separate_pair(_pieces[first_index], _pieces[second_index])


func _separate_pair(first: StonePieceType, second: StonePieceType) -> void:
	var offset: Vector2 = second.global_position - first.global_position
	var distance: float = offset.length()
	var minimum_distance: float = first.get_separation_radius() + second.get_separation_radius()
	if distance >= minimum_distance or distance <= 0.0001:
		return
	var overlap: float = minimum_distance - distance
	var push: Vector2 = offset / distance * (overlap * 0.5)
	first.global_position -= push
	second.global_position += push


func _create_stone_pieces() -> void:
	assert(stone_piece_scene != null, "StoneTower requires a StonePiece scene.")
	if not _pieces.is_empty():
		return

	for stack_index: int in range(STONE_COUNT):
		var piece: StonePieceType = stone_piece_scene.instantiate() as StonePieceType
		assert(piece != null, "StonePiece scene root must use the StonePiece script.")
		add_child(piece)
		_pieces.append(piece)
		piece.stone_settled.connect(_on_stone_settled)
		piece.configure(
			_get_stone_size(stack_index),
			_get_stone_color(stack_index),
			stack_index,
			_get_stack_position(stack_index)
		)


func _on_stone_settled(_piece: StonePieceType) -> void:
	if not _scatter_active:
		return
	_settled_piece_count += 1
	if _settled_piece_count == STONE_COUNT:
		_scatter_active = false
		set_physics_process(false)
		tower_scatter_finished.emit()


func _get_stone_size(stack_index: int) -> Vector2:
	return Vector2(
		BOTTOM_WIDTH - WIDTH_STEP * stack_index,
		BOTTOM_HEIGHT - HEIGHT_STEP * stack_index
	)


func _get_stack_position(stack_index: int) -> Vector2:
	var middle_index: float = float(STONE_COUNT - 1) * 0.5
	return Vector2(0.0, (middle_index - stack_index) * STACK_SPACING)


func _get_stone_color(stack_index: int) -> Color:
	match stack_index:
		0:
			return Color(0.43, 0.29, 0.18, 1.0)
		1:
			return Color(0.52, 0.35, 0.20, 1.0)
		2:
			return Color(0.58, 0.39, 0.23, 1.0)
		3:
			return Color(0.49, 0.32, 0.24, 1.0)
		4:
			return Color(0.62, 0.44, 0.28, 1.0)
		5:
			return Color(0.55, 0.38, 0.29, 1.0)
		_:
			return Color(0.68, 0.50, 0.33, 1.0)
