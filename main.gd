extends Node2D


const FPS_REFRESH_INTERVAL: float = 0.5
const ImpactEffectType = preload("res://scripts/presentation/impact_effect.gd")

# Keep useful space around the tower while retaining a right-side Lagori setup.
const TOWER_MARGIN_TARGET: float = 320.0
const TOWER_MARGIN_FLOOR: float = 40.0

@onready var _playground_background: ColorRect = $PlaygroundBackground
@onready var _rebuild_zone: RebuildZone = $RebuildZone
@onready var _stone_tower: StoneTower = $StoneTower
@onready var _player: GullyPlayerController = $Player
@onready var _throw_ball: ThrowBall = $ThrowBall
@onready var _round_controller: RoundController = $RoundController
@onready var _stone_trail: StoneTrail = $StoneTrail
@onready var _breath_meter: BreathMeter = $BreathMeter
@onready var _breath_bar: BreathBar = $UI/BreathBar
@onready var _impact_effect: ImpactEffectType = $ImpactEffect
@onready var _fps_label: Label = $UI/FPSLabel
@onready var _controls_label: Label = $UI/ControlsLabel
@onready var _state_label: Label = $UI/StateLabel
@onready var _result_label: Label = $UI/ResultLabel
@onready var _stones_label: Label = $UI/StonesLabel
@onready var _reset_button: Button = $UI/ResetButton

var _fps_refresh_remaining: float = 0.0
var _carried_count: int = 0
var _rebuilt_count: int = 0


func _ready() -> void:
	_update_viewport_layout()
	get_viewport().size_changed.connect(_update_viewport_layout)
	_refresh_fps_label()

	_round_controller.result_ready.connect(_on_round_result_ready)
	_round_controller.state_changed.connect(_on_round_state_changed)
	_stone_tower.tower_scatter_started.connect(_on_tower_scatter_started)
	_stone_tower.deposited_count_changed.connect(_on_deposited_count_changed)
	_stone_trail.stone_count_changed.connect(_on_stone_count_changed)
	_reset_button.pressed.connect(_on_reset_button_pressed)
	_rebuild_zone.setup(_player)
	_stone_trail.setup(_player, _stone_tower, _round_controller)
	_breath_meter.setup(_round_controller, _rebuild_zone)
	_breath_bar.setup(_breath_meter)
	_round_controller.setup(
		_throw_ball, _stone_tower, _player, _stone_trail, _rebuild_zone, _breath_meter
	)


func _on_reset_button_pressed() -> void:
	_round_controller.request_reset()


func _on_round_result_ready(message: String) -> void:
	_result_label.text = message


func _on_stone_count_changed(count: int) -> void:
	_carried_count = count
	_refresh_stones_label()


func _on_deposited_count_changed(count: int) -> void:
	_rebuilt_count = count
	_refresh_stones_label()


func _refresh_stones_label() -> void:
	_stones_label.text = "Carried: %d   Rebuilt: %d/%d" % [
		_carried_count, _rebuilt_count, StoneTower.STONE_COUNT
	]


func _on_round_state_changed(new_state: RoundController.State) -> void:
	_state_label.text = "State: " + _round_controller.get_state_name()
	_controls_label.text = _get_controls_text(new_state)
	_breath_bar.set_shown(
		new_state == RoundController.State.RAID
		or new_state == RoundController.State.RETURN
	)
	if _round_controller.current_state == RoundController.State.READY:
		_impact_effect.stop()


func _get_controls_text(state: RoundController.State) -> String:
	match state:
		RoundController.State.READY:
			return "Drag from the ball to aim | Drag elsewhere or WASD to move"
		RoundController.State.AIM:
			return "Release to throw | Short drag cancels"
		RoundController.State.BREAK:
			return "Stones scattering..."
		RoundController.State.RAID, RoundController.State.RETURN:
			return "Touch or left-drag to move | WASD / arrow keys"
		RoundController.State.REBUILD:
			return "Tower rebuilding..."
		_:
			return "Press Reset or R"


func _on_tower_scatter_started(impact_position: Vector2) -> void:
	_impact_effect.play_at(impact_position)


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

	var horizontal_margin: float = clampf(
		minf(TOWER_MARGIN_TARGET, viewport_size.x * 0.5), TOWER_MARGIN_FLOOR, viewport_size.x * 0.5
	)
	var vertical_margin: float = clampf(
		minf(TOWER_MARGIN_TARGET, viewport_size.y * 0.5), TOWER_MARGIN_FLOOR, viewport_size.y * 0.5
	)
	var tower_x: float = clampf(viewport_size.x * 0.62, horizontal_margin, viewport_size.x - horizontal_margin)
	var tower_y: float = clampf(viewport_size.y * 0.5, vertical_margin, viewport_size.y - vertical_margin)
	_stone_tower.position = Vector2(tower_x, tower_y)
	_rebuild_zone.position = _stone_tower.position
