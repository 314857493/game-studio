extends RefCounted

## Parsed Sokoban level. Built by level_loader.gd; invalid data carries `error`.
##
## walls, goals, crates and player are in grid cells: x grows right, y grows
## away from the camera (screen up), origin at the top-left cell.

var id: String = ""
var width: int = 0
var height: int = 0
var walls: Dictionary = {}
var goals: Array[Vector2i] = []
var crates: Array[Vector2i] = []
var player: Vector2i = Vector2i.ZERO
## Recorded solve as a string of U/D/L/R moves; replayed by the build check.
var solution: String = ""
var error: String = ""


## True when the loader accepted the level.
func is_valid() -> bool:
	return error.is_empty()
