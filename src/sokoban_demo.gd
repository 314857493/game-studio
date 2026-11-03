extends RefCounted

## Screenshot-only showcase for level-001, used only with --demo=pushed.
##
## Normal runs never call this module. The fixed sequence starts at the player
## spawn (4, 6) and is:
##   right, right: (4, 6) -> (6, 6)
##   up:           (6, 6) -> (6, 5)
##   up:           pushes crate (6, 4) -> (6, 3)
##   up:           pushes crate (6, 3) -> (6, 2), the goal
##
## The other two crates stay on floor and goals (2, 2) and (3, 7) stay empty.

const SokobanModel = preload("res://src/sokoban_model.gd")

const FLAG := "--demo=pushed"

const PUSHED_MOVES: Array[Vector2i] = [
	SokobanModel.DIR_RIGHT,
	SokobanModel.DIR_RIGHT,
	SokobanModel.DIR_UP,
	SokobanModel.DIR_UP,
	SokobanModel.DIR_UP,
]


## True only when the process was started with --demo=pushed.
static func requested() -> bool:
	for argument in OS.get_cmdline_user_args():
		if argument == FLAG:
			return true
	return false


## The fixed sequence, as a fresh array so callers cannot mutate the constant.
static func pushed_moves() -> Array[Vector2i]:
	return PUSHED_MOVES.duplicate()
