class_name ResultOverlay
extends Control


signal play_again_pressed

@onready var _round_label: Label = $Card/Margin/Content/RoundLabel
@onready var _score_value: Label = $Card/Margin/Content/ScoreValue
@onready var _time_value: Label = $Card/Margin/Content/StatsGrid/TimeValue
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
	round_number: int
) -> void:
	_round_label.text = "ROUND %d COMPLETE" % round_number
	_score_value.text = "%d" % score
	_time_value.text = _format_time(time_seconds)
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
