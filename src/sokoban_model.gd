extends RefCounted

## Pure Sokoban grid state and movement rules (design R4-R9).
##
## No scene or rendering dependency: the headless tests drive it directly.

const LevelData = preload("res://src/level_data.gd")

const DIR_UP := Vector2i(0, -1)
const DIR_DOWN := Vector2i(0, 1)
const DIR_LEFT := Vector2i(-1, 0)
const DIR_RIGHT := Vector2i(1, 0)

## R8: the undo history never grows past this many completed moves.
const HISTORY_LIMIT := 999

var width: int = 0
var height: int = 0
var walls: Dictionary = {}
var goals: Dictionary = {}
var crates: Dictionary = {}
var player: Vector2i = Vector2i.ZERO
var facing: Vector2i = DIR_DOWN
var move_count: int = 0
var push_count: int = 0

var _history: Array = []


## Copies a validated level into fresh, mutable state.
func setup(level: LevelData) -> void:
	width = level.width
	height = level.height
	walls = level.walls.duplicate()
	goals = {}
	for goal in level.goals:
		goals[goal] = true
	crates = {}
	for crate in level.crates:
		crates[crate] = true
	player = level.player
	facing = DIR_DOWN
	move_count = 0
	push_count = 0
	_history.clear()


## True for walls and for cells outside the grid.
func is_wall(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
		return true
	return walls.has(cell)


## R7: true when every goal cell holds a crate.
func is_solved() -> bool:
	if goals.is_empty():
		return false
	for goal in goals.keys():
		if not crates.has(goal):
			return false
	return true


## R4/R5/R6: moves one cell, pushes one crate, or bumps and turns.
## Returns true only when the player actually changed cell. A successful move
## records the pre-move state for undo (R8).
func try_move(direction: Vector2i) -> bool:
	var previous_facing: Vector2i = facing
	facing = direction
	var target: Vector2i = player + direction
	if is_wall(target):
		return false
	if crates.has(target):
		var beyond: Vector2i = target + direction
		if is_wall(beyond) or crates.has(beyond):
			return false
		_record(previous_facing)
		crates.erase(target)
		crates[beyond] = true
		player = target
		move_count += 1
		push_count += 1
		return true
	_record(previous_facing)
	player = target
	move_count += 1
	return true


## R8: restores the state before the last completed move. False at the start.
func undo() -> bool:
	if _history.is_empty():
		return false
	var snapshot: Dictionary = _history.pop_back()
	player = snapshot["player"]
	crates = (snapshot["crates"] as Dictionary).duplicate()
	move_count = snapshot["move_count"]
	push_count = snapshot["push_count"]
	facing = snapshot["facing"]
	return true


## Number of completed moves currently available to undo.
func history_size() -> int:
	return _history.size()


func _record(previous_facing: Vector2i) -> void:
	_history.append(
		{
			"player": player,
			"crates": crates.duplicate(),
			"move_count": move_count,
			"push_count": push_count,
			"facing": previous_facing,
		}
	)
	if _history.size() > HISTORY_LIMIT:
		_history.pop_front()
