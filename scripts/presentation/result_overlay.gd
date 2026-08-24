class_name ResultOverlay
extends Control


signal play_again_pressed

@onready var _round_label: Label = $Card/Margin/Content/RoundLabel
@onready var _score_label: Label = $Card/Margin/Content/ScoreLabel
@onready var _time_label: Label = $Card/Margin/Content/TimeLabel
@onready var _trips_label: Label = $Card/Margin/Content/TripsLabel
@onready var _tags_label: Label = $Card/Margin/Content/TagsLabel
@onready var _breath_label: Label = $Card/Margin/Content/BreathFailuresLabel
@onready var _best_label: Label = $Card/Margin/Content/BestScoreLabel
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
	round_number: int
) -> void:
	_round_label.text = "Round %d cleared" % round_number
	_score_label.text = "Final Score: %d" % score
	_time_label.text = "Total Time: %s" % _format_time(time_seconds)
	_trips_label.text = "Trips / Deposits: %d" % trips
	_tags_label.text = "Defender Tags: %d" % tags
	_breath_label.text = "Breath Failures: %d" % breath_failures
	_best_label.text = "Best Score (session): %d" % best_score
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
