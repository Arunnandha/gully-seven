class_name GradeBadge
extends Label


# Brief on-screen throw-grade readout: fades in, holds, fades out. Shares
# the same top-center HUD slot the breath bar uses — the two never overlap
# since the badge only shows right after impact (BREAK state), before the
# breath bar appears for RAID/RETURN.

const FADE_IN_DURATION: float = 0.12
const HOLD_DURATION: float = 1.1
const FADE_OUT_DURATION: float = 0.35

const WEAK_COLOR: Color = Color(0.45, 0.85, 0.42, 1.0)
const MEDIUM_COLOR: Color = Color(0.97, 0.78, 0.28, 1.0)
const STRONG_COLOR: Color = Color(0.95, 0.45, 0.22, 1.0)
const PERFECT_COLOR: Color = Color(1.0, 0.92, 0.55, 1.0)

var _tween: Tween = null


func _ready() -> void:
	visible = false
	modulate.a = 0.0


func show_for_grade(grade: ThrowBall.ThrowGrade) -> void:
	var label_text: String = ThrowBall.get_grade_name(grade)
	if grade == ThrowBall.ThrowGrade.PERFECT:
		label_text = "★ PERFECT ★"
	_show(label_text, _get_grade_color(grade))


func reset_badge() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	visible = false
	modulate.a = 0.0


func _show(label_text: String, color: Color) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	text = label_text
	add_theme_color_override("font_color", color)
	modulate.a = 0.0
	visible = true
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, FADE_IN_DURATION)
	_tween.tween_interval(HOLD_DURATION)
	_tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_DURATION)
	_tween.tween_callback(_on_fade_complete)


func _on_fade_complete() -> void:
	visible = false


func _get_grade_color(grade: ThrowBall.ThrowGrade) -> Color:
	match grade:
		ThrowBall.ThrowGrade.WEAK:
			return WEAK_COLOR
		ThrowBall.ThrowGrade.STRONG:
			return STRONG_COLOR
		ThrowBall.ThrowGrade.PERFECT:
			return PERFECT_COLOR
		_:
			return MEDIUM_COLOR
