class_name TutorialController
extends Panel


signal skip_pressed

enum Step {
	AIM,
	BREAK,
	COLLECT,
	RETURN,
	DEFENDER,
	REBUILD,
}

const PROMPTS: Dictionary = {
	Step.AIM: "Drag from the ball to aim.",
	Step.BREAK: "Release to break the tower.",
	Step.COLLECT: "Move and collect scattered stones.",
	Step.RETURN: "Return to the circle before your breath runs out.",
	Step.DEFENDER: "Avoid the defender.",
	Step.REBUILD: "Rebuild all seven stones.",
}

@onready var _prompt_label: Label = $Margin/Content/PromptLabel
@onready var _skip_button: Button = $Margin/Content/SkipButton

var _active: bool = false
var _step: Step = Step.AIM
var _collect_notified: bool = false
var _deposit_notified: bool = false


func _ready() -> void:
	visible = false
	_skip_button.pressed.connect(_on_skip_pressed)


func start() -> void:
	_active = true
	_step = Step.AIM
	_collect_notified = false
	_deposit_notified = false
	_show_step()


func stop() -> void:
	_active = false
	visible = false


func is_active() -> bool:
	return _active


func notify_aim_started() -> void:
	_try_advance(Step.AIM)


func notify_break_started() -> void:
	_try_advance(Step.BREAK)


func notify_stone_collected() -> void:
	if not _active or _step != Step.COLLECT or _collect_notified:
		return
	_collect_notified = true
	_try_advance(Step.COLLECT)


func notify_stone_deposited() -> void:
	if not _active or _step != Step.RETURN or _deposit_notified:
		return
	_deposit_notified = true
	_try_advance(Step.RETURN)


func notify_rebuild_zone_exited() -> void:
	_try_advance(Step.DEFENDER)


func notify_round_complete() -> void:
	if not _active:
		return
	_active = false
	visible = false


func _try_advance(expected_step: Step) -> void:
	if not _active or _step != expected_step:
		return
	var next_step: Step = _get_next_step(_step)
	if next_step == _step:
		return
	_step = next_step
	_show_step()


func _get_next_step(step: Step) -> Step:
	match step:
		Step.AIM:
			return Step.BREAK
		Step.BREAK:
			return Step.COLLECT
		Step.COLLECT:
			return Step.RETURN
		Step.RETURN:
			return Step.DEFENDER
		Step.DEFENDER:
			return Step.REBUILD
		_:
			return Step.REBUILD


func _show_step() -> void:
	_prompt_label.text = PROMPTS[_step]
	visible = true


func _on_skip_pressed() -> void:
	_active = false
	visible = false
	skip_pressed.emit()
