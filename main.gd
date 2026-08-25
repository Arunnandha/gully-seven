extends Node2D


@export var debug_display_enabled: bool = true

const FPS_REFRESH_INTERVAL: float = 0.5
const VILLAGE_COURTYARD_THEME: ArenaTheme = preload("res://resources/themes/village_courtyard.tres")
const TEMPLE_COURTYARD_THEME: ArenaTheme = preload("res://resources/themes/temple_courtyard.tres")
const COASTAL_VILLAGE_THEME: ArenaTheme = preload("res://resources/themes/coastal_village.tres")

const THEMES: Array[ArenaTheme] = [
	VILLAGE_COURTYARD_THEME, TEMPLE_COURTYARD_THEME, COASTAL_VILLAGE_THEME,
]

const TOWER_IMPACT_SHAKE: float = 0.6
const TAG_SHAKE: float = 0.5
const COMPLETION_SHAKE: float = 0.7

const SFX_ENABLED_VOLUME: float = 0.85

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
@onready var _feedback: FeedbackManager = $FeedbackManager
@onready var _world_dim: ColorRect = $WorldDim
@onready var _breath_bar: BreathBar = $UI/BreathBar
@onready var _grade_badge: GradeBadge = $UI/GradeBadge
@onready var _result_label: Label = $UI/InstructionsPanel/Margin/Content/ResultLabel
@onready var _debug_panel: Panel = $UI/DebugPanel
@onready var _debug_label: Label = $UI/DebugPanel/Margin/DebugLabel
@onready var _carried_label: Label = $UI/TopRightPanel/Margin/Content/CarriedLabel
@onready var _rebuilt_label: Label = $UI/TopRightPanel/Margin/Content/RebuiltLabel
@onready var _round_label: Label = $UI/TopLeftPanel/Margin/Content/RoundLabel
@onready var _score_label: Label = $UI/TopLeftPanel/Margin/Content/ScoreLabel
@onready var _reset_button: Button = $UI/ResetButton
@onready var _pause_button: Button = $UI/PauseButton
@onready var _tutorial: TutorialController = $UI/TutorialPrompt
@onready var _result_overlay: ResultOverlay = $UI/ResultOverlay
@onready var _pause_menu: PauseMenu = $UI/PauseMenu
@onready var _start_screen: StartScreen = $StartLayer/StartScreen

var _fps_refresh_remaining: float = 0.0
var _carried_count: int = 0
var _rebuilt_count: int = 0
var _current_state_name: String = "READY"
var _current_theme: ArenaTheme = null
var _theme_index: int = 0
var _sfx_enabled: bool = true
var _haptics_enabled: bool = true
var _game_paused: bool = false


func _ready() -> void:
	_update_viewport_layout()
	get_viewport().size_changed.connect(_update_viewport_layout)
	_debug_panel.visible = debug_display_enabled
	_refresh_debug_label()

	_round_controller.result_ready.connect(_on_round_result_ready)
	_round_controller.state_changed.connect(_on_round_state_changed)
	_round_controller.round_won.connect(_on_round_won)
	_round_controller.ball_thrown_effect.connect(_on_ball_thrown_effect)
	_round_controller.stone_deposited_effect.connect(_on_stone_deposited_effect)
	_round_controller.player_tagged_effect.connect(_on_player_tagged_effect)
	_round_controller.breath_expired_effect.connect(_on_breath_expired_effect)
	_breath_meter.breath_warning.connect(_on_breath_warning)
	_stone_tower.tower_scatter_started.connect(_on_tower_scatter_started)
	_stone_tower.deposited_count_changed.connect(_on_deposited_count_changed)
	_stone_trail.stone_count_changed.connect(_on_stone_count_changed)
	_reset_button.pressed.connect(_on_reset_button_pressed)
	_pause_button.pressed.connect(_on_pause_button_pressed)
	_pause_menu.resume_pressed.connect(_on_pause_resume_pressed)
	_pause_menu.restart_pressed.connect(_on_pause_restart_pressed)
	_pause_menu.home_pressed.connect(_on_pause_home_pressed)
	_pause_menu.sfx_toggled.connect(_on_sfx_toggled)
	_pause_menu.haptics_toggled.connect(_on_haptics_toggled)
	_score_manager.score_changed.connect(_on_score_changed)
	_result_overlay.play_again_pressed.connect(_on_play_again_pressed)
	_rebuild_zone.player_exited.connect(_on_rebuild_zone_exited_tutorial)
	_start_screen.play_pressed.connect(_on_start_play_pressed)
	_start_screen.theme_prev_pressed.connect(_on_theme_prev_pressed)
	_start_screen.theme_next_pressed.connect(_on_theme_next_pressed)
	_start_screen.sfx_toggled.connect(_on_sfx_toggled)
	_start_screen.haptics_toggled.connect(_on_haptics_toggled)
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
	_select_theme(0)
	_on_score_changed(_score_manager.score)
	_refresh_round_label()
	_start_screen.set_sfx_enabled(true)
	_start_screen.set_haptics_enabled(_feedback.haptics_enabled)
	_gate_input_for_start_screen()
	_start_screen.show_screen()


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


func _select_theme(index: int) -> void:
	_theme_index = index
	_apply_arena_theme(THEMES[_theme_index])
	_start_screen.set_theme_name(THEMES[_theme_index].theme_name)


func _gate_input_for_start_screen() -> void:
	_player.set_movement_enabled(false)
	_throw_ball.aiming_enabled = false


func _unhandled_key_input(event: InputEvent) -> void:
	if not debug_display_enabled or not event is InputEventKey:
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_1:
			_select_theme(0)
		KEY_2:
			_select_theme(1)
		KEY_3:
			_select_theme(2)


func _on_reset_button_pressed() -> void:
	_feedback.trigger(FeedbackManager.Event.BUTTON_PRESS)
	_round_controller.request_reset()


func _go_home() -> void:
	_tutorial.stop()
	_result_overlay.hide_result()
	_world_dim.visible = false
	_round_controller.request_home()
	_gate_input_for_start_screen()
	_start_screen.show_screen()
	_pause_button.visible = false


func _on_start_play_pressed() -> void:
	_feedback.trigger(FeedbackManager.Event.BUTTON_PRESS)
	_round_controller.request_reset()
	_start_screen.hide_screen()
	_tutorial.start()
	_refresh_pause_button_visibility()


func _on_pause_button_pressed() -> void:
	_feedback.trigger(FeedbackManager.Event.BUTTON_PRESS)
	_set_paused(true)


func _on_pause_resume_pressed() -> void:
	_feedback.trigger(FeedbackManager.Event.BUTTON_PRESS)
	_set_paused(false)


func _on_pause_restart_pressed() -> void:
	_feedback.trigger(FeedbackManager.Event.BUTTON_PRESS)
	_set_paused(false)
	_round_controller.request_reset()


func _on_pause_home_pressed() -> void:
	_feedback.trigger(FeedbackManager.Event.BUTTON_PRESS)
	_set_paused(false)
	_go_home()


func _set_paused(paused: bool) -> void:
	if _game_paused == paused:
		return
	_game_paused = paused
	get_tree().paused = paused
	if paused:
		_feedback.stop_active_sounds()
		_player.clear_pointer_state()
		_pause_menu.show_menu(_sfx_enabled, _haptics_enabled)
	else:
		_pause_menu.hide_menu()
	_refresh_pause_button_visibility()


func _refresh_pause_button_visibility() -> void:
	_pause_button.visible = (
		not _start_screen.visible
		and not _game_paused
		and _round_controller.current_state != RoundController.State.RESULT
	)


func _on_theme_prev_pressed() -> void:
	_feedback.trigger(FeedbackManager.Event.BUTTON_PRESS)
	_select_theme((_theme_index - 1 + THEMES.size()) % THEMES.size())


func _on_theme_next_pressed() -> void:
	_feedback.trigger(FeedbackManager.Event.BUTTON_PRESS)
	_select_theme((_theme_index + 1) % THEMES.size())


func _on_sfx_toggled(enabled: bool) -> void:
	_sfx_enabled = enabled
	_feedback.set_sfx_volume(SFX_ENABLED_VOLUME if enabled else 0.0)
	_start_screen.set_sfx_enabled(enabled)


func _on_haptics_toggled(enabled: bool) -> void:
	_haptics_enabled = enabled
	_feedback.set_haptics_enabled(enabled)
	_start_screen.set_haptics_enabled(enabled)


func _on_rebuild_zone_exited_tutorial() -> void:
	_tutorial.notify_rebuild_zone_exited()


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
	round_number: int,
	grade_name: String,
	accuracy_percent: int,
	stones_rebuilt: int,
	rank_name: String
) -> void:
	_result_overlay.show_result(
		score,
		time_seconds,
		trips,
		tags,
		breath_failures,
		best_score,
		round_number,
		grade_name,
		accuracy_percent,
		stones_rebuilt,
		rank_name
	)
	_world_dim.visible = true
	_effect_pool.play(EffectPool.Kind.TOWER_COMPLETE, _stone_tower.global_position)
	_screen_shake.shake(COMPLETION_SHAKE)
	_feedback.trigger(FeedbackManager.Event.TOWER_COMPLETE)
	_player.play_reaction(GullyCharacterVisual.Reaction.CELEBRATE)


func _on_play_again_pressed() -> void:
	_feedback.trigger(FeedbackManager.Event.BUTTON_PRESS)
	_result_overlay.hide_result()
	_world_dim.visible = false
	_round_controller.request_next_round()


func _on_ball_thrown_effect(effect_position: Vector2) -> void:
	_effect_pool.play(EffectPool.Kind.BALL_RELEASE, effect_position)
	_feedback.trigger(FeedbackManager.Event.BALL_RELEASE)


func _on_stone_collected_effect(piece: StonePiece) -> void:
	_effect_pool.play(EffectPool.Kind.STONE_COLLECT, piece.global_position)
	_player.play_reaction(GullyCharacterVisual.Reaction.BOUNCE)
	_feedback.trigger(FeedbackManager.Event.STONE_PICKUP)


func _on_stone_deposited_effect(effect_position: Vector2) -> void:
	_effect_pool.play(EffectPool.Kind.STONE_DEPOSIT, effect_position)
	_player.play_reaction(GullyCharacterVisual.Reaction.REACH)
	_feedback.trigger(FeedbackManager.Event.STONE_DEPOSIT)
	_tutorial.notify_stone_deposited()


func _on_player_tagged_effect(effect_position: Vector2) -> void:
	_effect_pool.play(EffectPool.Kind.DEFENDER_TAG, effect_position)
	_screen_shake.shake(TAG_SHAKE)
	_feedback.trigger(FeedbackManager.Event.DEFENDER_TAG)
	_player.play_reaction(GullyCharacterVisual.Reaction.RECOIL)
	_defender.play_tag_reaction()


func _on_breath_expired_effect(effect_position: Vector2) -> void:
	_effect_pool.play(EffectPool.Kind.BREATH_FAIL, effect_position)
	_feedback.trigger(FeedbackManager.Event.BREATH_FAILURE)
	_player.play_reaction(GullyCharacterVisual.Reaction.TIRED)


func _on_breath_warning() -> void:
	_feedback.trigger(FeedbackManager.Event.BREATH_WARNING)


func _on_round_result_ready(message: String) -> void:
	_result_label.text = message


func _on_stone_count_changed(count: int) -> void:
	_carried_count = count
	_refresh_stones_labels()
	if count >= 1:
		_tutorial.notify_stone_collected()


func _on_deposited_count_changed(count: int) -> void:
	_rebuilt_count = count
	_refresh_stones_labels()
	if count >= StoneTower.STONE_COUNT:
		_tutorial.notify_round_complete()


func _refresh_stones_labels() -> void:
	_carried_label.text = "CARRIED %d" % _carried_count
	_rebuilt_label.text = "REBUILT %d/%d" % [_rebuilt_count, StoneTower.STONE_COUNT]


func _on_round_state_changed(new_state: RoundController.State) -> void:
	_current_state_name = _round_controller.get_state_name()
	var raid_or_return: bool = (
		new_state == RoundController.State.RAID or new_state == RoundController.State.RETURN
	)
	_breath_bar.set_shown(raid_or_return)
	if raid_or_return:
		# Both banners share the top-center HUD slot; the breath bar always
		# wins so a still-fading grade badge can never overlap it.
		_grade_badge.reset_badge()
	_refresh_round_label()
	_refresh_debug_label()
	if new_state != RoundController.State.RESULT:
		_result_overlay.hide_result()
		_world_dim.visible = false
	if _round_controller.current_state == RoundController.State.READY:
		_effect_pool.stop_all()
		_screen_shake.stop()
		_player.reset_visual_feedback()
		_defender.reset_visuals()
		_feedback.stop_active_sounds()
		_grade_badge.reset_badge()
	_refresh_pause_button_visibility()
	match new_state:
		RoundController.State.AIM:
			_tutorial.notify_aim_started()
		RoundController.State.BREAK:
			_tutorial.notify_break_started()


func _on_tower_scatter_started(
	impact_position: Vector2, impact_strength: float, grade: ThrowBall.ThrowGrade
) -> void:
	_effect_pool.play(
		EffectPool.Kind.TOWER_IMPACT, impact_position, lerpf(0.75, 1.35, impact_strength)
	)
	_screen_shake.shake(TOWER_IMPACT_SHAKE * lerpf(0.6, 1.2, impact_strength))
	_feedback.trigger_tower_impact(grade)
	_grade_badge.show_for_grade(grade)


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
	PlayableArea.update(viewport_size)
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
