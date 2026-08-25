class_name GullyPlayerVisual
extends GullyCharacterVisual


# Village-boy player: flat side-swept hair, teal shirt (from theme).


func _init() -> void:
	hair_style = HairStyle.FLAT
	has_headband = false
	body_scale_factor = 1.0
	_facing = Vector2.DOWN
	_facing_bucket = 2


func apply_theme(arena_theme: ArenaTheme) -> void:
	_shirt_color = arena_theme.player_fill_color
	_shirt_shade_color = arena_theme.player_fill_color.darkened(0.28)
	_outline_color = arena_theme.player_outline_color
	_grace_outline_color = arena_theme.player_highlight_color
	_accent_color = arena_theme.player_highlight_color
	_shadow.set_shadow_color(arena_theme.object_shadow_color)
	queue_redraw()
