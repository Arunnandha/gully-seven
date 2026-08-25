class_name FinalMatchOverlay
extends Control


signal rematch_pressed
signal home_pressed

@onready var _winner_label: Label = $Card/Margin/Content/WinnerLabel
@onready var _set_score_label: Label = $Card/Margin/Content/SetScoreLabel
@onready var _name_a: Label = $Card/Margin/Content/StatsGrid/NameA
@onready var _name_b: Label = $Card/Margin/Content/StatsGrid/NameB
@onready var _combined_score_a: Label = $Card/Margin/Content/StatsGrid/CombinedScoreA
@onready var _combined_score_b: Label = $Card/Margin/Content/StatsGrid/CombinedScoreB
@onready var _best_grade_a: Label = $Card/Margin/Content/StatsGrid/BestGradeA
@onready var _best_grade_b: Label = $Card/Margin/Content/StatsGrid/BestGradeB
@onready var _rematch_button: Button = $Card/Margin/Content/RematchButton
@onready var _home_button: Button = $Card/Margin/Content/HomeButton


func _ready() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_STOP
	_rematch_button.pressed.connect(_on_rematch_pressed)
	_home_button.pressed.connect(_on_home_pressed)


func show_final(
	winner_index: int,
	wins: Array[int],
	names: Array[String],
	total_scores: Array[int],
	best_grade_names: Array[String]
) -> void:
	_winner_label.text = (
		"MATCH DRAWN" if winner_index < 0 else "%s WINS THE MATCH!" % names[winner_index].to_upper()
	)
	_set_score_label.text = "FINAL SCORE   %d – %d" % [wins[0], wins[1]]
	_name_a.text = names[0]
	_name_b.text = names[1]
	_combined_score_a.text = "%d" % total_scores[0]
	_combined_score_b.text = "%d" % total_scores[1]
	_best_grade_a.text = best_grade_names[0]
	_best_grade_b.text = best_grade_names[1]
	_rematch_button.disabled = false
	_home_button.disabled = false
	visible = true


func hide_overlay() -> void:
	visible = false


func _on_rematch_pressed() -> void:
	# Both buttons lock together until the next show_final so one decision
	# can't fire twice or race the other.
	if _rematch_button.disabled:
		return
	_rematch_button.disabled = true
	_home_button.disabled = true
	visible = false
	rematch_pressed.emit()


func _on_home_pressed() -> void:
	if _home_button.disabled:
		return
	_rematch_button.disabled = true
	_home_button.disabled = true
	visible = false
	home_pressed.emit()
