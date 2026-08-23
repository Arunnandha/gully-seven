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

const BALL_SPAWN_OFFSET: Vector2 = Vector2(60.0, -40.0)

var current_state: State = State.READY

var _ball: ThrowBall = null
var _stone_tower: StoneTower = null
var _player_controller: GullyPlayerController = null
var _stone_trail: StoneTrail = null
var _player_start_position: Vector2 = Vector2.ZERO


func setup(
	ball: ThrowBall,
	stone_tower: StoneTower,
	player_controller: GullyPlayerController,
	stone_trail: StoneTrail
) -> void:
	_ball = ball
	_stone_tower = stone_tower
	_player_controller = player_controller
	_stone_trail = stone_trail
	_player_start_position = _player_controller.global_position

	_ball.configure(_stone_tower)
	_ball.aim_started.connect(_on_ball_aim_started)
	_ball.aim_cancelled.connect(_on_ball_aim_cancelled)
	_ball.thrown.connect(_on_ball_thrown)
	_ball.hit.connect(_on_ball_hit)
	_ball.stopped.connect(_on_ball_stopped)
	_stone_tower.tower_scatter_finished.connect(_on_tower_scatter_finished)
	_stone_trail.all_stones_collected.connect(_on_all_stones_collected)

	_enter_ready()


func request_reset() -> void:
	_enter_ready()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_R:
			request_reset()


func _enter_ready() -> void:
	current_state = State.READY
	_player_controller.reset_to_start(_player_start_position)
	_stone_tower.reset_stack()
	_stone_trail.reset()
	_ball.reset_to_start(_player_controller.global_position + BALL_SPAWN_OFFSET)
	_ball.aiming_enabled = true
	_player_controller.set_movement_enabled(true)
	state_changed.emit(current_state)
	result_ready.emit("Drag from the ball to aim, release to throw")


func _on_ball_aim_started() -> void:
	if current_state != State.READY:
		return
	current_state = State.AIM
	_player_controller.set_movement_enabled(false)
	state_changed.emit(current_state)


func _on_ball_aim_cancelled() -> void:
	if current_state != State.AIM:
		return
	current_state = State.READY
	_player_controller.set_movement_enabled(true)
	state_changed.emit(current_state)


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
	current_state = State.BREAK
	state_changed.emit(current_state)
	result_ready.emit("Impact! Stones scattering...")
	_stone_tower.scatter(impact_direction, impact_speed, impact_position)


func _on_ball_stopped(was_hit: bool) -> void:
	if was_hit or current_state != State.AIM:
		return
	current_state = State.RESULT
	state_changed.emit(current_state)
	result_ready.emit("Missed — press Reset or R")


func _on_tower_scatter_finished() -> void:
	if current_state != State.BREAK:
		return
	current_state = State.RAID
	_player_controller.set_movement_enabled(true)
	state_changed.emit(current_state)
	result_ready.emit("Stones settled — collect all seven")


func _on_all_stones_collected() -> void:
	if current_state != State.RAID:
		return
	current_state = State.RETURN
	state_changed.emit(current_state)
	result_ready.emit("All seven collected — return with the stones")


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
