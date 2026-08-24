class_name ArenaBackdrop
extends Node2D


# Deterministic ground texture: precomputed once (fixed seed) and reused for
# every redraw, so the pattern never looks "randomly regenerated" and never
# costs anything per frame — only viewport resize/theme swap triggers a draw.
const PATTERN_SEED: int = 918273
const GROUND_DOT_COUNT: int = 90
const GROUND_STROKE_COUNT: int = 34
const GROUND_PATCH_COUNT: int = 6
const SHAKE_MARGIN: float = 16.0

const KOLAM_SPOTS: Array[Vector2] = [Vector2(0.07, 0.16), Vector2(0.90, 0.86)]
const PLANT_SPOTS: Array[Vector2] = [
	Vector2(0.025, 0.90), Vector2(0.975, 0.88), Vector2(0.955, 0.09),
]
const TREE_SHADOW_SPOTS: Array[Vector2] = [
	Vector2(0.0, 0.42), Vector2(1.0, 0.58), Vector2(0.18, 1.0),
]

var _theme: ArenaTheme = null
var _viewport_size: Vector2 = Vector2.ZERO
var _background_texture: Texture2D = null
var _background_draw_rect: Rect2 = Rect2()

var _dot_positions: PackedVector2Array = PackedVector2Array()
var _dot_variants: PackedFloat32Array = PackedFloat32Array()
var _dot_radii: PackedFloat32Array = PackedFloat32Array()
var _stroke_positions: PackedVector2Array = PackedVector2Array()
var _stroke_angles: PackedFloat32Array = PackedFloat32Array()
var _stroke_lengths: PackedFloat32Array = PackedFloat32Array()
var _patch_positions: PackedVector2Array = PackedVector2Array()
var _patch_radii: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	_generate_ground_pattern()


func setup(arena_theme: ArenaTheme) -> void:
	_theme = arena_theme
	_background_texture = arena_theme.background_texture
	_recompute_background_rect()
	queue_redraw()


func set_viewport_size(viewport_size: Vector2) -> void:
	if viewport_size == _viewport_size:
		return
	_viewport_size = viewport_size
	_recompute_background_rect()
	queue_redraw()


# "Cover" scaling: the single largest axis-uniform scale that makes the
# texture fully span the viewport on both axes, then centers it — excess
# spills past the viewport edges and is naturally clipped at render time.
# Only recomputed here (setup/resize), never per frame.
func _recompute_background_rect() -> void:
	if _background_texture == null or _viewport_size == Vector2.ZERO:
		_background_draw_rect = Rect2()
		return
	var texture_size: Vector2 = _background_texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		_background_draw_rect = Rect2()
		return
	var cover_scale: float = maxf(
		_viewport_size.x / texture_size.x, _viewport_size.y / texture_size.y
	)
	var drawn_size: Vector2 = texture_size * cover_scale
	var offset: Vector2 = (_viewport_size - drawn_size) * 0.5
	_background_draw_rect = Rect2(offset, drawn_size)


func _generate_ground_pattern() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = PATTERN_SEED

	_dot_positions.resize(GROUND_DOT_COUNT)
	_dot_variants.resize(GROUND_DOT_COUNT)
	_dot_radii.resize(GROUND_DOT_COUNT)
	for dot_index: int in range(GROUND_DOT_COUNT):
		_dot_positions[dot_index] = Vector2(rng.randf(), rng.randf())
		_dot_variants[dot_index] = rng.randf()
		_dot_radii[dot_index] = rng.randf_range(1.5, 3.5)

	_stroke_positions.resize(GROUND_STROKE_COUNT)
	_stroke_angles.resize(GROUND_STROKE_COUNT)
	_stroke_lengths.resize(GROUND_STROKE_COUNT)
	for stroke_index: int in range(GROUND_STROKE_COUNT):
		_stroke_positions[stroke_index] = Vector2(rng.randf(), rng.randf())
		_stroke_angles[stroke_index] = rng.randf_range(0.0, TAU)
		_stroke_lengths[stroke_index] = rng.randf_range(10.0, 22.0)

	_patch_positions.resize(GROUND_PATCH_COUNT)
	_patch_radii.resize(GROUND_PATCH_COUNT)
	for patch_index: int in range(GROUND_PATCH_COUNT):
		_patch_positions[patch_index] = Vector2(rng.randf(), rng.randf())
		_patch_radii[patch_index] = rng.randf_range(70.0, 140.0)


func _draw() -> void:
	if _theme == null or _viewport_size == Vector2.ZERO:
		return

	if _background_texture != null:
		# Photographic background already contains the ground, house, plants,
		# kolam and shadows, so none of the code-drawn ground/decor runs here.
		draw_texture_rect(_background_texture, _background_draw_rect, false)
		_draw_ground_tint()
	else:
		_draw_ground()
		if _theme.decorations_enabled:
			_draw_tree_shadows()
		_draw_ground_texture()
		if _theme.decorations_enabled:
			_draw_edge_decorations()


func _draw_ground_tint() -> void:
	if _theme.ground_tint_color.a <= 0.0:
		return
	var full_rect: Rect2 = Rect2(
		-Vector2.ONE * SHAKE_MARGIN, _viewport_size + Vector2.ONE * SHAKE_MARGIN * 2.0
	)
	draw_rect(full_rect, _theme.ground_tint_color, true)


func _draw_ground() -> void:
	var full_rect: Rect2 = Rect2(
		-Vector2.ONE * SHAKE_MARGIN, _viewport_size + Vector2.ONE * SHAKE_MARGIN * 2.0
	)
	draw_rect(full_rect, _theme.ground_color, true)
	for patch_index: int in range(_patch_positions.size()):
		var center: Vector2 = _patch_positions[patch_index] * _viewport_size
		draw_circle(center, _patch_radii[patch_index], _theme.ground_shadow_color, true, -1.0, true)


func _draw_ground_texture() -> void:
	for dot_index: int in range(_dot_positions.size()):
		var center: Vector2 = _dot_positions[dot_index] * _viewport_size
		var color: Color = _theme.ground_dot_dark_color.lerp(
			_theme.ground_dot_light_color, _dot_variants[dot_index]
		)
		draw_circle(center, _dot_radii[dot_index], color, true, -1.0, true)

	for stroke_index: int in range(_stroke_positions.size()):
		var center: Vector2 = _stroke_positions[stroke_index] * _viewport_size
		var direction: Vector2 = Vector2.RIGHT.rotated(_stroke_angles[stroke_index])
		var half_length: float = _stroke_lengths[stroke_index] * 0.5
		draw_line(
			center - direction * half_length,
			center + direction * half_length,
			_theme.ground_dot_dark_color,
			1.5,
			true
		)


func _draw_tree_shadows() -> void:
	for spot: Vector2 in TREE_SHADOW_SPOTS:
		_draw_tree_shadow(spot * _viewport_size)


func _draw_tree_shadow(base: Vector2) -> void:
	draw_circle(base, 110.0, _theme.decoration_shadow_color, true, -1.0, true)
	draw_circle(base + Vector2(46.0, 20.0), 70.0, _theme.decoration_shadow_color, true, -1.0, true)
	draw_circle(base + Vector2(-40.0, 26.0), 60.0, _theme.decoration_shadow_color, true, -1.0, true)


func _draw_edge_decorations() -> void:
	match _theme.decor_style:
		ArenaTheme.DecorStyle.VILLAGE:
			_draw_village_decorations()


func _draw_village_decorations() -> void:
	_draw_wall_and_door(Vector2.ZERO)
	_draw_stone_wall_hint(Vector2(0.30, 1.0) * _viewport_size)
	_draw_thatch_hint(Vector2(0.97, 0.97) * _viewport_size)

	for spot: Vector2 in KOLAM_SPOTS:
		_draw_kolam(spot * _viewport_size)

	for spot: Vector2 in PLANT_SPOTS:
		_draw_plant(spot * _viewport_size)


func _draw_wall_and_door(corner: Vector2) -> void:
	var wall_size: Vector2 = Vector2(196.0, 108.0)
	var wall_rect: Rect2 = Rect2(corner, wall_size)
	draw_rect(wall_rect, _theme.decoration_wall_color, true)
	draw_rect(
		Rect2(wall_rect.position + Vector2(0.0, wall_size.y - 14.0), Vector2(wall_size.x, 14.0)),
		_theme.decoration_wall_shadow_color,
		true
	)

	# Scalloped tiled-roof edge along the top of the wall.
	var tile_count: int = 7
	var tile_width: float = wall_size.x / float(tile_count)
	for tile_index: int in range(tile_count):
		var tile_center: Vector2 = wall_rect.position + Vector2(
			tile_width * (float(tile_index) + 0.5), 0.0
		)
		draw_circle(tile_center, tile_width * 0.58, _theme.decoration_roof_color, true, -1.0, true)
	draw_rect(
		Rect2(wall_rect.position + Vector2(0.0, -10.0), Vector2(wall_size.x, 16.0)),
		_theme.decoration_roof_color,
		true
	)

	# Small square window.
	var window_rect: Rect2 = Rect2(wall_rect.position + Vector2(24.0, 30.0), Vector2(26.0, 26.0))
	draw_rect(window_rect, _theme.decoration_wall_shadow_color, false, 3.0)

	# Teal door, rounded top approximated with a half-circle cap.
	var door_size: Vector2 = Vector2(40.0, 58.0)
	var door_position: Vector2 = wall_rect.position + Vector2(wall_size.x - 74.0, wall_size.y - door_size.y)
	draw_rect(Rect2(door_position, door_size), _theme.decoration_door_color, true)
	draw_circle(
		door_position + Vector2(door_size.x * 0.5, 0.0), door_size.x * 0.5, _theme.decoration_door_color, true, -1.0, true
	)


func _draw_stone_wall_hint(anchor: Vector2) -> void:
	var wall_size: Vector2 = Vector2(220.0, 34.0)
	var wall_rect: Rect2 = Rect2(anchor - Vector2(wall_size.x * 0.5, wall_size.y), wall_size)
	draw_rect(wall_rect, _theme.decoration_stone_wall_color, true)
	var block_count: int = 6
	for block_index: int in range(1, block_count):
		var x: float = wall_rect.position.x + wall_size.x * float(block_index) / float(block_count)
		draw_line(
			Vector2(x, wall_rect.position.y + 4.0),
			Vector2(x, wall_rect.end.y - 4.0),
			_theme.decoration_wall_shadow_color,
			2.0,
			true
		)


func _draw_thatch_hint(corner: Vector2) -> void:
	var roof_size: Vector2 = Vector2(130.0, 90.0)
	var apex: Vector2 = corner - roof_size
	var points: PackedVector2Array = PackedVector2Array([
		corner, Vector2(corner.x, apex.y + roof_size.y * 0.35), apex + Vector2(roof_size.x * 0.2, 0.0),
	])
	draw_colored_polygon(points, _theme.decoration_thatch_color)
	for line_index: int in range(3):
		var t: float = float(line_index + 1) / 4.0
		draw_line(
			corner.lerp(Vector2(corner.x, apex.y + roof_size.y * 0.35), t),
			apex.lerp(Vector2(corner.x, apex.y + roof_size.y * 0.35), 1.0 - t) + Vector2(roof_size.x * 0.2 * t, 0.0),
			_theme.decoration_wall_shadow_color,
			1.5,
			true
		)


func _draw_kolam(center: Vector2) -> void:
	var radius: float = 30.0
	var petal_count: int = 8
	for petal_index: int in range(petal_count):
		var angle: float = TAU * float(petal_index) / float(petal_count)
		var petal_center: Vector2 = center + Vector2.RIGHT.rotated(angle) * radius * 0.55
		draw_circle(petal_center, radius * 0.24, _theme.decoration_kolam_color, false, 2.0, true)
	draw_circle(center, radius * 0.9, _theme.decoration_kolam_color, false, 1.5, true)
	draw_circle(center, radius * 0.14, _theme.decoration_kolam_color, false, 2.0, true)


func _draw_plant(base: Vector2) -> void:
	var pot_size: Vector2 = Vector2(26.0, 18.0)
	var pot_points: PackedVector2Array = PackedVector2Array([
		base + Vector2(-pot_size.x * 0.5, 0.0),
		base + Vector2(pot_size.x * 0.5, 0.0),
		base + Vector2(pot_size.x * 0.35, pot_size.y),
		base + Vector2(-pot_size.x * 0.35, pot_size.y),
	])
	draw_colored_polygon(pot_points, _theme.decoration_stone_wall_color)

	var leaf_center: Vector2 = base + Vector2(0.0, -pot_size.y * 0.3)
	draw_circle(leaf_center, 17.0, _theme.decoration_foliage_color, true, -1.0, true)
	draw_circle(leaf_center + Vector2(14.0, -6.0), 12.0, _theme.decoration_foliage_light_color, true, -1.0, true)
	draw_circle(leaf_center + Vector2(-13.0, -8.0), 11.0, _theme.decoration_foliage_light_color, true, -1.0, true)
