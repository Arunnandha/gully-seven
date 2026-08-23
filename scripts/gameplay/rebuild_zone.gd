class_name RebuildZone
extends Node2D


signal player_entered

const RADIUS: float = 96.0
const DASH_COUNT: int = 28
const DASH_FILL_RATIO: float = 0.62
const ARC_POINT_COUNT: int = 6
const LINE_WIDTH: float = 5.0
const ACTIVE_COLOR: Color = Color(1.0, 0.97, 0.88, 0.85)
const INACTIVE_COLOR: Color = Color(1.0, 0.97, 0.88, 0.28)

var _player: GullyPlayerController = null
var _active: bool = false
var _player_was_inside: bool = false


func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	set_process_input(false)


func setup(player: GullyPlayerController) -> void:
	_player = player


func set_active(active: bool) -> void:
	if _active == active:
		return
	_active = active
	_player_was_inside = false
	set_physics_process(active)
	queue_redraw()


func is_player_inside() -> bool:
	return global_position.distance_to(_player.global_position) <= RADIUS


func _physics_process(_delta: float) -> void:
	var inside: bool = is_player_inside()
	if inside and not _player_was_inside:
		player_entered.emit()
	_player_was_inside = inside


func _draw() -> void:
	var color: Color = ACTIVE_COLOR if _active else INACTIVE_COLOR
	var dash_angle: float = TAU / float(DASH_COUNT)
	for dash_index: int in range(DASH_COUNT):
		var start_angle: float = dash_angle * float(dash_index)
		draw_arc(
			Vector2.ZERO,
			RADIUS,
			start_angle,
			start_angle + dash_angle * DASH_FILL_RATIO,
			ARC_POINT_COUNT,
			color,
			LINE_WIDTH,
			true
		)
