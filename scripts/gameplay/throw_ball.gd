class_name ThrowBall
extends CharacterBody2D


signal aim_started
signal aim_cancelled
signal thrown(direction: Vector2, power: float)
signal hit(impact_direction: Vector2, impact_speed: float, impact_position: Vector2)
signal stopped(was_hit: bool)

const NO_TOUCH: int = -1
const BALL_RADIUS: float = 14.0
const TOUCH_GRAB_RADIUS: float = 46.0
const MIN_DRAG_DISTANCE: float = 18.0
const MAX_DRAG_DISTANCE: float = 220.0
const MIN_THROW_SPEED: float = 260.0
const MAX_THROW_SPEED: float = 900.0

@onready var _aim_visual: GullyAimVisual = $AimLayer/AimVisual
@onready var _ball_visual: GullyBallVisual = $BallVisual

var aiming_enabled: bool = true
var is_traveling: bool = false

var _stone_tower: StoneTower = null
var _active_touch_index: int = NO_TOUCH
var _mouse_drag_active: bool = false
var _is_aiming: bool = false
var _viewport_bounds: Rect2 = Rect2()


func _ready() -> void:
	_update_viewport_bounds()
	get_viewport().size_changed.connect(_update_viewport_bounds)
	set_physics_process(false)


func configure(stone_tower: StoneTower) -> void:
	_stone_tower = stone_tower


func apply_theme(arena_theme: ArenaTheme) -> void:
	_ball_visual.apply_theme(arena_theme)


func reset_to_start(start_position: Vector2) -> void:
	set_physics_process(false)
	_active_touch_index = NO_TOUCH
	_mouse_drag_active = false
	_is_aiming = false
	is_traveling = false
	velocity = Vector2.ZERO
	global_position = start_position
	visible = true
	collision_layer = 1
	collision_mask = 1
	_aim_visual.clear_aim()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event as InputEventScreenDrag)
	elif event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)


func _physics_process(delta: float) -> void:
	if not is_traveling:
		return

	global_position += velocity * delta
	_check_travel_result()


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _active_touch_index == NO_TOUCH and not _mouse_drag_active and _can_begin_aim(event.position):
			_active_touch_index = event.index
			_begin_aim(event.position)
	elif event.index == _active_touch_index:
		_active_touch_index = NO_TOUCH
		_end_aim(event.position)


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index == _active_touch_index:
		_update_aim(event.position)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		if _active_touch_index == NO_TOUCH and not _mouse_drag_active and _can_begin_aim(event.position):
			_mouse_drag_active = true
			_begin_aim(event.position)
	elif _mouse_drag_active:
		_mouse_drag_active = false
		_end_aim(event.position)


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _mouse_drag_active:
		_update_aim(event.position)


func _can_begin_aim(pointer_position: Vector2) -> bool:
	if not aiming_enabled or is_traveling or _is_aiming:
		return false
	return global_position.distance_to(pointer_position) <= TOUCH_GRAB_RADIUS


func _begin_aim(pointer_position: Vector2) -> void:
	_is_aiming = true
	_aim_visual.show_aim(global_position)
	_aim_visual.update_aim(global_position, pointer_position)
	aim_started.emit()


func _update_aim(pointer_position: Vector2) -> void:
	if not _is_aiming:
		return
	_aim_visual.update_aim(global_position, pointer_position)


func _end_aim(pointer_position: Vector2) -> void:
	if not _is_aiming:
		return

	_is_aiming = false
	_aim_visual.clear_aim()

	var displacement: Vector2 = pointer_position - global_position
	var distance: float = displacement.length()

	if distance < MIN_DRAG_DISTANCE:
		aim_cancelled.emit()
		return

	var clamped_distance: float = clampf(distance, MIN_DRAG_DISTANCE, MAX_DRAG_DISTANCE)
	var strength: float = (clamped_distance - MIN_DRAG_DISTANCE) / (MAX_DRAG_DISTANCE - MIN_DRAG_DISTANCE)
	var speed: float = lerpf(MIN_THROW_SPEED, MAX_THROW_SPEED, strength)
	var direction: Vector2 = displacement / distance

	velocity = direction * speed
	is_traveling = true
	set_physics_process(true)
	thrown.emit(direction, speed)


func _check_travel_result() -> void:
	if _stone_tower != null:
		var distance_to_tower: float = global_position.distance_to(_stone_tower.global_position)
		if distance_to_tower <= _stone_tower.get_footprint_radius() + BALL_RADIUS:
			_stop_travel(true)
			return

	if not _viewport_bounds.grow(BALL_RADIUS).has_point(global_position):
		_stop_travel(false)


func _stop_travel(was_hit: bool) -> void:
	var impact_velocity: Vector2 = velocity
	velocity = Vector2.ZERO
	is_traveling = false
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	visible = false
	if was_hit:
		hit.emit(impact_velocity.normalized(), impact_velocity.length(), global_position)
	stopped.emit(was_hit)


func _update_viewport_bounds() -> void:
	_viewport_bounds = get_viewport_rect()
