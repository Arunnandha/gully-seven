class_name ResultOverlay
extends Control


signal play_again_pressed

const RANK_COLORS: Dictionary = {
	"BRONZE": Color(0.80, 0.55, 0.35, 1.0),
	"SILVER": Color(0.82, 0.85, 0.90, 1.0),
	"GOLD": Color(1.0, 0.82, 0.30, 1.0),
	"PERFECT": Color(0.65, 0.95, 1.0, 1.0),
}
const DEFAULT_RANK_COLOR: Color = Color(0.95, 0.92, 0.86, 1.0)

@onready var _round_label: Label = $Card/Margin/Content/RoundLabel
@onready var _rank_value: Label = $Card/Margin/Content/RankValue
@onready var _score_value: Label = $Card/Margin/Content/ScoreValue
@onready var _grade_value: Label = $Card/Margin/Content/StatsGrid/GradeValue
@onready var _accuracy_value: Label = $Card/Margin/Content/StatsGrid/AccuracyValue
@onready var _time_value: Label = $Card/Margin/Content/StatsGrid/TimeValue
@onready var _rebuilt_value: Label = $Card/Margin/Content/StatsGrid/RebuiltValue
@onready var _trips_value: Label = $Card/Margin/Content/StatsGrid/TripsValue
@onready var _tags_value: Label = $Card/Margin/Content/StatsGrid/TagsValue
@onready var _breath_value: Label = $Card/Margin/Content/StatsGrid/BreathValue
@onready var _best_value: Label = $Card/Margin/Content/BestRow/BestValue
@onready var _play_again_button: Button = $Card/Margin/Content/PlayAgainButton


func _ready() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_STOP
	_play_again_button.pressed.connect(_on_play_again_pressed)


func show_result(
	score: int,
	time_seconds: float,
	trips: int,
	tags: int,
	breath_failures: int,
	best_score: int,
	round_number: int,
	grade_name: String,
	accuracy_percent: int,
	stones_rebuilt: int,
	rank_name: String
) -> void:
	_round_label.text = "ROUND %d COMPLETE" % round_number
	_rank_value.text = "RANK: %s" % rank_name
	_rank_value.add_theme_color_override(
		"font_color", RANK_COLORS.get(rank_name, DEFAULT_RANK_COLOR)
	)
	_score_value.text = "%d" % score
	_grade_value.text = grade_name
	_accuracy_value.text = "%d%%" % accuracy_percent
	_time_value.text = _format_time(time_seconds)
	_rebuilt_value.text = "%d" % stones_rebuilt
	_trips_value.text = "%d" % trips
	_tags_value.text = "%d" % tags
	_breath_value.text = "%d" % breath_failures
	_best_value.text = "%d" % best_score
	visible = true


func hide_result() -> void:
	visible = false


func _on_play_again_pressed() -> void:
	play_again_pressed.emit()


func _format_time(time_seconds: float) -> String:
	var total_seconds: int = int(time_seconds)
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	return "%d:%02d" % [minutes, seconds]
