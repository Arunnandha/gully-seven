class_name ScoreManager
extends Node


signal score_changed(score: int)

const STONE_BASE_REWARD: int = 100
const BREATH_BONUS_MAX: int = 60
const MULTI_STONE_DEPOSIT_BONUS: int = 50
const COMPLETION_BONUS: int = 250
const TAG_PENALTY: int = 75
const BREATH_FAILURE_PENALTY: int = 50

const BASE_DEFENDER_SPEED: float = 265.0
const DEFENDER_SPEED_STEP: float = 12.0
const MAX_DEFENDER_SPEED: float = 340.0

const BASE_DEFENDER_GRACE: float = 1.5
const DEFENDER_GRACE_STEP: float = 0.1
const MIN_DEFENDER_GRACE: float = 0.6

const BASE_BREATH_DURATION: float = 15.0
const BREATH_DURATION_STEP: float = 0.8
const MIN_BREATH_DURATION: float = 8.0

var round_number: int = 1
var score: int = 0
var session_best_score: int = 0

var _trip_count: int = 0
var _tag_count: int = 0
var _breath_failure_count: int = 0
var _elapsed_time: float = 0.0
var _timer_running: bool = false


func _ready() -> void:
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	if _timer_running:
		_elapsed_time += delta


func reset_round_stats() -> void:
	score = 0
	_trip_count = 0
	_tag_count = 0
	_breath_failure_count = 0
	_elapsed_time = 0.0
	_timer_running = false
	set_physics_process(false)
	score_changed.emit(score)


func advance_round() -> void:
	round_number += 1


func reset_session() -> void:
	round_number = 1
	session_best_score = 0


func start_timer() -> void:
	_timer_running = true
	set_physics_process(true)


func stop_timer() -> void:
	_timer_running = false


func get_elapsed_time() -> float:
	return _elapsed_time


func get_trip_count() -> int:
	return _trip_count


func get_tag_count() -> int:
	return _tag_count


func get_breath_failure_count() -> int:
	return _breath_failure_count


func award_stone_deposited() -> void:
	_add_score(STONE_BASE_REWARD)


func award_trip_completed(stone_count: int, breath_ratio: float) -> void:
	_trip_count += 1
	var breath_bonus: int = int(round(BREATH_BONUS_MAX * clampf(breath_ratio, 0.0, 1.0)))
	_add_score(breath_bonus)
	if stone_count >= 2:
		_add_score(MULTI_STONE_DEPOSIT_BONUS)


func award_completion_bonus() -> void:
	_add_score(COMPLETION_BONUS)
	session_best_score = maxi(session_best_score, score)


func apply_tag_penalty() -> void:
	_tag_count += 1
	_remove_score(TAG_PENALTY)


func apply_breath_failure_penalty() -> void:
	_breath_failure_count += 1
	_remove_score(BREATH_FAILURE_PENALTY)


func get_defender_speed() -> float:
	return minf(
		BASE_DEFENDER_SPEED + DEFENDER_SPEED_STEP * float(round_number - 1), MAX_DEFENDER_SPEED
	)


func get_defender_grace() -> float:
	return maxf(
		BASE_DEFENDER_GRACE - DEFENDER_GRACE_STEP * float(round_number - 1), MIN_DEFENDER_GRACE
	)


func get_breath_duration() -> float:
	return maxf(
		BASE_BREATH_DURATION - BREATH_DURATION_STEP * float(round_number - 1), MIN_BREATH_DURATION
	)


func _add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)


func _remove_score(amount: int) -> void:
	score = maxi(score - amount, 0)
	score_changed.emit(score)
