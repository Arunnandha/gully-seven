class_name GullyDefender
extends CharacterBody2D


signal player_tagged

const DEFENDER_RADIUS: float = 26.0
const ARRIVE_RADIUS: float = 70.0
const ZONE_STANDOFF_MARGIN: float = 80.0
const GRACE_ALPHA: float = 0.45
# Normalized viewport spots considered when (re)spawning; the one farthest
# from both the player and the safe circle wins.
const SPAWN_CANDIDATES: Array[Vector2] = [
	Vector2(0.08, 0.10), Vector2(0.50, 0.08), Vector2(0.92, 0.10),
	Vector2(0.08, 0.50), Vector2(0.92, 0.50),
	Vector2(0.08, 0.90), Vector2(0.50, 0.92), Vector2(0.92, 0.90),
]

@export_range(50.0, 600.0, 1.0) var chase_speed: float = 265.0
@export_range(100.0, 3000.0, 1.0) var chase_acceleration: float = 900.0
@export_range(10.0, 120.0, 1.0) var tag_distance: float = 48.0
@export_range(0.0, 5.0, 0.1) var grace_duration: float = 1.5

var _player: GullyPlayerController = null
var _rebuild_zone: RebuildZone = null
var _chase_active: bool = false
var _grace_remaining: float = 0.0
var _viewport_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	visible = false
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	_update_viewport_size()
	get_viewport().size_changed.connect(_update_viewport_size)


func setup(player: GullyPlayerController, rebuild_zone: RebuildZone) -> void:
	_player = player
	_rebuild_zone = rebuild_zone


func set_chase_enabled(enabled: bool) -> void:
	if _chase_active == enabled:
		return
	_chase_active = enabled
	visible = enabled
	set_physics_process(enabled)
	if enabled:
		reset_to_spawn()
		start_grace()


func reset_to_spawn() -> void:
	global_position = _pick_spawn_position()
	velocity = Vector2.ZERO


func start_grace() -> void:
	if not _chase_active:
		return
	_grace_remaining = grace_duration
	_apply_grace_visual()


func _physics_process(delta: float) -> void:
	if _grace_remaining > 0.0:
		_grace_remaining = maxf(_grace_remaining - delta, 0.0)
		if _grace_remaining <= 0.0:
			_apply_grace_visual()

	var player_safe: bool = _rebuild_zone.is_player_inside()
	var target: Vector2 = _player.global_position
	if player_safe:
		# Hold a standoff ring outside the chalk circle instead of camping it.
		var away: Vector2 = global_position - _rebuild_zone.global_position
		var away_direction: Vector2 = (
			away.normalized() if away.length_squared() > 0.0001 else Vector2.RIGHT
		)
		target = _rebuild_zone.global_position + away_direction * (
			RebuildZone.RADIUS + ZONE_STANDOFF_MARGIN
		)

	var offset: Vector2 = target - global_position
	var distance: float = offset.length()
	var desired_velocity: Vector2 = Vector2.ZERO
	if distance > 0.5:
		# Arrival scaling kills the overshoot oscillation near the target.
		var speed_scale: float = minf(distance / ARRIVE_RADIUS, 1.0)
		desired_velocity = offset / distance * chase_speed * speed_scale

	velocity = velocity.move_toward(desired_velocity, chase_acceleration * delta)
	global_position += velocity * delta
	_keep_inside_viewport()

	if (
		not player_safe
		and _grace_remaining <= 0.0
		and global_position.distance_to(_player.global_position) <= tag_distance
	):
		player_tagged.emit()


func _pick_spawn_position() -> Vector2:
	var best_position: Vector2 = _viewport_size * 0.1
	var best_score: float = -1.0
	for candidate: Vector2 in SPAWN_CANDIDATES:
		var candidate_position: Vector2 = candidate * _viewport_size
		var score: float = minf(
			candidate_position.distance_to(_player.global_position),
			candidate_position.distance_to(_rebuild_zone.global_position)
		)
		if score > best_score:
			best_score = score
			best_position = candidate_position
	return best_position


func _apply_grace_visual() -> void:
	modulate.a = GRACE_ALPHA if _grace_remaining > 0.0 else 1.0


func _keep_inside_viewport() -> void:
	global_position.x = clampf(
		global_position.x, DEFENDER_RADIUS, _viewport_size.x - DEFENDER_RADIUS
	)
	global_position.y = clampf(
		global_position.y, DEFENDER_RADIUS, _viewport_size.y - DEFENDER_RADIUS
	)


func _update_viewport_size() -> void:
	_viewport_size = get_viewport_rect().size
