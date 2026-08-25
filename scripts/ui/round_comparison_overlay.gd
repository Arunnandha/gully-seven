class_name RoundComparisonOverlay
extends Control


signal continue_pressed

@onready var _winner_label: Label = $Card/Margin/Content/WinnerLabel
@onready var _match_score_label: Label = $Card/Margin/Content/MatchScoreLabel
@onready var _name_a: Label = $Card/Margin/Content/StatsGrid/NameA
@onready var _name_b: Label = $Card/Margin/Content/StatsGrid/NameB
@onready var _score_a: Label = $Card/Margin/Content/StatsGrid/ScoreA
@onready var _score_b: Label = $Card/Margin/Content/StatsGrid/ScoreB
@onready var _grade_a: Label = $Card/Margin/Content/StatsGrid/GradeA
@onready var _grade_b: Label = $Card/Margin/Content/StatsGrid/GradeB
@onready var _accuracy_a: Label = $Card/Margin/Content/StatsGrid/AccuracyA
@onready var _accuracy_b: Label = $Card/Margin/Content/StatsGrid/AccuracyB
@onready var _time_a: Label = $Card/Margin/Content/StatsGrid/TimeA
@onready var _time_b: Label = $Card/Margin/Content/StatsGrid/TimeB
@onready var _trips_a: Label = $Card/Margin/Content/StatsGrid/TripsA
@onready var _trips_b: Label = $Card/Margin/Content/StatsGrid/TripsB
@onready var _tags_a: Label = $Card/Margin/Content/StatsGrid/TagsA
@onready var _tags_b: Label = $Card/Margin/Content/StatsGrid/TagsB
@onready var _breath_a: Label = $Card/Margin/Content/StatsGrid/BreathA
@onready var _breath_b: Label = $Card/Margin/Content/StatsGrid/BreathB
@onready var _continue_button: Button = $Card/Margin/Content/ContinueButton


func _ready() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_STOP
	_continue_button.pressed.connect(_on_continue_pressed)


func show_comparison(
	result_a: AttemptResult, result_b: AttemptResult, winner_index: int, wins: Array[int]
) -> void:
	_name_a.text = result_a.player_name
	_name_b.text = result_b.player_name
	_score_a.text = "%d" % result_a.score
	_score_b.text = "%d" % result_b.score
	_grade_a.text = result_a.get_grade_name()
	_grade_b.text = result_b.get_grade_name()
	_accuracy_a.text = "%d%%" % result_a.accuracy_percent
	_accuracy_b.text = "%d%%" % result_b.accuracy_percent
	_time_a.text = _format_time(result_a.elapsed_time)
	_time_b.text = _format_time(result_b.elapsed_time)
	_trips_a.text = "%d" % result_a.trips
	_trips_b.text = "%d" % result_b.trips
	_tags_a.text = "%d" % result_a.tags
	_tags_b.text = "%d" % result_b.tags
	_breath_a.text = "%d" % result_a.breath_failures
	_breath_b.text = "%d" % result_b.breath_failures
	_winner_label.text = _get_winner_text(result_a, result_b, winner_index)
	_match_score_label.text = "MATCH SCORE   %d – %d" % [wins[0], wins[1]]
	_continue_button.disabled = false
	visible = true


func hide_overlay() -> void:
	visible = false


func _get_winner_text(result_a: AttemptResult, result_b: AttemptResult, winner_index: int) -> String:
	if winner_index == 0:
		return "%s WINS THE ROUND" % result_a.player_name.to_upper()
	if winner_index == 1:
		return "%s WINS THE ROUND" % result_b.player_name.to_upper()
	return "ROUND DRAWN"


func _on_continue_pressed() -> void:
	# Locked until the next show_comparison — a double tap here previously
	# advanced the match round twice.
	if _continue_button.disabled:
		return
	_continue_button.disabled = true
	visible = false
	continue_pressed.emit()


func _format_time(time_seconds: float) -> String:
	var total_seconds: int = int(time_seconds)
	return "%d:%02d" % [total_seconds / 60, total_seconds % 60]
