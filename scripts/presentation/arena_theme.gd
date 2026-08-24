class_name ArenaTheme
extends Resource


enum DecorStyle {
	VILLAGE,
}

@export var theme_id: String = "village_courtyard"
@export var theme_name: String = "Village Courtyard"
@export var decor_style: DecorStyle = DecorStyle.VILLAGE

@export_group("Background")
# When set, this photographic background replaces every code-drawn ground
# fill/texture/edge decoration below. Boundary and rebuild-circle stay
# code-drawn regardless, so gameplay markings are always crisp and themeable.
@export var background_texture: Texture2D = null
# Alpha 0 disables the tint; a low alpha darkens/cools the photo backdrop so
# gameplay objects keep enough contrast without touching the source image.
@export var ground_tint_color: Color = Color(0.0, 0.0, 0.0, 0.0)

@export_group("Ground")
@export var ground_color: Color = Color(0.72, 0.46, 0.26, 1.0)
@export var ground_shadow_color: Color = Color(0.62, 0.38, 0.20, 0.55)
@export var ground_dot_light_color: Color = Color(0.82, 0.56, 0.34, 0.35)
@export var ground_dot_dark_color: Color = Color(0.56, 0.34, 0.16, 0.30)
@export var object_shadow_color: Color = Color(0.08, 0.05, 0.03, 0.34)

@export_group("Safe Circle")
@export var safe_circle_active_color: Color = Color(1.0, 0.97, 0.88, 0.85)
@export var safe_circle_inactive_color: Color = Color(1.0, 0.97, 0.88, 0.28)

@export_group("UI Panels")
@export var panel_background_color: Color = Color(0.13, 0.09, 0.06, 0.75)
@export var panel_border_color: Color = Color(0.97, 0.93, 0.85, 0.85)
@export var panel_accent_color: Color = Color(0.95, 0.75, 0.30, 1.0)

@export_group("Player")
@export var player_fill_color: Color = Color(0.12, 0.78, 0.72, 1.0)
@export var player_outline_color: Color = Color(0.03, 0.20, 0.19, 1.0)
@export var player_highlight_color: Color = Color(0.75, 1.0, 0.96, 0.85)
@export var player_marker_color: Color = Color(0.03, 0.20, 0.19, 0.9)

@export_group("Defender")
@export var defender_fill_color: Color = Color(0.85, 0.30, 0.20, 1.0)
@export var defender_outline_color: Color = Color(0.30, 0.08, 0.05, 1.0)
@export var defender_grace_outline_color: Color = Color(0.95, 0.92, 0.85, 0.9)
@export var defender_band_color: Color = Color(0.98, 0.92, 0.80, 1.0)
@export var defender_marker_color: Color = Color(0.30, 0.08, 0.05, 0.95)
@export var defender_grace_alpha: float = 0.55

@export_group("Ball")
@export var ball_fill_color: Color = Color(0.95, 0.90, 0.78, 1.0)
@export var ball_outline_color: Color = Color(0.35, 0.25, 0.12, 1.0)
@export var ball_highlight_color: Color = Color(1.0, 1.0, 0.96, 0.9)

@export_group("Stones")
@export var stone_outline_color: Color = Color(0.16, 0.10, 0.06, 1.0)
@export var stone_highlight_color: Color = Color(1.0, 0.95, 0.85, 0.35)
@export var stone_safe_ring_color: Color = Color(0.98, 0.92, 0.75, 0.85)

@export_group("Edge Decorations")
@export var decorations_enabled: bool = true
@export var decoration_wall_color: Color = Color(0.82, 0.74, 0.60, 0.95)
@export var decoration_wall_shadow_color: Color = Color(0.68, 0.58, 0.45, 0.95)
@export var decoration_roof_color: Color = Color(0.64, 0.27, 0.18, 0.95)
@export var decoration_door_color: Color = Color(0.09, 0.32, 0.32, 0.95)
@export var decoration_stone_wall_color: Color = Color(0.50, 0.42, 0.35, 0.85)
@export var decoration_thatch_color: Color = Color(0.68, 0.55, 0.30, 0.85)
@export var decoration_foliage_color: Color = Color(0.26, 0.40, 0.19, 0.85)
@export var decoration_foliage_light_color: Color = Color(0.36, 0.52, 0.26, 0.85)
@export var decoration_shadow_color: Color = Color(0.0, 0.0, 0.0, 0.10)
@export var decoration_kolam_color: Color = Color(0.97, 0.93, 0.85, 0.55)
