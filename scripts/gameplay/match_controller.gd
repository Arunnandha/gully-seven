class_name MatchController
extends Node


# Local two-player "Same Device Challenge" orchestration.
#
# This node never touches gameplay simulation directly — it only decides
# WHEN a fresh attempt should start (by setting RoundController.round_seed
# and calling its reset) and WHAT happens to a completed attempt's numbers
# (compare, accumulate, decide the round/match winner). All scoring and
# round-reset logic stays exactly where it already lived in ScoreManager
# and RoundController; nothing here duplicates it.
#
# Solo mode never touches this node beyond leaving game_mode at SOLO, so
# Main's solo code path is completely unaffected by anything below.

enum GameMode {
	SOLO,
	LOCAL_CHALLENGE,
}

const ROUNDS_TO_WIN: int = 2
const MAX_MATCH_ROUNDS: int = 3
const DEFAULT_NAMES: Array[String] = ["Player 1", "Player 2"]

# player_index: 0/1. is_handover: true whenever this is not the very first
# attempt of the match, i.e. the device needs to change hands (or come back
# to Player 1 for a new round) before play continues. tiebreaker_number is 0
# during the three regulation rounds, then 1, 2, ... for sudden-death rounds.
signal turn_ready(
	player_index: int,
	player_name: String,
	match_round: int,
	is_handover: bool,
	tiebreaker_number: int
)
signal round_compared(
	result_a: AttemptResult, result_b: AttemptResult, winner_index: int, wins: Array[int]
)
signal match_finished(
	winner_index: int, wins: Array[int], total_scores: Array[int], best_grade_names: Array[String]
)

var game_mode: GameMode = GameMode.SOLO
var player_names: Array[String] = DEFAULT_NAMES.duplicate()

var _round_controller: RoundController = null
var _current_player_index: int = 0
var _match_round: int = 1
var _wins: Array[int] = [0, 0]
var _total_scores: Array[int] = [0, 0]
var _best_grades: Array[ThrowBall.ThrowGrade] = [
	ThrowBall.ThrowGrade.WEAK, ThrowBall.ThrowGrade.WEAK,
]
var _pending_results: Array[AttemptResult] = [null, null]
# 0 = regulation rounds 1..3; 1, 2, ... = sudden-death tie-breaker rounds.
var _tiebreaker_number: int = 0
var _match_over: bool = false
# True only between Ready being confirmed and that attempt's result being
# recorded — makes a duplicate round_won signal (or one arriving with no
# armed attempt) a no-op instead of a phantom extra result.
var _attempt_in_progress: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func setup(round_controller: RoundController) -> void:
	_round_controller = round_controller


func is_active() -> bool:
	return game_mode == GameMode.LOCAL_CHALLENGE


func get_current_player_name() -> String:
	return player_names[_current_player_index]


func get_match_round() -> int:
	return _match_round


func get_wins() -> Array[int]:
	return _wins.duplicate()


func get_tiebreaker_number() -> int:
	return _tiebreaker_number


func is_match_over() -> bool:
	return _match_over


# Starts a brand-new best-of-three match: fresh seed, fresh totals, fresh
# pending results. Used for both the initial Start Match and a Rematch.
func start_match(names: Array[String]) -> void:
	game_mode = GameMode.LOCAL_CHALLENGE
	player_names = names.duplicate()
	_wins = [0, 0]
	_total_scores = [0, 0]
	_best_grades = [ThrowBall.ThrowGrade.WEAK, ThrowBall.ThrowGrade.WEAK]
	_pending_results = [null, null]
	_match_round = 1
	_tiebreaker_number = 0
	_match_over = false
	_attempt_in_progress = false
	_current_player_index = 0
	_round_controller.round_seed = _generate_seed()
	_begin_attempt()


# Player tapped Ready on the turn overlay: (re)arm the arena with this
# match round's seed. Never advances round_number/difficulty — that stays
# pinned flat for the whole match by simply never calling
# request_next_round()/advance_round() anywhere in this file.
func confirm_player_ready() -> void:
	if _match_over or _attempt_in_progress:
		return
	_attempt_in_progress = true
	_round_controller.request_match_next_attempt()


# Called by Main once RoundController reports round_won for the attempt
# currently in progress.
func record_attempt_result(
	score: int,
	time_seconds: float,
	trips: int,
	tags: int,
	breath_failures: int,
	grade: ThrowBall.ThrowGrade,
	accuracy_percent: int,
	stones_rebuilt: int,
	rank_name: String
) -> void:
	# Ignore anything arriving after the match is decided or without an armed
	# attempt (e.g. a duplicated round_won) — one attempt, one result.
	if _match_over or not _attempt_in_progress:
		return
	_attempt_in_progress = false

	var result: AttemptResult = AttemptResult.new()
	result.player_name = get_current_player_name()
	result.score = score
	result.elapsed_time = time_seconds
	result.trips = trips
	result.tags = tags
	result.breath_failures = breath_failures
	result.grade = grade
	result.accuracy_percent = accuracy_percent
	result.stones_rebuilt = stones_rebuilt
	result.rank_name = rank_name

	_pending_results[_current_player_index] = result
	_total_scores[_current_player_index] += score
	if int(grade) > int(_best_grades[_current_player_index]):
		_best_grades[_current_player_index] = grade

	if _current_player_index == 0:
		_current_player_index = 1
		_begin_attempt()
	else:
		_finish_match_round()


# Continue button on the round-comparison screen, when the match isn't
# decided yet: fresh seed for a new round (or tie-breaker), back to Player 1.
# Regulation stops at round 3 — anything past it is a labelled tie-breaker,
# so "ROUND 4 OF 3" can never exist.
func advance_to_next_round() -> void:
	if _match_over:
		return
	if _match_round < MAX_MATCH_ROUNDS:
		_match_round += 1
	else:
		_tiebreaker_number += 1
	_current_player_index = 0
	_pending_results = [null, null]
	_round_controller.round_seed = _generate_seed()
	_begin_attempt()


func abandon_match() -> void:
	game_mode = GameMode.SOLO
	_pending_results = [null, null]
	_tiebreaker_number = 0
	_match_over = false
	_attempt_in_progress = false


# Winner determination, documented tie-break order:
# score -> time -> tags -> breath failures -> accuracy -> draw.
# Returns -1 if A wins, 1 if B wins, 0 for a draw.
static func compare_results(a: AttemptResult, b: AttemptResult) -> int:
	if a.score != b.score:
		return -1 if a.score > b.score else 1
	if a.elapsed_time != b.elapsed_time:
		return -1 if a.elapsed_time < b.elapsed_time else 1
	if a.tags != b.tags:
		return -1 if a.tags < b.tags else 1
	if a.breath_failures != b.breath_failures:
		return -1 if a.breath_failures < b.breath_failures else 1
	if a.accuracy_percent != b.accuracy_percent:
		return -1 if a.accuracy_percent > b.accuracy_percent else 1
	return 0


func _finish_match_round() -> void:
	var result_a: AttemptResult = _pending_results[0]
	var result_b: AttemptResult = _pending_results[1]
	if result_a == null or result_b == null:
		return
	var comparison: int = compare_results(result_a, result_b)
	var round_winner_index: int = -1
	if comparison < 0:
		round_winner_index = 0
		_wins[0] += 1
	elif comparison > 0:
		round_winner_index = 1
		_wins[1] += 1

	# Consumed: makes a repeated _finish_match_round call a no-op instead of
	# a second comparison/win for the same pair of attempts.
	_pending_results = [null, null]

	round_compared.emit(result_a, result_b, round_winner_index, _wins.duplicate())

	# Match-completion decision, made BEFORE any next-round handover exists:
	# - someone reached two wins -> over;
	# - a tie-breaker just produced a winner -> over;
	# - regulation round 3 done with unequal wins -> over;
	# - otherwise play on (round 2/3, or the next sudden-death tie-breaker —
	#   a drawn tie-breaker awards no win and simply forces another one).
	if _wins[0] >= ROUNDS_TO_WIN or _wins[1] >= ROUNDS_TO_WIN:
		_finish_match()
	elif _tiebreaker_number > 0:
		if comparison != 0:
			_finish_match()
	elif _match_round >= MAX_MATCH_ROUNDS and _wins[0] != _wins[1]:
		_finish_match()


func _finish_match() -> void:
	_match_over = true
	var winner_index: int = -1
	if _wins[0] > _wins[1]:
		winner_index = 0
	elif _wins[1] > _wins[0]:
		winner_index = 1
	# Must be an explicitly typed Array[String]: emitting a plain Array
	# literal here fails the typed-signal conversion, the match_finished
	# handler silently never runs, and the match can never be marked over.
	var best_grade_names: Array[String] = [
		ThrowBall.get_grade_name(_best_grades[0]), ThrowBall.get_grade_name(_best_grades[1])
	]
	match_finished.emit(
		winner_index, _wins.duplicate(), _total_scores.duplicate(), best_grade_names
	)


func _begin_attempt() -> void:
	var is_handover: bool = not (
		_match_round == 1 and _tiebreaker_number == 0 and _current_player_index == 0
	)
	turn_ready.emit(
		_current_player_index,
		get_current_player_name(),
		_match_round,
		is_handover,
		_tiebreaker_number
	)


func _generate_seed() -> int:
	return _rng.randi()
