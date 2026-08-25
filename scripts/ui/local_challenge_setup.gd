class_name LocalChallengeSetup
extends Control


signal start_match_pressed(name_a: String, name_b: String)
signal back_pressed

const DEFAULT_NAME_A: String = "Player 1"
const DEFAULT_NAME_B: String = "Player 2"

@onready var _name_a_edit: LineEdit = $Panel/Margin/Content/NameAEdit
@onready var _name_b_edit: LineEdit = $Panel/Margin/Content/NameBEdit
@onready var _start_button: Button = $Panel/Margin/Content/StartMatchButton
@onready var _back_button: Button = $Panel/Margin/Content/BackButton


func _ready() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_STOP
	_name_a_edit.text = DEFAULT_NAME_A
	_name_b_edit.text = DEFAULT_NAME_B
	_start_button.pressed.connect(_on_start_pressed)
	_back_button.pressed.connect(_on_back_pressed)


func show_screen() -> void:
	visible = true


func hide_screen() -> void:
	visible = false


func _on_start_pressed() -> void:
	var name_a: String = _name_a_edit.text.strip_edges()
	var name_b: String = _name_b_edit.text.strip_edges()
	start_match_pressed.emit(
		name_a if name_a != "" else DEFAULT_NAME_A,
		name_b if name_b != "" else DEFAULT_NAME_B
	)


func _on_back_pressed() -> void:
	back_pressed.emit()
