extends Node2D


const FPS_REFRESH_INTERVAL: float = 0.5

@onready var _fps_label: Label = $UI/FPSLabel

var _fps_refresh_remaining: float = 0.0


func _ready() -> void:
	_refresh_fps_label()


func _process(delta: float) -> void:
	_fps_refresh_remaining -= delta
	if _fps_refresh_remaining <= 0.0:
		_refresh_fps_label()


func _refresh_fps_label() -> void:
	_fps_refresh_remaining = FPS_REFRESH_INTERVAL
	_fps_label.text = "FPS: " + str(int(Engine.get_frames_per_second()))
