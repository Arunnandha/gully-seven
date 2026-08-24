class_name EffectPool
extends Node2D


enum Kind {
	BALL_RELEASE,
	TOWER_IMPACT,
	STONE_COLLECT,
	STONE_DEPOSIT,
	DEFENDER_TAG,
	BREATH_FAIL,
	TOWER_COMPLETE,
}

const POOL_SIZE: int = 6

var _pool: Array[GameEffect] = []
var _next_index: int = 0


func _ready() -> void:
	for _pool_index: int in range(POOL_SIZE):
		var effect: GameEffect = GameEffect.new()
		add_child(effect)
		_pool.append(effect)


func play(kind: Kind, effect_position: Vector2) -> void:
	var effect: GameEffect = _pool[_next_index]
	_next_index = (_next_index + 1) % POOL_SIZE
	match kind:
		Kind.BALL_RELEASE:
			effect.play(effect_position, GameEffect.Style.SPARKLE, Color(1.0, 0.95, 0.80, 0.9), 0.18, 0.4, 1.0)
		Kind.TOWER_IMPACT:
			effect.play(effect_position, GameEffect.Style.BURST, Color(1.0, 0.88, 0.56, 0.92), 0.28, 0.55, 1.5)
		Kind.STONE_COLLECT:
			effect.play(effect_position, GameEffect.Style.SPARKLE, Color(1.0, 0.85, 0.40, 0.95), 0.22, 0.5, 1.2)
		Kind.STONE_DEPOSIT:
			effect.play(effect_position, GameEffect.Style.RING, Color(0.60, 0.90, 0.50, 0.9), 0.24, 0.6, 1.3)
		Kind.DEFENDER_TAG:
			effect.play(effect_position, GameEffect.Style.RING, Color(0.95, 0.30, 0.25, 0.95), 0.3, 0.5, 1.6)
		Kind.BREATH_FAIL:
			effect.play(effect_position, GameEffect.Style.DUST, Color(0.60, 0.60, 0.65, 0.8), 0.35, 0.6, 1.4)
		Kind.TOWER_COMPLETE:
			effect.play(effect_position, GameEffect.Style.BURST, Color(1.0, 0.82, 0.30, 1.0), 0.5, 0.5, 1.9)


func stop_all() -> void:
	for effect: GameEffect in _pool:
		effect.stop()
