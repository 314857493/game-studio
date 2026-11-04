extends RefCounted

## Screenshot-only showcases for level-001, used only with --demo=pushed,
## --demo=win or --demo=pause, plus the campaign level select with
## --demo=select. Normal runs never call this module.
##
## --demo=pushed: right, right, up, up, up pushes crate (6, 4) onto goal (6, 2).
## --demo=win: the 21-move recorded solve below finishes the level; it pushes
## crate (4, 7) to goal (3, 7), crate (6, 4) to goal (6, 2), and crate (4, 4)
## to goal (2, 2).
## --demo=pause: the first three solving moves put crate (4, 7) on goal (3, 7),
## then the game opens the pause overlay over that partially solved board.
## --demo=select: opens the level select with five levels unlocked and the rest
## locked, without loading a level or touching the saved campaign progress.

const SokobanModel = preload("res://src/sokoban_model.gd")

const MODE_NONE := ""
const MODE_PUSHED := "pushed"
const MODE_WIN := "win"
const MODE_PAUSE := "pause"
const MODE_SELECT := "select"

const FLAG_PUSHED := "--demo=pushed"
const FLAG_WIN := "--demo=win"
const FLAG_PAUSE := "--demo=pause"
const FLAG_SELECT := "--demo=select"

## How many levels the --demo=select frame shows as unlocked.
const SELECT_UNLOCKED_LEVELS := 5

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

const PAUSE_MOVES: Array[Vector2i] = [
	SokobanModel.DIR_RIGHT,
	SokobanModel.DIR_DOWN,
	SokobanModel.DIR_LEFT,   # pushes crate (4, 7) to goal (3, 7)
]


## Returns the requested demo mode, or MODE_NONE for a normal run.
static func requested() -> String:
	return parse(OS.get_cmdline_user_args())


## Reads the demo flag from one user-argument list; separated so the headless
## test can exercise every flag without launching the game.
static func parse(arguments: PackedStringArray) -> String:
	for argument in arguments:
		if argument == FLAG_PUSHED:
			return MODE_PUSHED
		if argument == FLAG_WIN:
			return MODE_WIN
		if argument == FLAG_PAUSE:
			return MODE_PAUSE
		if argument == FLAG_SELECT:
			return MODE_SELECT
	return MODE_NONE


## The fixed sequences, as fresh arrays so callers cannot mutate the constants.
static func pushed_moves() -> Array[Vector2i]:
	return PUSHED_MOVES.duplicate()


## The recorded solve, as a fresh array so callers cannot mutate the constant.
static func win_moves() -> Array[Vector2i]:
	return WIN_MOVES.duplicate()


## The partial solve shown behind the pause overlay.
static func pause_moves() -> Array[Vector2i]:
	return PAUSE_MOVES.duplicate()
