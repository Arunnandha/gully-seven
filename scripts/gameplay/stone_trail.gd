class_name StoneTrail
extends Node


signal stone_count_changed(count: int)
signal all_stones_collected

# Player path samples are kept SAMPLE_SPACING apart along the travelled route,
# so arc-length lookups are O(1) index math instead of per-frame walks.
const SAMPLE_SPACING: float = 4.0
# 192 samples * 4 px = 768 px of recorded route; the full trail needs at most
# 7 * MAX_CENTER_SPACING = 490 px, so the buffer never runs short.
const HISTORY_CAPACITY: int = 192
const MIN_CENTER_SPACING: float = 50.0
const MAX_CENTER_SPACING: float = 70.0
const LINK_GAP: float = 4.0
const PICKUP_BLEND_DURATION: float = 0.3
const FALLBACK_DIRECTION: Vector2 = Vector2(0.0, 1.0)

var _player_controller: GullyPlayerController = null
var _stone_tower: StoneTower = null
var _round_controller: RoundController = null
var _carried_stones: Array[StonePiece] = []

# Fixed-size ring buffer of past player positions; no per-frame allocation.
var _history: PackedVector2Array = PackedVector2Array()
var _history_head: int = 0
var _history_count: int = 0

# Per-trail-slot data, preallocated for all seven stones.
var _arc_distances: PackedFloat32Array = PackedFloat32Array()
var _blend_remaining: PackedFloat32Array = PackedFloat32Array()
var _blend_start_positions: PackedVector2Array = PackedVector2Array()
var _blend_start_rotations: PackedFloat32Array = PackedFloat32Array()
var _active_blend_count: int = 0
var _last_player_position: Vector2 = Vector2.INF


func _ready() -> void:
	_history.resize(HISTORY_CAPACITY)
	_arc_distances.resize(StoneTower.STONE_COUNT)
	_blend_remaining.resize(StoneTower.STONE_COUNT)
	_blend_start_positions.resize(StoneTower.STONE_COUNT)
	_blend_start_rotations.resize(StoneTower.STONE_COUNT)
	set_physics_process(false)


func setup(
	player_controller: GullyPlayerController,
	stone_tower: StoneTower,
	round_controller: RoundController
) -> void:
	_player_controller = player_controller
	_stone_tower = stone_tower
	_round_controller = round_controller

	for piece: StonePiece in _stone_tower.get_pieces():
		piece.stone_collected.connect(_on_piece_collected)

	_round_controller.state_changed.connect(_on_round_state_changed)


func reset() -> void:
	_carried_stones.clear()
	_active_blend_count = 0
	_last_player_position = Vector2.INF
	set_physics_process(false)
	_player_controller.set_carried_stone_count(0)
	stone_count_changed.emit(0)


func _physics_process(delta: float) -> void:
	var player_position: Vector2 = _player_controller.global_position

	# Once the player stops and every pickup blend has finished, all targets
	# are frozen, so the whole update can be skipped and the chain stays put.
	if player_position == _last_player_position and _active_blend_count == 0:
		return
	_last_player_position = player_position

	_record_path(player_position)
	_update_trail(delta, player_position)


func _record_path(player_position: Vector2) -> void:
	var newest: Vector2 = _sample_back(0)
	var segment: Vector2 = player_position - newest
	var distance: float = segment.length()

	while distance >= SAMPLE_SPACING:
		newest += segment / distance * SAMPLE_SPACING
		_push_sample(newest)
		segment = player_position - newest
		distance = segment.length()


func _update_trail(delta: float, player_position: Vector2) -> void:
	var leader_position: Vector2 = player_position

	for slot_index: int in range(_carried_stones.size()):
		var stone: StonePiece = _carried_stones[slot_index]
		var target: Vector2 = _get_path_position(_arc_distances[slot_index], player_position)
		var toward_leader: Vector2 = leader_position - target
		var target_rotation: float = stone.rotation
		if toward_leader.length_squared() > 0.0001:
			target_rotation = toward_leader.angle()

		if _blend_remaining[slot_index] > 0.0:
			_blend_remaining[slot_index] = maxf(_blend_remaining[slot_index] - delta, 0.0)
			if _blend_remaining[slot_index] <= 0.0:
				_active_blend_count = maxi(_active_blend_count - 1, 0)
			var blend_t: float = 1.0 - _blend_remaining[slot_index] / PICKUP_BLEND_DURATION
			blend_t = blend_t * blend_t * (3.0 - 2.0 * blend_t)
			stone.global_position = _blend_start_positions[slot_index].lerp(target, blend_t)
			stone.rotation = lerp_angle(_blend_start_rotations[slot_index], target_rotation, blend_t)
		else:
			stone.global_position = target
			stone.rotation = target_rotation

		leader_position = stone.global_position


func _reset_history() -> void:
	_history_head = 0
	_history_count = 1
	_history[0] = _player_controller.global_position
	_last_player_position = Vector2.INF


func _push_sample(sample: Vector2) -> void:
	_history_head = (_history_head + 1) % HISTORY_CAPACITY
	_history[_history_head] = sample
	_history_count = mini(_history_count + 1, HISTORY_CAPACITY)


func _sample_back(steps_back: int) -> Vector2:
	var clamped_steps: int = mini(steps_back, _history_count - 1)
	var ring_index: int = _history_head - clamped_steps
	if ring_index < 0:
		ring_index += HISTORY_CAPACITY
	return _history[ring_index]


func _get_path_position(arc_distance: float, player_position: Vector2) -> Vector2:
	var newest: Vector2 = _sample_back(0)
	var partial: float = player_position.distance_to(newest)

	if arc_distance <= partial:
		if partial <= 0.0001:
			return newest
		return player_position.lerp(newest, arc_distance / partial)

	var remaining: float = arc_distance - partial
	var segment_index: int = int(remaining / SAMPLE_SPACING)
	var segment_fraction: float = (
		remaining - float(segment_index) * SAMPLE_SPACING
	) / SAMPLE_SPACING

	if segment_index + 1 <= _history_count - 1:
		return _sample_back(segment_index).lerp(_sample_back(segment_index + 1), segment_fraction)

	# The requested arc distance is older than the recorded route (early in
	# RAID); extend past the oldest sample along the route's oldest direction.
	var oldest: Vector2 = _sample_back(_history_count - 1)
	var direction: Vector2 = FALLBACK_DIRECTION
	if _history_count >= 2:
		var oldest_segment: Vector2 = oldest - _sample_back(_history_count - 2)
		if oldest_segment.length_squared() > 0.000001:
			direction = oldest_segment.normalized()
	elif partial > 0.0001:
		direction = (newest - player_position) / partial
	var overflow: float = remaining - float(_history_count - 1) * SAMPLE_SPACING
	return oldest + direction * overflow


func _on_piece_collected(piece: StonePiece) -> void:
	if _carried_stones.has(piece):
		return

	_carried_stones.append(piece)
	var slot_index: int = _carried_stones.size() - 1
	var radius: float = piece.get_separation_radius()
	var spacing: float
	if slot_index == 0:
		spacing = clampf(
			GullyPlayerController.PLAYER_RADIUS + radius + LINK_GAP,
			MIN_CENTER_SPACING,
			MAX_CENTER_SPACING
		)
		_arc_distances[0] = spacing
	else:
		var previous_radius: float = _carried_stones[slot_index - 1].get_separation_radius()
		spacing = clampf(
			previous_radius + radius + LINK_GAP,
			MIN_CENTER_SPACING,
			MAX_CENTER_SPACING
		)
		_arc_distances[slot_index] = _arc_distances[slot_index - 1] + spacing

	_blend_start_positions[slot_index] = piece.global_position
	_blend_start_rotations[slot_index] = piece.rotation
	_blend_remaining[slot_index] = PICKUP_BLEND_DURATION
	_active_blend_count += 1

	_player_controller.set_carried_stone_count(_carried_stones.size())
	stone_count_changed.emit(_carried_stones.size())

	if _carried_stones.size() >= StoneTower.STONE_COUNT:
		all_stones_collected.emit()


func _on_round_state_changed(new_state: RoundController.State) -> void:
	_stone_tower.set_collection_enabled(new_state == RoundController.State.RAID)
	match new_state:
		RoundController.State.RAID:
			_reset_history()
			set_physics_process(true)
		RoundController.State.RETURN:
			set_physics_process(true)
		_:
			set_physics_process(false)
