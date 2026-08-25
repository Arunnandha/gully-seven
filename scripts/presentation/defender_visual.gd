class_name GullyDefenderVisual
extends GullyCharacterVisual


# Village-boy defender: spiky hair with a headband, red-orange shirt (from
# theme). During grace the controller lowers modulate alpha and this rig
# swaps the dark danger outline for a soft neutral one plus a dashed ring;
# both disappear the moment tagging becomes active again.

const GRACE_RING_RADIUS: float = 34.0
const GRACE_RING_DASHES: int = 12


func _init() -> void:
	hair_style = HairStyle.SPIKY
	has_headband = true
	body_scale_factor = 0.95
	_facing = Vector2.LEFT
	_facing_bucket = 4


func apply_theme(arena_theme: ArenaTheme) -> void:
	_shirt_color = arena_theme.defender_fill_color
	_shirt_shade_color = arena_theme.defender_fill_color.darkened(0.30)
	_outline_color = arena_theme.defender_outline_color
	_grace_outline_color = arena_theme.defender_grace_outline_color
	_accent_color = arena_theme.defender_band_color
	_shadow.set_shadow_color(arena_theme.object_shadow_color)
	queue_redraw()


func _draw() -> void:
	_draw_character()
	if _grace_active:
		_draw_grace_ring()


func _draw_grace_ring() -> void:
	var dash_angle: float = TAU / float(GRACE_RING_DASHES)
	var ring_center: Vector2 = Vector2(0.0, -24.0 * body_scale_factor)
	for dash_index: int in range(GRACE_RING_DASHES):
		var start_angle: float = dash_angle * float(dash_index)
		draw_arc(
			ring_center,
			GRACE_RING_RADIUS,
			start_angle,
			start_angle + dash_angle * 0.5,
			4,
			_grace_outline_color,
			3.0,
			true
		)
