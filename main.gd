extends Node2D


@export var debug_display_enabled: bool = true

const FPS_REFRESH_INTERVAL: float = 0.5
const VILLAGE_COURTYARD_THEME: ArenaTheme = preload("res://resources/themes/village_courtyard.tres")
const TEMPLE_COURTYARD_THEME: ArenaTheme = preload("res://resources/themes/temple_courtyard.tres")
const COASTAL_VILLAGE_THEME: ArenaTheme = preload("res://resources/themes/coastal_village.tres")

const TOWER_IMPACT_SHAKE: float = 0.6
const TAG_SHAKE: float = 0.5
const COMPLETION_SHAKE: float = 0.7

const WORLD_DIM_MARGIN: float = 40.0

# Keep useful space around the tower while retaining a right-side Lagori setup.
const TOWER_MARGIN_TARGET: float = 320.0
const TOWER_MARGIN_FLOOR: float = 40.0

@onready var _arena_backdrop: ArenaBackdrop = $BackgroundLayer/ArenaBackdrop
@onready var _rebuild_zone: RebuildZone = $RebuildZone
@onready var _stone_tower: StoneTower = $StoneTower
@onready var _player: GullyPlayerController = $Player
@onready var _throw_ball: ThrowBall = $ThrowBall
@onready var _round_controller: RoundController = $RoundController
@onready var _stone_trail: StoneTrail = $StoneTrail
@onready var _breath_meter: BreathMeter = $BreathMeter
@onready var _defender: GullyDefender = $Defender
@onready var _score_manager: ScoreManager = $ScoreManager
@onready var _effect_pool: EffectPool = $EffectPool
@onready var _screen_shake: ScreenShake = $ScreenShake
@onready var _world_dim: ColorRect = $WorldDim
@onready var _breath_bar: BreathBar = $UI/BreathBar
@onready var _controls_label: Label = $UI/MessagePanel/Margin/Content/ControlsLabel
@onready var _result_label: Label = $UI/MessagePanel/Margin/Content/ResultLabel
@onready var _debug_label: Label = $UI/MessagePanel/Margin/Content/DebugLabel
@onready var _carried_label: Label = $UI/TopRightPanel/Margin/Content/CarriedLabel
@onready var _rebuilt_label: Label = $UI/TopRightPanel/Margin/Content/RebuiltLabel
@onready var _round_label: Label = $UI/TopLeftPanel/Margin/Content/RoundLabel
@onready var _score_label: Label = $UI/TopLeftPanel/Margin/Content/ScoreLabel
@onready var _reset_button: Button = $UI/ResetButton
@onready var _result_overlay: ResultOverlay = $UI/ResultOverlay

var _fps_refresh_remaining: float = 0.0
var _carried_count: int = 0
var _rebuilt_count: int = 0
var _current_state_name: String = "READY"
var _current_theme: ArenaTheme = null


func _ready() -> void:
	_update_viewport_layout()
	get_viewport().size_changed.connect(_update_viewport_layout)
	_debug_label.visible = debug_display_enabled
	_refresh_debug_label()

	_round_controller.result_ready.connect(_on_round_result_ready)
	_round_controller.state_changed.connect(_on_round_state_changed)
	_round_controller.round_won.connect(_on_round_won)
	_round_controller.ball_thrown_effect.connect(_on_ball_thrown_effect)
	_round_controller.stone_deposited_effect.connect(_on_stone_deposited_effect)
	_round_controller.player_tagged_effect.connect(_on_player_tagged_effect)
	_round_controller.breath_expired_effect.connect(_on_breath_expired_effect)
	_stone_tower.tower_scatter_started.connect(_on_tower_scatter_started)
	_stone_tower.deposited_count_changed.connect(_on_deposited_count_changed)
	_stone_trail.stone_count_changed.connect(_on_stone_count_changed)
	_reset_button.pressed.connect(_on_reset_button_pressed)
	_score_manager.score_changed.connect(_on_score_changed)
	_result_overlay.play_again_pressed.connect(_on_play_again_pressed)
	for piece: StonePiece in _stone_tower.get_pieces():
		piece.stone_collected.connect(_on_stone_collected_effect)

	_rebuild_zone.setup(_player)
	_stone_trail.setup(_player, _stone_tower, _round_controller)
	_breath_meter.setup(_round_controller, _rebuild_zone)
	_breath_bar.setup(_breath_meter)
	_screen_shake.setup(self)
	_round_controller.setup(
		_throw_ball,
		_stone_tower,
		_player,
		_stone_trail,
		_rebuild_zone,
		_breath_meter,
		_defender,
		_score_manager
	)
	_apply_arena_theme(VILLAGE_COURTYARD_THEME)
	_on_score_changed(_score_manager.score)
	_refresh_round_label()


func _apply_arena_theme(arena_theme: ArenaTheme) -> void:
	_current_theme = arena_theme
	_arena_backdrop.setup(arena_theme)
	_rebuild_zone.apply_theme(arena_theme)
	_player.apply_theme(arena_theme)
	_throw_ball.apply_theme(arena_theme)
	_defender.apply_theme(arena_theme)
	_stone_tower.apply_theme(arena_theme)
	_breath_bar.apply_theme(arena_theme)
	_score_label.add_theme_color_override("font_color", arena_theme.panel_accent_color)
	_rebuilt_label.add_theme_color_override("font_color", arena_theme.panel_accent_color)
	_refresh_debug_label()


func _unhandled_key_input(event: InputEvent) -> void:
	if not debug_display_enabled or not event is InputEventKey:
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_1:
			_apply_arena_theme(VILLAGE_COURTYARD_THEME)
		KEY_2:
			_apply_arena_theme(TEMPLE_COURTYARD_THEME)
		KEY_3:
			_apply_arena_theme(COASTAL_VILLAGE_THEME)


func _on_reset_button_pressed() -> void:
	_round_controller.request_reset()


func _on_score_changed(score: int) -> void:
	_score_label.text = "SCORE %d" % score


func _refresh_round_label() -> void:
	_round_label.text = "ROUND %d" % _score_manager.round_number


func _on_round_won(
	score: int,
	time_seconds: float,
	trips: int,
	tags: int,
	breath_failures: int,
	best_score: int,
	round_number: int
) -> void:
	_result_overlay.show_result(score, time_seconds, trips, tags, breath_failures, best_score, round_number)
	_world_dim.visible = true
	_effect_pool.play(EffectPool.Kind.TOWER_COMPLETE, _stone_tower.global_position)
	_screen_shake.shake(COMPLETION_SHAKE)


func _on_play_again_pressed() -> void:
	_result_overlay.hide_result()
	_world_dim.visible = false
	_round_controller.request_next_round()


func _on_ball_thrown_effect(effect_position: Vector2) -> void:
	_effect_pool.play(EffectPool.Kind.BALL_RELEASE, effect_position)


func _on_stone_collected_effect(piece: StonePiece) -> void:
	_effect_pool.play(EffectPool.Kind.STONE_COLLECT, piece.global_position)
	_player.play_pulse()


func _on_stone_deposited_effect(effect_position: Vector2) -> void:
	_effect_pool.play(EffectPool.Kind.STONE_DEPOSIT, effect_position)
	_player.play_pulse()


func _on_player_tagged_effect(effect_position: Vector2) -> void:
	_effect_pool.play(EffectPool.Kind.DEFENDER_TAG, effect_position)
	_screen_shake.shake(TAG_SHAKE)


func _on_breath_expired_effect(effect_position: Vector2) -> void:
	_effect_pool.play(EffectPool.Kind.BREATH_FAIL, effect_position)


func _on_round_result_ready(message: String) -> void:
	_result_label.text = message


func _on_stone_count_changed(count: int) -> void:
	_carried_count = count
	_refresh_stones_labels()


func _on_deposited_count_changed(count: int) -> void:
	_rebuilt_count = count
	_refresh_stones_labels()


func _refresh_stones_labels() -> void:
	_carried_label.text = "CARRIED %d" % _carried_count
	_rebuilt_label.text = "REBUILT %d/%d" % [_rebuilt_count, StoneTower.STONE_COUNT]


func _on_round_state_changed(new_state: RoundController.State) -> void:
	_current_state_name = _round_controller.get_state_name()
	_controls_label.text = _get_controls_text(new_state)
	_breath_bar.set_shown(
		new_state == RoundController.State.RAID
		or new_state == RoundController.State.RETURN
	)
	_refresh_round_label()
	_refresh_debug_label()
	if new_state != RoundController.State.RESULT:
		_result_overlay.hide_result()
		_world_dim.visible = false
	if _round_controller.current_state == RoundController.State.READY:
		_effect_pool.stop_all()
		_screen_shake.stop()
		_player.reset_visual_feedback()


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
	_effect_pool.play(EffectPool.Kind.TOWER_IMPACT, impact_position)
	_screen_shake.shake(TOWER_IMPACT_SHAKE)


func _process(delta: float) -> void:
	if not debug_display_enabled:
		return
	_fps_refresh_remaining -= delta
	if _fps_refresh_remaining <= 0.0:
		_refresh_debug_label()


func _refresh_debug_label() -> void:
	if not debug_display_enabled:
		return
	_fps_refresh_remaining = FPS_REFRESH_INTERVAL
	var theme_name: String = _current_theme.theme_name if _current_theme != null else "--"
	_debug_label.text = "FPS: %d | State: %s | Theme: %s" % [
		int(Engine.get_frames_per_second()), _current_state_name, theme_name
	]


func _update_viewport_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	_arena_backdrop.set_viewport_size(viewport_size)
	_world_dim.position = -Vector2.ONE * WORLD_DIM_MARGIN
	_world_dim.size = viewport_size + Vector2.ONE * WORLD_DIM_MARGIN * 2.0

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
