class_name ScreenShake
extends Node


const DECAY_RATE: float = 6.0
const MAX_OFFSET: float = 10.0

var _target: Node2D = null
var _base_position: Vector2 = Vector2.ZERO
var _trauma: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	set_process(false)


func setup(target: Node2D) -> void:
	_target = target
	_base_position = target.position


func shake(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)
	set_process(true)


func stop() -> void:
	_trauma = 0.0
	if _target != null:
		_target.position = _base_position
	set_process(false)


func _process(delta: float) -> void:
	_trauma = maxf(_trauma - DECAY_RATE * delta, 0.0)
	if _trauma <= 0.0:
		stop()
		return
	var power: float = _trauma * _trauma
	var offset: Vector2 = Vector2(
		_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)
	) * power * MAX_OFFSET
	_target.position = _base_position + offset
