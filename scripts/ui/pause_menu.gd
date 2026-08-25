class_name PauseMenu
extends Control


signal resume_pressed
signal restart_pressed
signal home_pressed
signal sfx_toggled(enabled: bool)
signal haptics_toggled(enabled: bool)

@onready var _resume_button: Button = $Card/Margin/Content/ResumeButton
@onready var _restart_button: Button = $Card/Margin/Content/RestartButton
@onready var _home_button: Button = $Card/Margin/Content/HomeButton
@onready var _sfx_toggle: CheckButton = $Card/Margin/Content/TogglesRow/SfxToggle
@onready var _haptics_toggle: CheckButton = $Card/Margin/Content/TogglesRow/HapticsToggle


func _ready() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_STOP
	_resume_button.pressed.connect(_on_resume_pressed)
	_restart_button.pressed.connect(_on_restart_pressed)
	_home_button.pressed.connect(_on_home_pressed)
	_sfx_toggle.toggled.connect(_on_sfx_toggled)
	_haptics_toggle.toggled.connect(_on_haptics_toggled)


func show_menu(sfx_enabled: bool, haptics_enabled: bool) -> void:
	_sfx_toggle.set_pressed_no_signal(sfx_enabled)
	_haptics_toggle.set_pressed_no_signal(haptics_enabled)
	visible = true


func hide_menu() -> void:
	visible = false


func _on_resume_pressed() -> void:
	resume_pressed.emit()


func _on_restart_pressed() -> void:
	restart_pressed.emit()


func _on_home_pressed() -> void:
	home_pressed.emit()


func _on_sfx_toggled(enabled: bool) -> void:
	sfx_toggled.emit(enabled)


func _on_haptics_toggled(enabled: bool) -> void:
	haptics_toggled.emit(enabled)
