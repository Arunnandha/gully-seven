class_name GullyCharacterVisual
extends Node2D


# Shared procedural "village boy" rig for the player and defender.
#
# Presentation only: gameplay controllers feed velocity via update_motion()
# and trigger short reactions; this node owns facing buckets, run phase,
# idle blending and pose drawing. The rig draws with FEET AT THE LOCAL
# ORIGIN, so the gameplay position (and collision shape) is the character's
# ground contact point. Nothing here reads or mutates gameplay state, which
# keeps a later swap to AnimatedSprite2D sprite sheets a drop-in change.
#
# Redraw policy: _process is enabled only while moving, blending to idle or
# playing a reaction, and queue_redraw fires only when the quantized draw
# signature (facing bucket / run frame / blend step / reaction step / grace)
# actually changes — roughly 20 redraws per second while running, zero while
# standing still.

enum HairStyle {
	FLAT,
	SPIKY,
}

enum Reaction {
	NONE,
	BOUNCE,
	REACH,
	RECOIL,
	TIRED,
	CELEBRATE,
}

const RUN_FRAMES: int = 12
const REACTION_STEPS: int = 10
const INTENSITY_BLEND_RATE: float = 6.0
const PHASE_PER_PIXEL: float = 0.045
const MOVE_SPEED_THRESHOLD: float = 12.0
const FACING_SPEED_SQUARED: float = 100.0
const FACING_BUCKET_COUNT: int = 8

const REACTION_DURATIONS: Array[float] = [0.0, 0.28, 0.32, 0.36, 0.55, 0.9]

const SKIN_COLOR: Color = Color(0.62, 0.42, 0.28, 1.0)
const SKIN_SHADE_COLOR: Color = Color(0.48, 0.31, 0.20, 1.0)
const HAIR_COLOR: Color = Color(0.10, 0.08, 0.07, 1.0)
const SHORTS_COLOR: Color = Color(0.16, 0.14, 0.18, 1.0)

@onready var _shadow: GullyCharacterShadow = $Shadow

# Subclass configuration (set in _init before _ready).
var hair_style: HairStyle = HairStyle.FLAT
var has_headband: bool = false
var body_scale_factor: float = 1.0

# Palette fed from ArenaTheme by the subclass apply_theme.
var _shirt_color: Color = Color(0.12, 0.78, 0.72, 1.0)
var _shirt_shade_color: Color = Color(0.08, 0.58, 0.54, 1.0)
var _outline_color: Color = Color(0.03, 0.20, 0.19, 1.0)
var _grace_outline_color: Color = Color(0.95, 0.92, 0.85, 0.9)
var _accent_color: Color = Color(0.98, 0.92, 0.80, 1.0)

# Motion state.
var _velocity: Vector2 = Vector2.ZERO
var _facing: Vector2 = Vector2.DOWN
var _facing_bucket: int = 2
var _run_phase: float = 0.0
var _intensity: float = 0.0
var _grace_active: bool = false

# Reaction state.
var _reaction: Reaction = Reaction.NONE
var _reaction_time: float = 0.0

# Captured at the moment a redraw is queued so _draw stays deterministic.
var _draw_swing: float = 0.0
var _draw_bob: float = 0.0
var _draw_reaction_t: float = 0.0
var _draw_signature: int = -1

var _poly_scratch: PackedVector2Array = PackedVector2Array()


func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	set_process_input(false)


# Called by the gameplay controller once per physics tick while it is
# simulating; the rig derives everything else from this velocity.
func update_motion(velocity: Vector2) -> void:
	_velocity = velocity
	if velocity.length_squared() > FACING_SPEED_SQUARED:
		_update_facing_bucket(velocity)
	if velocity.length_squared() > MOVE_SPEED_THRESHOLD * MOVE_SPEED_THRESHOLD:
		set_process(true)


# Called when the controller stops simulating so the rig eases back to the
# idle pose on its own clock instead of freezing mid-stride.
func set_idle() -> void:
	_velocity = Vector2.ZERO
	if _intensity > 0.0 or _reaction != Reaction.NONE:
		set_process(true)


func play_reaction(reaction: Reaction) -> void:
	if reaction == Reaction.NONE:
		return
	_reaction = reaction
	_reaction_time = 0.0
	set_process(true)


func reset_visuals() -> void:
	_reaction = Reaction.NONE
	_reaction_time = 0.0
	_velocity = Vector2.ZERO
	_intensity = 0.0
	_run_phase = 0.0
	_draw_swing = 0.0
	_draw_bob = 0.0
	_draw_reaction_t = 0.0
	_draw_signature = -1
	set_process(false)
	queue_redraw()


func set_grace_active(active: bool) -> void:
	if _grace_active == active:
		return
	_grace_active = active
	queue_redraw()


func _process(delta: float) -> void:
	var speed: float = _velocity.length()
	var moving: bool = speed > MOVE_SPEED_THRESHOLD
	var target_intensity: float = 1.0 if moving else 0.0
	_intensity = move_toward(_intensity, target_intensity, INTENSITY_BLEND_RATE * delta)
	if moving:
		_run_phase = fposmod(_run_phase + speed * PHASE_PER_PIXEL * delta, TAU)
	elif _intensity <= 0.0:
		_run_phase = 0.0

	var reaction_step: int = 0
	if _reaction != Reaction.NONE:
		var duration: float = REACTION_DURATIONS[_reaction]
		_reaction_time += delta
		if _reaction_time >= duration:
			_reaction = Reaction.NONE
			_reaction_time = 0.0
		else:
			reaction_step = int(_reaction_time / duration * float(REACTION_STEPS))

	var frame: int = int(_run_phase / TAU * float(RUN_FRAMES)) % RUN_FRAMES
	var intensity_step: int = int(_intensity * 8.0 + 0.5)
	var signature: int = (
		_facing_bucket
		+ (frame << 3)
		+ (intensity_step << 7)
		+ (reaction_step << 11)
		+ (int(_reaction) << 15)
		+ (int(_grace_active) << 18)
	)
	if signature != _draw_signature:
		_draw_signature = signature
		_draw_swing = sin(_run_phase) * _intensity
		_draw_bob = -absf(sin(_run_phase)) * 2.2 * _intensity
		_draw_reaction_t = float(reaction_step) / float(REACTION_STEPS)
		queue_redraw()

	if not moving and _intensity <= 0.0 and _reaction == Reaction.NONE:
		set_process(false)


func _update_facing_bucket(velocity: Vector2) -> void:
	var bucket: int = wrapi(
		roundi(velocity.angle() / (TAU / float(FACING_BUCKET_COUNT))),
		0,
		FACING_BUCKET_COUNT
	)
	if bucket == _facing_bucket:
		return
	_facing_bucket = bucket
	_facing = Vector2.RIGHT.rotated(TAU / float(FACING_BUCKET_COUNT) * float(bucket))


func _draw() -> void:
	_draw_character()


func _draw_character() -> void:
	var s: float = body_scale_factor
	var upper_offset: Vector2 = Vector2(_facing.x * 1.5 * _intensity, _draw_bob)
	var feet_offset: Vector2 = Vector2.ZERO

	var t: float = _draw_reaction_t
	var arm_mode: Reaction = _reaction
	match _reaction:
		Reaction.BOUNCE:
			var hop: Vector2 = Vector2(0.0, -6.0 * sin(PI * t))
			upper_offset += hop
			feet_offset += hop
		Reaction.CELEBRATE:
			var hop: Vector2 = Vector2(0.0, -5.0 * absf(sin(TAU * t)))
			upper_offset += hop
			feet_offset += hop
		Reaction.REACH:
			upper_offset += _facing * 4.0 * sin(PI * t)
		Reaction.RECOIL:
			upper_offset += -_facing * 5.0 * sin(PI * t)
		Reaction.TIRED:
			upper_offset += Vector2(0.0, 3.0 * sin(PI * t))
		_:
			pass

	_draw_legs(s, upper_offset, feet_offset)
	_draw_torso(s, upper_offset)
	_draw_arms(s, upper_offset, arm_mode)
	_draw_head(s, upper_offset)


func _draw_legs(s: float, upper_offset: Vector2, feet_offset: Vector2) -> void:
	var hip_y: float = -14.0 * s
	var swing_vec: Vector2 = Vector2(_facing.x, _facing.y * 0.55) * 6.0 * s
	var lift_left: float = maxf(_draw_swing, 0.0) * 3.0 * s
	var lift_right: float = maxf(-_draw_swing, 0.0) * 3.0 * s

	var hip_left: Vector2 = Vector2(-4.5 * s, hip_y) + upper_offset
	var hip_right: Vector2 = Vector2(4.5 * s, hip_y) + upper_offset
	var foot_left: Vector2 = (
		Vector2(-4.5 * s, 0.0) + feet_offset
		+ swing_vec * _draw_swing + Vector2(0.0, -lift_left)
	)
	var foot_right: Vector2 = (
		Vector2(4.5 * s, 0.0) + feet_offset
		- swing_vec * _draw_swing + Vector2(0.0, -lift_right)
	)

	draw_line(hip_left, foot_left, SKIN_SHADE_COLOR, 4.5 * s, true)
	draw_line(hip_right, foot_right, SKIN_COLOR, 4.5 * s, true)
	draw_circle(foot_left, 2.4 * s, SKIN_SHADE_COLOR, true, -1.0, true)
	draw_circle(foot_right, 2.4 * s, SKIN_SHADE_COLOR, true, -1.0, true)


func _draw_torso(s: float, upper_offset: Vector2) -> void:
	var outline: Color = _grace_outline_color if _grace_active else _outline_color

	var shorts_rect: Rect2 = Rect2(
		Vector2(-8.0 * s, -23.0 * s) + upper_offset, Vector2(16.0 * s, 10.0 * s)
	)
	draw_rect(shorts_rect, SHORTS_COLOR, true)
	draw_rect(shorts_rect, outline, false, 2.0)

	var torso_rect: Rect2 = Rect2(
		Vector2(-9.5 * s, -39.0 * s) + upper_offset, Vector2(19.0 * s, 17.0 * s)
	)
	draw_rect(torso_rect, _shirt_color, true)
	draw_rect(
		Rect2(
			torso_rect.position + Vector2(torso_rect.size.x - 4.5 * s, 0.0),
			Vector2(4.5 * s, torso_rect.size.y)
		),
		_shirt_shade_color,
		true
	)
	draw_rect(torso_rect, outline, false, 2.0)


func _draw_arms(s: float, upper_offset: Vector2, arm_mode: Reaction) -> void:
	var shoulder_left: Vector2 = Vector2(-9.0 * s, -36.0 * s) + upper_offset
	var shoulder_right: Vector2 = Vector2(9.0 * s, -36.0 * s) + upper_offset
	var hand_left: Vector2 = _get_hand_position(shoulder_left, -1.0, s, arm_mode, -_draw_swing)
	var hand_right: Vector2 = _get_hand_position(shoulder_right, 1.0, s, arm_mode, _draw_swing)

	_draw_arm(shoulder_left, hand_left, s)
	_draw_arm(shoulder_right, hand_right, s)


func _get_hand_position(
	shoulder: Vector2, side: float, s: float, arm_mode: Reaction, swing: float
) -> Vector2:
	match arm_mode:
		Reaction.CELEBRATE, Reaction.BOUNCE:
			return shoulder + Vector2(side * 4.0 * s, -12.0 * s)
		Reaction.REACH:
			return shoulder + Vector2(
				_facing.x * 11.0 * s + side * 2.0 * s, _facing.y * 6.0 * s + 3.0 * s
			)
		Reaction.TIRED:
			return shoulder + Vector2(side * 1.0 * s, 12.0 * s)
		_:
			return (
				shoulder + Vector2(side * 3.0 * s, 10.0 * s)
				+ Vector2(_facing.x, _facing.y * 0.55) * 7.0 * s * swing
			)


func _draw_arm(shoulder: Vector2, hand: Vector2, s: float) -> void:
	var sleeve_end: Vector2 = shoulder.lerp(hand, 0.4)
	draw_line(shoulder, sleeve_end, _shirt_shade_color, 5.0 * s, true)
	draw_line(sleeve_end, hand, SKIN_COLOR, 3.8 * s, true)
	draw_circle(hand, 2.2 * s, SKIN_COLOR, true, -1.0, true)


func _draw_head(s: float, upper_offset: Vector2) -> void:
	var radius: float = 10.0 * s
	var head_center: Vector2 = (
		Vector2(_facing.x * 1.5 * s, -47.0 * s) + upper_offset
	)
	if _reaction == Reaction.TIRED:
		head_center.y += 2.0 * s * sin(PI * _draw_reaction_t)
	var outline: Color = _grace_outline_color if _grace_active else _outline_color

	draw_circle(head_center, radius, SKIN_COLOR, true, -1.0, true)
	_draw_hair(head_center, radius)
	draw_circle(head_center, radius, outline, false, 2.0, true)
	_draw_face(head_center, radius)


func _draw_hair(head_center: Vector2, radius: float) -> void:
	var facing_back: bool = _facing.y < -0.35
	if facing_back:
		# Back view: hair covers most of the head, kept inside the skull
		# outline so it reads as short hair rather than a helmet.
		draw_circle(head_center + Vector2(0.0, -1.0), radius * 0.86, HAIR_COLOR, true, -1.0, true)
	else:
		_fill_hair_cap(head_center, radius)
		if hair_style == HairStyle.FLAT:
			draw_rect(
				Rect2(
					head_center + Vector2(-radius * 0.8, -radius * 0.42),
					Vector2(radius * 1.35, radius * 0.26)
				),
				HAIR_COLOR,
				true
			)
	if hair_style == HairStyle.SPIKY:
		for spike_index: int in range(3):
			var angle: float = -PI * 0.5 + (float(spike_index) - 1.0) * 0.55
			var base_dir: Vector2 = Vector2.RIGHT.rotated(angle)
			var perp: Vector2 = base_dir.orthogonal() * radius * 0.2
			_poly_scratch.resize(3)
			_poly_scratch[0] = head_center + base_dir * radius * 1.22
			_poly_scratch[1] = head_center + base_dir * radius * 0.8 + perp
			_poly_scratch[2] = head_center + base_dir * radius * 0.8 - perp
			draw_colored_polygon(_poly_scratch, HAIR_COLOR)
	if has_headband:
		draw_rect(
			Rect2(
				head_center + Vector2(-radius, -radius * 0.3),
				Vector2(radius * 2.0, radius * 0.34)
			),
			_accent_color,
			true
		)


# Short rounded hair cap: a flattened elliptical dome hugging the top of
# the skull instead of the old full semicircle "helmet".
func _fill_hair_cap(head_center: Vector2, radius: float) -> void:
	var cap_center: Vector2 = head_center + Vector2(0.0, -radius * 0.18)
	var point_count: int = 9
	_poly_scratch.resize(point_count)
	for point_index: int in range(point_count):
		var angle: float = PI + PI * float(point_index) / float(point_count - 1)
		_poly_scratch[point_index] = cap_center + Vector2(
			cos(angle) * radius * 0.99, sin(angle) * radius * 0.62
		)
	draw_colored_polygon(_poly_scratch, HAIR_COLOR)


func _draw_face(head_center: Vector2, radius: float) -> void:
	if _facing.y < -0.35:
		return
	var gaze_x: float = _facing.x * 2.0
	if absf(_facing.y) <= 0.35:
		# Profile: single eye shifted toward the movement side.
		draw_circle(
			head_center + Vector2(_facing.x * radius * 0.5, radius * 0.05),
			1.5 * body_scale_factor,
			HAIR_COLOR,
			true,
			-1.0,
			true
		)
		return
	draw_circle(
		head_center + Vector2(-3.4 * body_scale_factor + gaze_x, 0.5),
		1.4 * body_scale_factor, HAIR_COLOR, true, -1.0, true
	)
	draw_circle(
		head_center + Vector2(3.4 * body_scale_factor + gaze_x, 0.5),
		1.4 * body_scale_factor, HAIR_COLOR, true, -1.0, true
	)
	draw_arc(
		head_center + Vector2(gaze_x, 3.2 * body_scale_factor),
		2.6 * body_scale_factor, 0.4, PI - 0.4, 6, HAIR_COLOR, 1.3, true
	)
