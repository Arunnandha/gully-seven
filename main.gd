extends Node2D


const FPS_REFRESH_INTERVAL: float = 0.5

@onready var _playground_background: ColorRect = $PlaygroundBackground
@onready var _stone_tower: Node2D = $StoneTower
@onready var _fps_label: Label = $UI/FPSLabel

var _fps_refresh_remaining: float = 0.0


func _ready() -> void:
	_update_viewport_layout()
	get_viewport().size_changed.connect(_update_viewport_layout)
	_refresh_fps_label()


func _process(delta: float) -> void:
	_fps_refresh_remaining -= delta
	if _fps_refresh_remaining <= 0.0:
		_refresh_fps_label()


func _refresh_fps_label() -> void:
	_fps_refresh_remaining = FPS_REFRESH_INTERVAL
	_fps_label.text = "FPS: " + str(int(Engine.get_frames_per_second()))


func _update_viewport_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	_playground_background.position = Vector2.ZERO
	_playground_background.size = viewport_size
	_stone_tower.position = Vector2(viewport_size.x * 0.70, viewport_size.y * 0.50)
