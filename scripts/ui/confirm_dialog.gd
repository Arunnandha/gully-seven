class_name ConfirmDialog
extends Control


# Small reusable yes/no confirmation card. Not match-specific — anything
# that needs an "are you sure?" gate can reuse this one pre-created node.

signal confirmed
signal cancelled

@onready var _message_label: Label = $Card/Margin/Content/MessageLabel
@onready var _confirm_button: Button = $Card/Margin/Content/ButtonsRow/ConfirmButton
@onready var _cancel_button: Button = $Card/Margin/Content/ButtonsRow/CancelButton


func _ready() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_STOP
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_cancel_button.pressed.connect(_on_cancel_pressed)


func show_confirm(message: String) -> void:
	_message_label.text = message
	visible = true


func hide_dialog() -> void:
	visible = false


func _on_confirm_pressed() -> void:
	visible = false
	confirmed.emit()


func _on_cancel_pressed() -> void:
	visible = false
	cancelled.emit()
