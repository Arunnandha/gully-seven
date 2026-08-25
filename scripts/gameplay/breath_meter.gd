class_name BreathMeter
extends Node


signal breath_expired
signal breath_warning

# Hysteresis keeps the warning a single discrete edge-trigger: it fires once
# on the way down past WARNING_THRESHOLD and only re-arms once breath has
# climbed back past the (higher) rearm threshold, so it can never chatter.
const WARNING_THRESHOLD: float = 0.30
const WARNING_REARM_THRESHOLD: float = 0.45

@export_range(1.0, 60.0, 0.5) var breath_duration: float = 15.0
@export_range(0.2, 10.0, 0.1) var refill_duration: float = 1.2

var _rebuild_zone: RebuildZone = null
var _ratio: float = 1.0
var _warning_armed: bool = true


func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	set_process_input(false)


func setup(round_controller: RoundController, rebuild_zone: RebuildZone) -> void:
	_rebuild_zone = rebuild_zone
	round_controller.state_changed.connect(_on_round_state_changed)


func get_ratio() -> float:
	return _ratio


func refill_full() -> void:
	refill_to(1.0)


# Used at raid start so a weak throw grade can begin the raid with reduced
# breath instead of always topping off to full.
func refill_to(ratio: float) -> void:
	_ratio = clampf(ratio, 0.0, 1.0)
	_warning_armed = true


func _physics_process(delta: float) -> void:
	if _rebuild_zone.is_player_inside():
		_ratio = minf(_ratio + delta / refill_duration, 1.0)
		if _ratio >= WARNING_REARM_THRESHOLD:
			_warning_armed = true
		return

	if _ratio <= 0.0:
		return

	_ratio = maxf(_ratio - delta / breath_duration, 0.0)
	if _warning_armed and _ratio <= WARNING_THRESHOLD and _ratio > 0.0:
		_warning_armed = false
		breath_warning.emit()
	if _ratio <= 0.0:
		breath_expired.emit()


func _on_round_state_changed(new_state: RoundController.State) -> void:
	set_physics_process(
		new_state == RoundController.State.RAID
		or new_state == RoundController.State.RETURN
	)
