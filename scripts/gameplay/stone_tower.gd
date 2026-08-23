class_name StoneTower
extends Node2D


const STONE_COUNT: int = 7
const BOTTOM_WIDTH: float = 118.0
const BOTTOM_HEIGHT: float = 30.0
const WIDTH_STEP: float = 11.0
const HEIGHT_STEP: float = 1.25
const STACK_SPACING: float = 20.0
const StonePieceType = preload("res://scripts/gameplay/stone_piece.gd")

@export var stone_piece_scene: PackedScene

var _pieces: Array[StonePieceType] = []


func _ready() -> void:
	_create_stone_pieces()
	reset_stack()
	set_process(false)
	set_physics_process(false)
	set_process_input(false)


func reset_stack() -> void:
	for piece: StonePieceType in _pieces:
		piece.reset_to_stack()


func get_footprint_radius() -> float:
	return BOTTOM_WIDTH * 0.5 + 12.0


func _create_stone_pieces() -> void:
	assert(stone_piece_scene != null, "StoneTower requires a StonePiece scene.")
	if not _pieces.is_empty():
		return

	for stack_index: int in range(STONE_COUNT):
		var piece: StonePieceType = stone_piece_scene.instantiate() as StonePieceType
		assert(piece != null, "StonePiece scene root must use the StonePiece script.")
		add_child(piece)
		_pieces.append(piece)
		piece.configure(
			_get_stone_size(stack_index),
			_get_stone_color(stack_index),
			stack_index,
			_get_stack_position(stack_index)
		)


func _get_stone_size(stack_index: int) -> Vector2:
	return Vector2(
		BOTTOM_WIDTH - WIDTH_STEP * stack_index,
		BOTTOM_HEIGHT - HEIGHT_STEP * stack_index
	)


func _get_stack_position(stack_index: int) -> Vector2:
	var middle_index: float = float(STONE_COUNT - 1) * 0.5
	return Vector2(0.0, (middle_index - stack_index) * STACK_SPACING)


func _get_stone_color(stack_index: int) -> Color:
	match stack_index:
		0:
			return Color(0.43, 0.29, 0.18, 1.0)
		1:
			return Color(0.52, 0.35, 0.20, 1.0)
		2:
			return Color(0.58, 0.39, 0.23, 1.0)
		3:
			return Color(0.49, 0.32, 0.24, 1.0)
		4:
			return Color(0.62, 0.44, 0.28, 1.0)
		5:
			return Color(0.55, 0.38, 0.29, 1.0)
		_:
			return Color(0.68, 0.50, 0.33, 1.0)
