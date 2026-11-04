extends RefCounted

## Single entry point for loading one Sokoban level from JSON.
##
## The file shape is documented in assets/data/levels/level.schema.md.
## Invalid data is rejected with the level id in the error: the returned
## LevelData has is_valid() == false and its error names the level.

const LevelData = preload("res://src/level_data.gd")

const TILE_WALL := "#"
const TILE_FLOOR := "."

const KEY_ID := "id"
const KEY_WIDTH := "width"
const KEY_HEIGHT := "height"
const KEY_TILES := "tiles"
const KEY_GOALS := "goals"
const KEY_CRATES := "crates"
const KEY_PLAYER := "player"
const KEY_SOLUTION := "solution"

const SOLUTION_MOVES := "UDLR"
const MIN_SIZE := 5
const MAX_SIZE := 16


## Reads and validates `path`. Never returns null; check is_valid().
static func load_level(path: String) -> LevelData:
	var level := LevelData.new()
	level.id = path.get_file().get_basename()
	if path.is_empty() or not FileAccess.file_exists(path):
		return _fail(level, "file not found: %s" % path)
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return _fail(level, "invalid JSON")
	return _parse(parsed as Dictionary, level)


static func _parse(data: Dictionary, level: LevelData) -> LevelData:
	level.id = str(data.get(KEY_ID, level.id))
	if not _read_size(data, level):
		return level
	if not _read_tiles(data, level):
		return level
	if not _read_goals(data, level):
		return level
	if not _read_crates(data, level):
		return level
	if not _read_player(data, level):
		return level
	if level.crates.is_empty():
		return _fail(level, "no crates")
	if level.crates.size() != level.goals.size():
		return _fail(
			level,
			"crate count %d does not match goal count %d" % [level.crates.size(), level.goals.size()],
		)
	if not _read_solution(data, level):
		return level
	return level


static func _read_size(data: Dictionary, level: LevelData) -> bool:
	var width_value: Variant = data.get(KEY_WIDTH)
	var height_value: Variant = data.get(KEY_HEIGHT)
	if not _is_integer(width_value) or not _is_integer(height_value):
		_set_error(level, "width and height must be integers")
		return false
	level.width = int(width_value)
	level.height = int(height_value)
	if (
		level.width < MIN_SIZE
		or level.height < MIN_SIZE
		or level.width > MAX_SIZE
		or level.height > MAX_SIZE
	):
		_set_error(level, "width and height must be %d-%d cells" % [MIN_SIZE, MAX_SIZE])
		return false
	return true


static func _read_tiles(data: Dictionary, level: LevelData) -> bool:
	var tiles: Variant = data.get(KEY_TILES)
	if typeof(tiles) != TYPE_ARRAY:
		_set_error(level, "tiles must be an array of strings")
		return false
	var rows: Array = tiles as Array
	if rows.size() != level.height:
		_set_error(level, "tiles must have %d rows" % level.height)
		return false
	for y in level.height:
		var row: Variant = rows[y]
		if typeof(row) != TYPE_STRING:
			_set_error(level, "tiles row %d must be a string" % y)
			return false
		var text: String = row
		if text.length() != level.width:
			_set_error(level, "tiles row %d must be %d characters wide" % [y, level.width])
			return false
		for x in level.width:
			var tile := text[x]
			if tile == TILE_WALL:
				level.walls[Vector2i(x, y)] = true
			elif tile != TILE_FLOOR:
				_set_error(level, "tiles row %d has unknown tile '%s'" % [y, tile])
				return false
	return true


static func _read_goals(data: Dictionary, level: LevelData) -> bool:
	return _read_cell_array(data.get(KEY_GOALS), level, "goals", level.goals)


static func _read_crates(data: Dictionary, level: LevelData) -> bool:
	return _read_cell_array(data.get(KEY_CRATES), level, "crates", level.crates)


static func _read_player(data: Dictionary, level: LevelData) -> bool:
	if not data.has(KEY_PLAYER):
		_set_error(level, "no player spawn")
		return false
	var player_cells: Array[Vector2i] = []
	if not _read_cell(data[KEY_PLAYER], level, "player", player_cells):
		return false
	var player: Vector2i = player_cells[0]
	if level.crates.has(player):
		_set_error(level, "player and crate share cell %s" % _cell_text(player))
		return false
	level.player = player
	return true


## The recorded solve is part of the level contract: a level without one is a
## build error, so the loader rejects it instead of loading an unprovable level.
static func _read_solution(data: Dictionary, level: LevelData) -> bool:
	var value: Variant = data.get(KEY_SOLUTION)
	if typeof(value) != TYPE_STRING:
		_set_error(level, "solution must be a string of U/D/L/R moves")
		return false
	var text: String = value
	if text.is_empty():
		_set_error(level, "no recorded solution")
		return false
	for index in text.length():
		var move: String = text[index]
		if not SOLUTION_MOVES.contains(move):
			_set_error(level, "solution has unknown move '%s'" % move)
			return false
	level.solution = text
	return true


static func _read_cell_array(
	cells: Variant, level: LevelData, label: String, target: Array[Vector2i]
) -> bool:
	if typeof(cells) != TYPE_ARRAY:
		_set_error(level, "%s must be an array of [x, y] cells" % label)
		return false
	for entry in (cells as Array):
		if not _read_cell(entry, level, label, target):
			return false
	return true


static func _read_cell(
	value: Variant, level: LevelData, label: String, target: Array[Vector2i]
) -> bool:
	if typeof(value) != TYPE_ARRAY:
		_set_error(level, "%s entry must be an [x, y] cell" % label)
		return false
	var pair: Array = value as Array
	if pair.size() != 2 or not _is_integer(pair[0]) or not _is_integer(pair[1]):
		_set_error(level, "%s entry must be an [x, y] cell" % label)
		return false
	var cell := Vector2i(int(pair[0]), int(pair[1]))
	if cell.x < 0 or cell.y < 0 or cell.x >= level.width or cell.y >= level.height:
		_set_error(level, "%s cell %s is outside the grid" % [label, _cell_text(cell)])
		return false
	if level.walls.has(cell):
		_set_error(level, "%s cell %s is a wall" % [label, _cell_text(cell)])
		return false
	if target.has(cell):
		_set_error(level, "two %s share cell %s" % [label, _cell_text(cell)])
		return false
	target.append(cell)
	return true


static func _is_integer(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) == TYPE_FLOAT:
		var number: float = value
		return number == floor(number)
	return false


static func _cell_text(cell: Vector2i) -> String:
	return "(%d, %d)" % [cell.x, cell.y]


static func _set_error(level: LevelData, reason: String) -> void:
	level.error = "level '%s': %s" % [level.id, reason]
	push_error(level.error)


static func _fail(level: LevelData, reason: String) -> LevelData:
	_set_error(level, reason)
	return level
