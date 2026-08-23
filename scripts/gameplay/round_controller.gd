class_name RoundController
extends Node


enum State {
	READY,
	AIM,
	BREAK,
	RESULT,
}

signal state_changed(new_state: State)
signal result_ready(message: String)

const BALL_SPAWN_OFFSET: Vector2 = Vector2(60.0, -40.0)

var current_state: State = State.READY

var _ball: ThrowBall = null
var _stone_tower: StoneTower = null
var _player_controller: GullyPlayerController = null
var _last_throw_hit: bool = false


func setup(
	ball: ThrowBall,
	stone_tower: StoneTower,
	player_controller: GullyPlayerController
) -> void:
	_ball = ball
	_stone_tower = stone_tower
	_player_controller = player_controller

	_ball.configure(_stone_tower)
	_ball.aim_started.connect(_on_ball_aim_started)
	_ball.aim_cancelled.connect(_on_ball_aim_cancelled)
	_ball.thrown.connect(_on_ball_thrown)
	_ball.hit.connect(_on_ball_hit)
	_ball.stopped.connect(_on_ball_stopped)

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
	_last_throw_hit = false
	_stone_tower.reset_stack()
	_ball.reset_to_start(_player_controller.global_position + BALL_SPAWN_OFFSET)
	_ball.aiming_enabled = true
	_player_controller.set_movement_enabled(true)
	state_changed.emit(current_state)


func _on_ball_aim_started() -> void:
	current_state = State.AIM
	_player_controller.set_movement_enabled(false)
	state_changed.emit(current_state)


func _on_ball_aim_cancelled() -> void:
	current_state = State.READY
	_player_controller.set_movement_enabled(true)
	state_changed.emit(current_state)


func _on_ball_thrown(_direction: Vector2, _power: float) -> void:
	current_state = State.BREAK
	_ball.aiming_enabled = false
	state_changed.emit(current_state)


func _on_ball_hit() -> void:
	_last_throw_hit = true


func _on_ball_stopped() -> void:
	current_state = State.RESULT
	state_changed.emit(current_state)
	result_ready.emit("Tower hit!" if _last_throw_hit else "Missed — press Reset or R")
