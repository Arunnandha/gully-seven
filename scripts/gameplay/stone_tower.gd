class_name StoneTower
extends Node2D


signal tower_scatter_started(impact_position: Vector2)
signal tower_scatter_finished
signal deposited_count_changed(count: int)

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
const FINAL_SEPARATION_PADDING: float = 6.0
const FINAL_SEPARATION_PASSES: int = 8

# One fan offset per stack index (0 = bottom/heaviest .. 6 = top/lightest),
# broad enough to cover forward, sideways, and one backward-leaning stone.
const FAN_ANGLE_BY_INDEX: Array[float] = [
	0.05, -0.35, 0.40, -0.80, 0.85, -1.35, 2.05,
]

@export var stone_piece_scene: PackedScene
@export var scatter_seed: int = 73471

var _pieces: Array[StonePieceType] = []
var _deposited_pieces: Array[StonePieceType] = []
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
	_deposited_pieces.clear()
	set_physics_process(false)
	for piece: StonePieceType in _pieces:
		piece.reset_to_stack()
	deposited_count_changed.emit(0)


func deposit_stone(piece: StonePieceType) -> void:
	if _deposited_pieces.has(piece):
		return
	_deposited_pieces.append(piece)
	piece.deposit_to_stack()
	# Larger stones (lower original stack_index) always sit lower, so the
	# rebuilt stack looks correct regardless of collection/deposit order.
	_deposited_pieces.sort_custom(_compare_by_stack_index)
	for slot_index: int in range(_deposited_pieces.size()):
		_deposited_pieces[slot_index].position = _get_stack_position(slot_index)
	deposited_count_changed.emit(_deposited_pieces.size())


func get_deposited_count() -> int:
	return _deposited_pieces.size()


static func _compare_by_stack_index(first: StonePiece, second: StonePiece) -> bool:
	return first.stack_index < second.stack_index


func get_footprint_radius() -> float:
	return BOTTOM_WIDTH * 0.5 + 12.0


func get_pieces() -> Array[StonePieceType]:
	return _pieces


func set_collection_enabled(enabled: bool) -> void:
	for piece: StonePieceType in _pieces:
		piece.set_collection_enabled(enabled)


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

	_scatter_rng.seed = scatter_seed
	_settled_piece_count = 0
	_scatter_active = true
	tower_scatter_started.emit(impact_position)

	for piece: StonePieceType in _pieces:
		var index_t: float = float(piece.stack_index) / float(STONE_COUNT - 1)
		var jitter: float = _scatter_rng.randf_range(-angle_jitter_limit, angle_jitter_limit)
		var direction: Vector2 = normalized_impact.rotated(
			FAN_ANGLE_BY_INDEX[piece.stack_index] + jitter
		)
		var target_distance: float = lerpf(MIN_INDEX_DISTANCE, MAX_INDEX_DISTANCE, index_t)
		target_distance *= distance_scale

		if piece.stack_index == STONE_COUNT - 1 and _scatter_rng.randf() < OUTLIER_CHANCE:
			target_distance += lerpf(OUTLIER_BONUS_MIN, OUTLIER_BONUS_MAX, strength_t)

		target_distance = clampf(target_distance, MINIMUM_DISTANCE, HARD_DISTANCE_CEILING)
		var max_allowed_distance: float = _get_max_allowed_distance(direction, piece)
		target_distance = minf(target_distance, max_allowed_distance)
		var initial_speed: float = sqrt(
			2.0 * StonePiece.SCATTER_FRICTION * target_distance
			+ StonePiece.SETTLE_SPEED * StonePiece.SETTLE_SPEED
		)
		var spin_direction: float = -1.0 if piece.stack_index % 2 == 0 else 1.0
		var angular_velocity: float = spin_direction * (
			2.0 + float(piece.stack_index) * 0.25
		) + _scatter_rng.randf_range(-0.3, 0.3)
		piece.start_scatter(direction * initial_speed, angular_velocity)


func _get_max_allowed_distance(direction: Vector2, piece: StonePieceType) -> float:
	var viewport_rect: Rect2 = get_viewport_rect()
	var start_position: Vector2 = piece.global_position
	var safety_extent: float = piece.stone_size.x * 0.5 + EDGE_SAFETY_MARGIN
	var maximum_distance: float = HARD_DISTANCE_CEILING

	if direction.x > 0.0001:
		maximum_distance = minf(
			maximum_distance,
			(viewport_rect.end.x - start_position.x - safety_extent) / direction.x
		)
	elif direction.x < -0.0001:
		maximum_distance = minf(
			maximum_distance,
			(start_position.x - viewport_rect.position.x - safety_extent) / -direction.x
		)

	if direction.y > 0.0001:
		maximum_distance = minf(
			maximum_distance,
			(viewport_rect.end.y - start_position.y - safety_extent) / direction.y
		)
	elif direction.y < -0.0001:
		maximum_distance = minf(
			maximum_distance,
			(start_position.y - viewport_rect.position.y - safety_extent) / -direction.y
		)

	return maxf(MINIMUM_DISTANCE, maximum_distance)


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
		_resolve_final_overlaps()
		tower_scatter_finished.emit()


func _resolve_final_overlaps() -> void:
	for _pass_index: int in range(FINAL_SEPARATION_PASSES):
		var overlap_found: bool = false
		for first_index: int in range(_pieces.size()):
			for second_index: int in range(first_index + 1, _pieces.size()):
				overlap_found = _separate_settled_pair(
					_pieces[first_index],
					_pieces[second_index]
				) or overlap_found
		if not overlap_found:
			return


func _separate_settled_pair(first: StonePieceType, second: StonePieceType) -> bool:
	var offset: Vector2 = second.global_position - first.global_position
	var distance: float = offset.length()
	var direction: Vector2 = offset / distance if distance > 0.0001 else _get_fallback_separation_direction(
		first.stack_index,
		second.stack_index
	)
	var first_extent: float = first.get_separation_extent(direction)
	var second_extent: float = second.get_separation_extent(-direction)
	var required_distance: float = first_extent + second_extent + FINAL_SEPARATION_PADDING
	if distance >= required_distance:
		return false

	var overlap: float = required_distance - distance
	var combined_extent: float = first_extent + second_extent
	var first_share: float = second_extent / combined_extent
	var second_share: float = first_extent / combined_extent
	first.apply_settle_separation(-direction * overlap * first_share)
	second.apply_settle_separation(direction * overlap * second_share)
	return true


func _get_fallback_separation_direction(first_index: int, second_index: int) -> Vector2:
	var deterministic_angle: float = float(first_index * 53 + second_index * 97) * 0.017
	return Vector2.RIGHT.rotated(deterministic_angle)


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
