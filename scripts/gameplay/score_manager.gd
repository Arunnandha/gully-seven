class_name ScoreManager
extends Node


signal score_changed(score: int)

enum Rank {
	BRONZE,
	SILVER,
	GOLD,
	PERFECT_RANK,
}

const STONE_BASE_REWARD: int = 100
const BREATH_BONUS_MAX: int = 60
const MULTI_STONE_DEPOSIT_BONUS: int = 50
const COMPLETION_BONUS: int = 250
const TAG_PENALTY: int = 75
const BREATH_FAILURE_PENALTY: int = 50

# Throw-grade multiplier: applies to the score components that scale with
# how the round was played (stone/trip/completion rewards), while
# achievement bonuses below (fast/no-tag/no-breath-fail) stay flat for every
# grade so clean play is always worth the same regardless of throw choice.
const GRADE_MULTIPLIER_WEAK: float = 0.7
const GRADE_MULTIPLIER_MEDIUM: float = 1.0
const GRADE_MULTIPLIER_STRONG: float = 1.25
const GRADE_MULTIPLIER_PERFECT: float = 1.5
const IMPACT_ACCURACY_BONUS_MAX: int = 80

const FAST_COMPLETION_BONUS_MAX: int = 120
const FAST_COMPLETION_TARGET_TIME: float = 18.0
const FAST_COMPLETION_MAX_TIME: float = 45.0
const NO_TAG_BONUS: int = 100
const NO_BREATH_FAILURE_BONUS: int = 80

const EXCESS_TRIP_THRESHOLD: int = 4
const EXCESS_TRIP_PENALTY: int = 15
# Reserved for a future retry-after-miss mode — a miss today always forces a
# full round reset (which already zeroes score), so this is not yet called.
const MISSED_THROW_PENALTY: int = 30

const RANK_SILVER_SCORE: int = 700
const RANK_GOLD_SCORE: int = 1100

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
var _miss_count: int = 0
var _elapsed_time: float = 0.0
var _timer_running: bool = false
var _throw_grade: ThrowBall.ThrowGrade = ThrowBall.ThrowGrade.MEDIUM
var _grade_multiplier: float = GRADE_MULTIPLIER_MEDIUM
var _impact_accuracy: float = 0.0


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
	_miss_count = 0
	_elapsed_time = 0.0
	_timer_running = false
	_throw_grade = ThrowBall.ThrowGrade.MEDIUM
	_grade_multiplier = GRADE_MULTIPLIER_MEDIUM
	_impact_accuracy = 0.0
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


func get_miss_count() -> int:
	return _miss_count


func get_throw_grade() -> ThrowBall.ThrowGrade:
	return _throw_grade


func get_grade_multiplier() -> float:
	return _grade_multiplier


func get_impact_accuracy() -> float:
	return _impact_accuracy


# Scores exactly once per round: the ball can only strike the tower once
# before the round moves past AIM, and a reset wipes round stats entirely.
func apply_throw_grade(grade: ThrowBall.ThrowGrade, accuracy: float) -> void:
	_throw_grade = grade
	_grade_multiplier = _get_grade_multiplier(grade)
	_impact_accuracy = clampf(accuracy, 0.0, 1.0)
	_add_score(int(round(IMPACT_ACCURACY_BONUS_MAX * _impact_accuracy)))


func award_stone_deposited() -> void:
	_add_score(int(round(STONE_BASE_REWARD * _grade_multiplier)))


func award_trip_completed(stone_count: int, breath_ratio: float) -> void:
	_trip_count += 1
	var breath_bonus: int = int(round(BREATH_BONUS_MAX * clampf(breath_ratio, 0.0, 1.0)))
	_add_score(breath_bonus)
	if stone_count >= 2:
		_add_score(int(round(MULTI_STONE_DEPOSIT_BONUS * _grade_multiplier)))


# Every completion-only line item (fast time, clean-run bonuses, excess-trip
# penalty) is evaluated here, exactly once, from the round's final counters.
func award_completion_bonus() -> void:
	_add_score(int(round(COMPLETION_BONUS * _grade_multiplier)))
	_add_score(_get_fast_completion_bonus())
	if _tag_count == 0:
		_add_score(NO_TAG_BONUS)
	if _breath_failure_count == 0:
		_add_score(NO_BREATH_FAILURE_BONUS)
	var excess_trips: int = maxi(_trip_count - EXCESS_TRIP_THRESHOLD, 0)
	if excess_trips > 0:
		_remove_score(excess_trips * EXCESS_TRIP_PENALTY)
	session_best_score = maxi(session_best_score, score)


func apply_tag_penalty() -> void:
	_tag_count += 1
	_remove_score(TAG_PENALTY)


func apply_breath_failure_penalty() -> void:
	_breath_failure_count += 1
	_remove_score(BREATH_FAILURE_PENALTY)


# Reserved for a future retry-after-miss mode; see MISSED_THROW_PENALTY.
func apply_missed_throw_penalty() -> void:
	_miss_count += 1
	_remove_score(MISSED_THROW_PENALTY)


func get_rank() -> Rank:
	if score >= RANK_GOLD_SCORE and _tag_count == 0 and _breath_failure_count == 0:
		return Rank.PERFECT_RANK
	if score >= RANK_GOLD_SCORE:
		return Rank.GOLD
	if score >= RANK_SILVER_SCORE:
		return Rank.SILVER
	return Rank.BRONZE


static func get_rank_name(rank: Rank) -> String:
	match rank:
		Rank.PERFECT_RANK:
			return "PERFECT"
		Rank.GOLD:
			return "GOLD"
		Rank.SILVER:
			return "SILVER"
		_:
			return "BRONZE"


static func _get_grade_multiplier(grade: ThrowBall.ThrowGrade) -> float:
	match grade:
		ThrowBall.ThrowGrade.WEAK:
			return GRADE_MULTIPLIER_WEAK
		ThrowBall.ThrowGrade.STRONG:
			return GRADE_MULTIPLIER_STRONG
		ThrowBall.ThrowGrade.PERFECT:
			return GRADE_MULTIPLIER_PERFECT
		_:
			return GRADE_MULTIPLIER_MEDIUM


func _get_fast_completion_bonus() -> int:
	if _elapsed_time <= FAST_COMPLETION_TARGET_TIME:
		return FAST_COMPLETION_BONUS_MAX
	if _elapsed_time >= FAST_COMPLETION_MAX_TIME:
		return 0
	var t: float = (
		1.0
		- (_elapsed_time - FAST_COMPLETION_TARGET_TIME)
		/ (FAST_COMPLETION_MAX_TIME - FAST_COMPLETION_TARGET_TIME)
	)
	return int(round(FAST_COMPLETION_BONUS_MAX * t))


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
