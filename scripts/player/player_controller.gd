class_name GullyPlayerController
extends CharacterBody2D


const NO_TOUCH: int = -1
const PLAYER_RADIUS: float = 28.0

@export_range(1.0, 200.0, 1.0) var joystick_radius: float = 90.0
@export_range(1.0, 600.0, 1.0) var maximum_speed: float = 300.0
@export_range(1.0, 3000.0, 1.0) var acceleration: float = 1200.0
@export_range(1.0, 3000.0, 1.0) var deceleration: float = 900.0
@export_range(0.0, 0.5, 0.01) var speed_reduction_per_stone: float = 0.05
@export_range(0.1, 1.0, 0.01) var minimum_speed_multiplier: float = 0.5

@onready var _joystick_visual: GullyJoystickVisual = $JoystickLayer/JoystickVisual
@onready var _player_visual: GullyPlayerVisual = $PlayerVisual

var _active_touch_index: int = NO_TOUCH
var _mouse_drag_active: bool = false
var _joystick_origin: Vector2 = Vector2.ZERO
var _joystick_input: Vector2 = Vector2.ZERO
var _viewport_size: Vector2 = Vector2.ZERO
var _movement_enabled: bool = true
var _carried_stone_count: int = 0


func _ready() -> void:
	_update_viewport_size()
	get_viewport().size_changed.connect(_update_viewport_size)


func set_movement_enabled(enabled: bool) -> void:
	_movement_enabled = enabled
	if not enabled:
		_active_touch_index = NO_TOUCH
		_mouse_drag_active = false
		_joystick_input = Vector2.ZERO
		_joystick_visual.hide_joystick()
		velocity = Vector2.ZERO


func reset_to_start(start_position: Vector2) -> void:
	set_movement_enabled(false)
	global_position = start_position
	velocity = Vector2.ZERO


func set_carried_stone_count(count: int) -> void:
	_carried_stone_count = maxi(count, 0)


func apply_theme(arena_theme: ArenaTheme) -> void:
	_player_visual.apply_theme(arena_theme)


func play_pulse() -> void:
	_player_visual.pulse()


func reset_visual_feedback() -> void:
	_player_visual.reset_pulse()


func _get_effective_maximum_speed() -> float:
	var multiplier: float = maxf(
		minimum_speed_multiplier,
		pow(1.0 - speed_reduction_per_stone, float(_carried_stone_count))
	)
	return maximum_speed * multiplier


func _input(event: InputEvent) -> void:
	if not _movement_enabled:
		return
	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		_handle_screen_touch(touch_event)
	elif event is InputEventScreenDrag:
		var drag_event: InputEventScreenDrag = event as InputEventScreenDrag
		_handle_screen_drag(drag_event)
	elif event is InputEventMouseButton:
		var button_event: InputEventMouseButton = event as InputEventMouseButton
		_handle_mouse_button(button_event)
	elif event is InputEventMouseMotion:
		var motion_event: InputEventMouseMotion = event as InputEventMouseMotion
		_handle_mouse_motion(motion_event)


func _physics_process(delta: float) -> void:
	if not _movement_enabled:
		return

	var input_direction: Vector2 = _joystick_input if _pointer_is_active() else _get_keyboard_input()
	var target_velocity: Vector2 = input_direction * _get_effective_maximum_speed()
	var change_rate: float = acceleration if target_velocity.length_squared() > 0.0 else deceleration

	velocity = velocity.move_toward(target_velocity, change_rate * delta)
	move_and_slide()
	_keep_inside_gameplay_area()
	if velocity.length_squared() > 100.0:
		_player_visual.set_facing_direction(velocity)


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _active_touch_index == NO_TOUCH and not _mouse_drag_active:
			_active_touch_index = event.index
			_begin_joystick(event.position)
	elif event.index == _active_touch_index:
		_active_touch_index = NO_TOUCH
		_release_joystick()


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index == _active_touch_index:
		_update_joystick(event.position)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		if _active_touch_index == NO_TOUCH and not _mouse_drag_active:
			_mouse_drag_active = true
			_begin_joystick(event.position)
	elif _mouse_drag_active:
		_mouse_drag_active = false
		_release_joystick()


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _mouse_drag_active:
		_update_joystick(event.position)


func _begin_joystick(origin: Vector2) -> void:
	_joystick_origin = origin
	_joystick_input = Vector2.ZERO
	_joystick_visual.show_joystick(_joystick_origin)


func _update_joystick(pointer_position: Vector2) -> void:
	var displacement: Vector2 = pointer_position - _joystick_origin
	var distance: float = displacement.length()

	if distance > 0.0:
		var strength: float = minf(distance / joystick_radius, 1.0)
		_joystick_input = displacement / distance * strength
	else:
		_joystick_input = Vector2.ZERO

	_joystick_visual.update_joystick(_joystick_input, joystick_radius)


func _release_joystick() -> void:
	_joystick_input = Vector2.ZERO
	_joystick_visual.hide_joystick()


func _pointer_is_active() -> bool:
	return _active_touch_index != NO_TOUCH or _mouse_drag_active


func _get_keyboard_input() -> Vector2:
	var horizontal: float = 0.0
	var vertical: float = 0.0

	if Input.is_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A):
		horizontal -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D):
		horizontal += 1.0
	if Input.is_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W):
		vertical -= 1.0
	if Input.is_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S):
		vertical += 1.0

	var input_direction: Vector2 = Vector2(horizontal, vertical)
	if input_direction.length_squared() > 1.0:
		input_direction = input_direction.normalized()
	return input_direction


func _keep_inside_gameplay_area() -> void:
	var maximum_x: float = _viewport_size.x - PLAYER_RADIUS
	var maximum_y: float = _viewport_size.y - PLAYER_RADIUS

	position.x = clampf(position.x, PLAYER_RADIUS, maximum_x)
	position.y = clampf(position.y, PLAYER_RADIUS, maximum_y)

	if position.x <= PLAYER_RADIUS and velocity.x < 0.0:
		velocity.x = 0.0
	elif position.x >= maximum_x and velocity.x > 0.0:
		velocity.x = 0.0

	if position.y <= PLAYER_RADIUS and velocity.y < 0.0:
		velocity.y = 0.0
	elif position.y >= maximum_y and velocity.y > 0.0:
		velocity.y = 0.0


func _update_viewport_size() -> void:
	_viewport_size = get_viewport_rect().size
