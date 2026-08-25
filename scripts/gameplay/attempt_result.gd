class_name AttemptResult
extends RefCounted


# One completed Local Challenge attempt (one player's play-through of one
# match round). Plain typed data — no logic — so MatchController and the
# comparison UI both read the exact same shape without guessing field names.

var player_name: String = ""
var score: int = 0
var elapsed_time: float = 0.0
var trips: int = 0
var tags: int = 0
var breath_failures: int = 0
var grade: ThrowBall.ThrowGrade = ThrowBall.ThrowGrade.MEDIUM
var accuracy_percent: int = 0
var stones_rebuilt: int = 0
var rank_name: String = ""


func get_grade_name() -> String:
	return ThrowBall.get_grade_name(grade)
