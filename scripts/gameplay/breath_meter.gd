class_name BreathMeter
extends Node


signal breath_expired

@export_range(1.0, 60.0, 0.5) var breath_duration: float = 15.0
@export_range(0.2, 10.0, 0.1) var refill_duration: float = 1.2

var _rebuild_zone: RebuildZone = null
var _ratio: float = 1.0


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
	_ratio = 1.0


func _physics_process(delta: float) -> void:
	if _rebuild_zone.is_player_inside():
		_ratio = minf(_ratio + delta / refill_duration, 1.0)
		return

	if _ratio <= 0.0:
		return

	_ratio = maxf(_ratio - delta / breath_duration, 0.0)
	if _ratio <= 0.0:
		breath_expired.emit()


func _on_round_state_changed(new_state: RoundController.State) -> void:
	set_physics_process(
		new_state == RoundController.State.RAID
		or new_state == RoundController.State.RETURN
	)
