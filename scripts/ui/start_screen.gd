class_name StartScreen
extends Control


signal play_pressed
signal local_challenge_pressed
signal theme_prev_pressed
signal theme_next_pressed
signal sfx_toggled(enabled: bool)
signal haptics_toggled(enabled: bool)

@onready var _theme_label: Label = $Panel/Margin/Content/ThemeRow/ThemeNameLabel
@onready var _prev_button: Button = $Panel/Margin/Content/ThemeRow/PrevButton
@onready var _next_button: Button = $Panel/Margin/Content/ThemeRow/NextButton
@onready var _sfx_toggle: CheckButton = $Panel/Margin/Content/TogglesRow/SfxToggle
@onready var _haptics_toggle: CheckButton = $Panel/Margin/Content/TogglesRow/HapticsToggle
@onready var _play_button: Button = $Panel/Margin/Content/PlayButton
@onready var _local_challenge_button: Button = $Panel/Margin/Content/LocalChallengeButton


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	_prev_button.pressed.connect(_on_prev_pressed)
	_next_button.pressed.connect(_on_next_pressed)
	_play_button.pressed.connect(_on_play_pressed)
	_local_challenge_button.pressed.connect(_on_local_challenge_pressed)
	_sfx_toggle.toggled.connect(_on_sfx_toggled)
	_haptics_toggle.toggled.connect(_on_haptics_toggled)


func show_screen() -> void:
	visible = true


func hide_screen() -> void:
	visible = false


func set_theme_name(theme_name: String) -> void:
	_theme_label.text = theme_name


func set_sfx_enabled(enabled: bool) -> void:
	_sfx_toggle.set_pressed_no_signal(enabled)


func set_haptics_enabled(enabled: bool) -> void:
	_haptics_toggle.set_pressed_no_signal(enabled)


func _on_prev_pressed() -> void:
	theme_prev_pressed.emit()


func _on_next_pressed() -> void:
	theme_next_pressed.emit()


func _on_play_pressed() -> void:
	play_pressed.emit()


func _on_local_challenge_pressed() -> void:
	local_challenge_pressed.emit()


func _on_sfx_toggled(enabled: bool) -> void:
	sfx_toggled.emit(enabled)


func _on_haptics_toggled(enabled: bool) -> void:
	haptics_toggled.emit(enabled)
