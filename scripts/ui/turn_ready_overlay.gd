class_name TurnReadyOverlay
extends Control


# Opaque full-screen turn-transition card, reused for every attempt start
# in a Local Challenge match. Doubles as the "private handover" screen
# required between Player 1 and Player 2: since it fully covers the arena
# and never displays scores, showing it for a handover needs no separate
# overlay — only its hint text changes.

signal ready_pressed

@onready var _player_label: Label = $Card/Margin/Content/PlayerLabel
@onready var _round_label: Label = $Card/Margin/Content/RoundLabel
@onready var _hint_label: Label = $Card/Margin/Content/HintLabel
@onready var _ready_button: Button = $Card/Margin/Content/ReadyButton


func _ready() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_STOP
	_ready_button.pressed.connect(_on_ready_pressed)


func show_for(
	player_name: String, match_round: int, is_handover: bool, tiebreaker_number: int = 0
) -> void:
	_player_label.text = "%s — GET READY" % player_name.to_upper()
	_round_label.text = (
		"TIEBREAKER %d" % tiebreaker_number
		if tiebreaker_number > 0
		else "ROUND %d OF 3" % match_round
	)
	_hint_label.text = (
		"Pass the device, then tap Ready" if is_handover else "Tap Ready when you're set"
	)
	_ready_button.disabled = false
	visible = true


func hide_overlay() -> void:
	visible = false


func _on_ready_pressed() -> void:
	# Locked until the next show_for so a stray second tap (multi-touch or
	# queued release) can never confirm the same turn twice.
	if _ready_button.disabled:
		return
	_ready_button.disabled = true
	visible = false
	ready_pressed.emit()
