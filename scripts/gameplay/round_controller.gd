class_name RoundController
extends Node


enum State {
	READY,
	AIM,
	BREAK,
	RAID,
	RETURN,
	REBUILD,
	RESULT,
}

signal state_changed(new_state: State)
signal result_ready(message: String)
signal round_won(
	score: int,
	time_seconds: float,
	trips: int,
	tags: int,
	breath_failures: int,
	best_score: int,
	round_number: int
)

const BALL_SPAWN_OFFSET: Vector2 = Vector2(60.0, -40.0)
const DEPOSIT_INTERVAL: float = 0.28
const REBUILD_DURATION: float = 1.2

var current_state: State = State.READY

var _ball: ThrowBall = null
var _stone_tower: StoneTower = null
var _player_controller: GullyPlayerController = null
var _stone_trail: StoneTrail = null
var _rebuild_zone: RebuildZone = null
var _breath_meter: BreathMeter = null
var _defender: GullyDefender = null
var _score_manager: ScoreManager = null
var _player_start_position: Vector2 = Vector2.ZERO
var _depositing: bool = false
var _deposit_countdown: float = 0.0
var _rebuild_countdown: float = 0.0
var _trip_stone_count: int = 0
var _trip_breath_ratio: float = 1.0
var _victory_active: bool = false


func _ready() -> void:
	set_physics_process(false)


func setup(
	ball: ThrowBall,
	stone_tower: StoneTower,
	player_controller: GullyPlayerController,
	stone_trail: StoneTrail,
	rebuild_zone: RebuildZone,
	breath_meter: BreathMeter,
	defender: GullyDefender,
	score_manager: ScoreManager
) -> void:
	_ball = ball
	_stone_tower = stone_tower
	_player_controller = player_controller
	_stone_trail = stone_trail
	_rebuild_zone = rebuild_zone
	_breath_meter = breath_meter
	_defender = defender
	_score_manager = score_manager
	_player_start_position = _player_controller.global_position

	_ball.configure(_stone_tower)
	_ball.aim_started.connect(_on_ball_aim_started)
	_ball.aim_cancelled.connect(_on_ball_aim_cancelled)
	_ball.thrown.connect(_on_ball_thrown)
	_ball.hit.connect(_on_ball_hit)
	_ball.stopped.connect(_on_ball_stopped)
	_stone_tower.tower_scatter_finished.connect(_on_tower_scatter_finished)
	_stone_trail.stone_count_changed.connect(_on_carried_count_changed)
	_rebuild_zone.player_entered.connect(_on_rebuild_zone_entered)
	_rebuild_zone.player_exited.connect(_on_rebuild_zone_exited)
	_breath_meter.breath_expired.connect(_on_breath_expired)
	_defender.setup(_player_controller, _rebuild_zone)
	_defender.player_tagged.connect(_on_defender_tagged)

	_enter_ready()


func request_reset() -> void:
	if _victory_active:
		return
	_enter_ready()


func request_next_round() -> void:
	_victory_active = false
	_score_manager.advance_round()
	_enter_ready()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_R:
			request_reset()


func _physics_process(delta: float) -> void:
	if _depositing:
		_deposit_countdown -= delta
		if _deposit_countdown <= 0.0:
			_deposit_next_stone()
	elif current_state == State.REBUILD:
		_rebuild_countdown -= delta
		if _rebuild_countdown <= 0.0:
			_enter_result_success()
	else:
		set_physics_process(false)


func _change_state(new_state: State) -> void:
	current_state = new_state
	var raid_or_return: bool = new_state == State.RAID or new_state == State.RETURN
	_rebuild_zone.set_active(raid_or_return)
	_defender.set_chase_enabled(raid_or_return)
	state_changed.emit(new_state)


func _enter_ready() -> void:
	_depositing = false
	_deposit_countdown = 0.0
	_rebuild_countdown = 0.0
	_trip_stone_count = 0
	_trip_breath_ratio = 1.0
	set_physics_process(false)
	_score_manager.reset_round_stats()
	_apply_difficulty()
	_breath_meter.refill_full()
	_player_controller.reset_to_start(_player_start_position)
	_stone_tower.reset_stack()
	_stone_trail.reset()
	_ball.reset_to_start(_player_controller.global_position + BALL_SPAWN_OFFSET)
	_ball.aiming_enabled = true
	_player_controller.set_movement_enabled(true)
	_change_state(State.READY)
	result_ready.emit("Drag from the ball to aim, release to throw")


func _apply_difficulty() -> void:
	_defender.chase_speed = _score_manager.get_defender_speed()
	_defender.grace_duration = _score_manager.get_defender_grace()
	_breath_meter.breath_duration = _score_manager.get_breath_duration()


func _on_ball_aim_started() -> void:
	if current_state != State.READY:
		return
	_player_controller.set_movement_enabled(false)
	_change_state(State.AIM)


func _on_ball_aim_cancelled() -> void:
	if current_state != State.AIM:
		return
	_player_controller.set_movement_enabled(true)
	_change_state(State.READY)


func _on_ball_thrown(_direction: Vector2, _power: float) -> void:
	if current_state != State.AIM:
		return
	_ball.aiming_enabled = false
	_player_controller.set_movement_enabled(false)
	result_ready.emit("Ball in flight...")


func _on_ball_hit(
	impact_direction: Vector2,
	impact_speed: float,
	impact_position: Vector2
) -> void:
	if current_state != State.AIM:
		return
	_change_state(State.BREAK)
	result_ready.emit("Impact! Stones scattering...")
	_stone_tower.scatter(impact_direction, impact_speed, impact_position)


func _on_ball_stopped(was_hit: bool) -> void:
	if was_hit or current_state != State.AIM:
		return
	_change_state(State.RESULT)
	result_ready.emit("Missed — press Reset or R")


func _on_tower_scatter_finished() -> void:
	if current_state != State.BREAK:
		return
	_player_controller.set_movement_enabled(true)
	_score_manager.start_timer()
	_change_state(State.RAID)
	result_ready.emit("Stones settled — collect stones and return them to the circle")


func _on_carried_count_changed(count: int) -> void:
	if count <= 0:
		return
	if current_state == State.RAID:
		_change_state(State.RETURN)
		result_ready.emit("Stone secured — return to the circle, or risk grabbing more")
	if current_state == State.RETURN:
		_try_start_deposit()


func _on_rebuild_zone_entered() -> void:
	_try_start_deposit()


func _on_rebuild_zone_exited() -> void:
	_defender.start_grace()


func _on_defender_tagged() -> void:
	if current_state != State.RAID and current_state != State.RETURN:
		return

	var had_stones: bool = _stone_trail.get_carried_count() > 0
	_stone_trail.drop_all_stones()
	_player_controller.global_position = _rebuild_zone.global_position
	_player_controller.velocity = Vector2.ZERO
	_breath_meter.refill_full()
	_defender.reset_to_spawn()
	_defender.start_grace()
	_score_manager.apply_tag_penalty()
	if current_state == State.RETURN:
		_change_state(State.RAID)
	result_ready.emit(
		"Tagged! Stones dropped." if had_stones else "Tagged! Returned safely."
	)


func _try_start_deposit() -> void:
	if _depositing or current_state != State.RETURN:
		return
	if _stone_trail.get_carried_count() == 0:
		return
	if not _rebuild_zone.is_player_inside():
		return
	_depositing = true
	_trip_stone_count = _stone_trail.get_carried_count()
	_trip_breath_ratio = _breath_meter.get_ratio()
	_deposit_countdown = DEPOSIT_INTERVAL * 0.5
	set_physics_process(true)
	result_ready.emit("Depositing stones...")


func _deposit_next_stone() -> void:
	if not _rebuild_zone.is_player_inside():
		# Player stepped out mid-sequence: pause with the remaining stones
		# still carried; re-entering the circle resumes the deposit.
		_depositing = false
		return

	var piece: StonePiece = _stone_trail.pop_front_stone()
	if piece != null:
		_stone_tower.deposit_stone(piece)
		_score_manager.award_stone_deposited()

	if _stone_trail.get_carried_count() > 0:
		_deposit_countdown = DEPOSIT_INTERVAL
		return

	_depositing = false
	_breath_meter.refill_full()
	_score_manager.award_trip_completed(_trip_stone_count, _trip_breath_ratio)
	if _stone_tower.get_deposited_count() >= StoneTower.STONE_COUNT:
		_enter_rebuild()
	else:
		_change_state(State.RAID)
		result_ready.emit(
			"%d rebuilt — collect the remaining stones" % _stone_tower.get_deposited_count()
		)


func _on_breath_expired() -> void:
	if current_state != State.RAID and current_state != State.RETURN:
		return

	# Drop first so the pieces are SCATTERED before the RAID transition
	# re-arms collection, then move the player home and refill.
	_stone_trail.drop_all_stones()
	_player_controller.global_position = _rebuild_zone.global_position
	_player_controller.velocity = Vector2.ZERO
	_breath_meter.refill_full()
	_score_manager.apply_breath_failure_penalty()
	if current_state == State.RETURN:
		_change_state(State.RAID)
	result_ready.emit("Out of breath! Stones dropped — recover and raid again")


func _enter_rebuild() -> void:
	_player_controller.set_movement_enabled(false)
	_rebuild_countdown = REBUILD_DURATION
	set_physics_process(true)
	_change_state(State.REBUILD)
	result_ready.emit("All seven returned — rebuilding the tower!")


func _enter_result_success() -> void:
	set_physics_process(false)
	_player_controller.set_movement_enabled(false)
	_score_manager.stop_timer()
	_score_manager.award_completion_bonus()
	_victory_active = true
	_change_state(State.RESULT)
	result_ready.emit("Lagori! Tower rebuilt!")
	round_won.emit(
		_score_manager.score,
		_score_manager.get_elapsed_time(),
		_score_manager.get_trip_count(),
		_score_manager.get_tag_count(),
		_score_manager.get_breath_failure_count(),
		_score_manager.session_best_score,
		_score_manager.round_number
	)


func get_state_name() -> String:
	match current_state:
		State.READY:
			return "READY"
		State.AIM:
			return "AIM"
		State.BREAK:
			return "BREAK"
		State.RAID:
			return "RAID"
		State.RETURN:
			return "RETURN"
		State.REBUILD:
			return "REBUILD"
		_:
			return "RESULT"
