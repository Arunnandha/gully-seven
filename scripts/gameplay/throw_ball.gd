class_name ThrowBall
extends CharacterBody2D


signal aim_started
signal aim_cancelled
signal thrown(direction: Vector2, power: float)
signal hit(impact_direction: Vector2, impact_speed: float, impact_position: Vector2)
signal stopped(was_hit: bool)

enum PowerBand {
	WEAK,
	MEDIUM,
	STRONG,
}

enum ThrowGrade {
	WEAK,
	MEDIUM,
	STRONG,
	PERFECT,
}

const NO_TOUCH: int = -1
const BALL_RADIUS: float = 14.0
const TOUCH_GRAB_RADIUS: float = 46.0
const MIN_DRAG_DISTANCE: float = 18.0
const MAX_DRAG_DISTANCE: float = 220.0
const MIN_THROW_SPEED: float = 260.0
const MAX_THROW_SPEED: float = 900.0

# Configurable power bands, shared by the aim indicator, the scatter model
# and the impact feedback so every system agrees on weak/medium/strong.
const WEAK_STRENGTH_THRESHOLD: float = 0.33
const STRONG_STRENGTH_THRESHOLD: float = 0.66

# A Perfect throw grade requires strong-band power AND a near-central hit.
const PERFECT_ACCURACY_THRESHOLD: float = 0.85


# 0..1 strength from the ball's actual speed at tower contact (flight speed
# is constant, so this equals the release strength by construction).
static func get_normalized_strength(impact_speed: float) -> float:
	return clampf(
		(impact_speed - MIN_THROW_SPEED) / (MAX_THROW_SPEED - MIN_THROW_SPEED), 0.0, 1.0
	)


static func get_power_band(strength: float) -> PowerBand:
	if strength < WEAK_STRENGTH_THRESHOLD:
		return PowerBand.WEAK
	if strength < STRONG_STRENGTH_THRESHOLD:
		return PowerBand.MEDIUM
	return PowerBand.STRONG


# 0..1 position within the band the strength falls into.
static func get_band_progress(strength: float) -> float:
	if strength < WEAK_STRENGTH_THRESHOLD:
		return strength / WEAK_STRENGTH_THRESHOLD
	if strength < STRONG_STRENGTH_THRESHOLD:
		return (
			(strength - WEAK_STRENGTH_THRESHOLD)
			/ (STRONG_STRENGTH_THRESHOLD - WEAK_STRENGTH_THRESHOLD)
		)
	return (strength - STRONG_STRENGTH_THRESHOLD) / (1.0 - STRONG_STRENGTH_THRESHOLD)


# 0..1: 1.0 means the ball's path ran straight through target_position (a
# dead-central hit); lower values mean a glancing hit. Shared by the scatter
# model (energy transfer / sideways bias) and by throw grading, so both
# agree on exactly what "accurate" means for the same impact.
static func get_impact_alignment(
	impact_direction: Vector2, impact_position: Vector2, target_position: Vector2
) -> float:
	var to_target: Vector2 = target_position - impact_position
	if to_target.length_squared() <= 1.0:
		return 1.0
	return clampf(to_target.normalized().dot(impact_direction.normalized()), 0.0, 1.0)


# A Perfect grade is a strong-band hit that is also near-central; every
# other band maps straight to its same-named grade.
static func get_throw_grade(strength: float, accuracy: float) -> ThrowGrade:
	var band: PowerBand = get_power_band(strength)
	if band == PowerBand.STRONG and accuracy >= PERFECT_ACCURACY_THRESHOLD:
		return ThrowGrade.PERFECT
	match band:
		PowerBand.WEAK:
			return ThrowGrade.WEAK
		PowerBand.STRONG:
			return ThrowGrade.STRONG
		_:
			return ThrowGrade.MEDIUM


static func get_grade_name(grade: ThrowGrade) -> String:
	match grade:
		ThrowGrade.WEAK:
			return "WEAK"
		ThrowGrade.STRONG:
			return "STRONG"
		ThrowGrade.PERFECT:
			return "PERFECT"
		_:
			return "MEDIUM"

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
	_send_aim_to_visual(pointer_position)
	aim_started.emit()


func _update_aim(pointer_position: Vector2) -> void:
	if not _is_aiming:
		return
	_send_aim_to_visual(pointer_position)


# Mirrors the release formula exactly so the indicator always shows the
# strength the throw would actually get, with the drag clamped for display.
func _send_aim_to_visual(pointer_position: Vector2) -> void:
	var displacement: Vector2 = pointer_position - global_position
	var distance: float = displacement.length()
	var clamped_distance: float = minf(distance, MAX_DRAG_DISTANCE)
	var strength: float = 0.0
	if distance >= MIN_DRAG_DISTANCE:
		strength = (
			(clamped_distance - MIN_DRAG_DISTANCE)
			/ (MAX_DRAG_DISTANCE - MIN_DRAG_DISTANCE)
		)
	_aim_visual.update_aim(global_position, pointer_position, strength, clamped_distance)


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
