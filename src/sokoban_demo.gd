extends RefCounted

## Screenshot-only showcases for level-001, used only with --demo=pushed or
## --demo=win. Normal runs never call this module.
##
## --demo=pushed: right, right, up, up, up pushes crate (6, 4) onto goal (6, 2).
## --demo=win: the 21-move recorded solve below finishes the level; it pushes
## crate (4, 7) to goal (3, 7), crate (6, 4) to goal (6, 2), and crate (4, 4)
## to goal (2, 2).

const SokobanModel = preload("res://src/sokoban_model.gd")

const MODE_NONE := ""
const MODE_PUSHED := "pushed"
const MODE_WIN := "win"

const FLAG_PUSHED := "--demo=pushed"
const FLAG_WIN := "--demo=win"

const PUSHED_MOVES: Array[Vector2i] = [
	SokobanModel.DIR_RIGHT,
	SokobanModel.DIR_RIGHT,
	SokobanModel.DIR_UP,
	SokobanModel.DIR_UP,
	SokobanModel.DIR_UP,
]

const WIN_MOVES: Array[Vector2i] = [
	SokobanModel.DIR_RIGHT,
	SokobanModel.DIR_DOWN,
	SokobanModel.DIR_LEFT,   # pushes crate (4, 7) to goal (3, 7)
	SokobanModel.DIR_RIGHT,
	SokobanModel.DIR_RIGHT,
	SokobanModel.DIR_UP,
	SokobanModel.DIR_UP,
	SokobanModel.DIR_UP,     # pushes crate (6, 4) to (6, 3)
	SokobanModel.DIR_UP,     # pushes it to goal (6, 2)
	SokobanModel.DIR_DOWN,
	SokobanModel.DIR_DOWN,
	SokobanModel.DIR_LEFT,
	SokobanModel.DIR_LEFT,
	SokobanModel.DIR_UP,     # pushes crate (4, 4) to (4, 3)
	SokobanModel.DIR_RIGHT,
	SokobanModel.DIR_UP,
	SokobanModel.DIR_LEFT,   # pushes it to (3, 3)
	SokobanModel.DIR_LEFT,   # pushes it to (2, 3)
	SokobanModel.DIR_DOWN,
	SokobanModel.DIR_LEFT,
	SokobanModel.DIR_UP,     # pushes it to goal (2, 2)
]


## Returns MODE_PUSHED or MODE_WIN only when the matching flag is present.
static func requested() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument == FLAG_PUSHED:
			return MODE_PUSHED
		if argument == FLAG_WIN:
			return MODE_WIN
	return MODE_NONE


## The fixed sequence, as a fresh array so callers cannot mutate the constant.
static func pushed_moves() -> Array[Vector2i]:
	return PUSHED_MOVES.duplicate()


## The recorded solve, as a fresh array so callers cannot mutate the constant.
static func win_moves() -> Array[Vector2i]:
	return WIN_MOVES.duplicate()
