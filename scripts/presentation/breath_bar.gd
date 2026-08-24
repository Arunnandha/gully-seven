class_name BreathBar
extends Control


const LOW_THRESHOLD: float = 0.2
const MID_THRESHOLD: float = 0.5
const HIGH_COLOR: Color = Color(0.30, 0.85, 0.35, 1.0)
const MID_COLOR: Color = Color(0.95, 0.75, 0.20, 1.0)
const LOW_COLOR: Color = Color(0.92, 0.25, 0.18, 1.0)
const LABEL_COLOR: Color = Color(1.0, 0.95, 0.85, 1.0)
const LABEL_FONT_SIZE: int = 15
const PULSE_FREQUENCY: float = 9.0
const LABEL_BASELINE: float = 15.0
const BAR_TOP: float = 22.0
const BORDER_WIDTH: float = 3.0
const FILL_INSET: float = 3.0

var _meter: BreathMeter = null
var _last_ratio: float = -1.0
var _background_color: Color = Color(0.10, 0.08, 0.06, 0.60)
var _border_color: Color = Color(1.0, 1.0, 1.0, 0.75)


func _ready() -> void:
	set_process(false)
	mouse_filter = MOUSE_FILTER_IGNORE


func setup(meter: BreathMeter) -> void:
	_meter = meter


func apply_theme(arena_theme: ArenaTheme) -> void:
	_background_color = arena_theme.panel_background_color
	_border_color = arena_theme.panel_border_color
	queue_redraw()


func set_shown(shown: bool) -> void:
	visible = shown
	set_process(shown)
	if shown:
		_last_ratio = -1.0
		queue_redraw()


func _process(_delta: float) -> void:
	var ratio: float = _meter.get_ratio()
	# Redraw only when the value changed, except in the low band where the
	# pulse animates alpha continuously.
	if ratio != _last_ratio or ratio < LOW_THRESHOLD:
		_last_ratio = ratio
		queue_redraw()


func _draw() -> void:
	var ratio: float = _meter.get_ratio() if _meter != null else 1.0

	# Faux-bold: draw the caption twice with a 1px offset instead of relying
	# on a bold font asset.
	for offset_x: float in [0.0, 1.0]:
		draw_string(
			ThemeDB.fallback_font,
			Vector2(offset_x, LABEL_BASELINE),
			"BREATH",
			HORIZONTAL_ALIGNMENT_CENTER,
			size.x,
			LABEL_FONT_SIZE,
			LABEL_COLOR
		)

	var bar_rect: Rect2 = Rect2(0.0, BAR_TOP, size.x, size.y - BAR_TOP)
	draw_rect(bar_rect, _background_color, true)
	draw_rect(bar_rect, _border_color, false, BORDER_WIDTH)

	if ratio <= 0.0:
		return

	var fill_color: Color = HIGH_COLOR
	if ratio <= LOW_THRESHOLD:
		fill_color = LOW_COLOR
		var pulse_phase: float = float(Time.get_ticks_msec()) * 0.001 * PULSE_FREQUENCY
		fill_color.a = 0.72 + 0.28 * (0.5 + 0.5 * sin(pulse_phase))
	elif ratio <= MID_THRESHOLD:
		fill_color = MID_COLOR

	var fill_rect: Rect2 = Rect2(
		bar_rect.position + Vector2(FILL_INSET, FILL_INSET),
		Vector2(
			(bar_rect.size.x - FILL_INSET * 2.0) * ratio,
			bar_rect.size.y - FILL_INSET * 2.0
		)
	)
	draw_rect(fill_rect, fill_color, true)
