extends RefCounted

## Campaign unlock progress for the twelve-level campaign (design R12).
##
## The highest unlocked level persists between sessions in `user://campaign.json`
## as JSON: {"version": 1, "highest_unlocked": 3}. A missing or malformed file
## starts a fresh campaign with only level 1 unlocked. Solving a level unlocks
## the next one; replaying a solved level never removes an unlock.

const LEVEL_COUNT := 12
const MIN_LEVEL := 1
const DEFAULT_PATH := "user://campaign.json"
const FORMAT_VERSION := 1
const KEY_VERSION := "version"
const KEY_HIGHEST_UNLOCKED := "highest_unlocked"

var highest_unlocked: int = MIN_LEVEL
var path: String = DEFAULT_PATH


## Loads the persisted frontier, or level 1 when the file is missing or unreadable.
func load_progress() -> void:
	highest_unlocked = MIN_LEVEL
	if not FileAccess.file_exists(path):
		return
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("campaign: ignoring malformed progress file %s" % path)
		return
	var data: Dictionary = parsed as Dictionary
	var version: Variant = data.get(KEY_VERSION, 0)
	if typeof(version) != TYPE_INT and typeof(version) != TYPE_FLOAT:
		push_warning("campaign: ignoring progress file without a version: %s" % path)
		return
	if int(version) != FORMAT_VERSION:
		push_warning("campaign: ignoring progress file version %d at %s" % [int(version), path])
		return
	var frontier: Variant = data.get(KEY_HIGHEST_UNLOCKED, MIN_LEVEL)
	if typeof(frontier) != TYPE_INT and typeof(frontier) != TYPE_FLOAT:
		push_warning("campaign: ignoring non-numeric unlock frontier in %s" % path)
		return
	highest_unlocked = _clamp_level(int(frontier))


## Writes the current frontier in the documented format. False on I/O failure.
func save_progress() -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("campaign: cannot write progress file %s" % path)
		return false
	var data: Dictionary = {
		KEY_VERSION: FORMAT_VERSION,
		KEY_HIGHEST_UNLOCKED: highest_unlocked,
	}
	file.store_string(JSON.stringify(data, "  ", false) + "\n")
	file.close()
	return true


## R12: only the frontier and everything before it can be started.
func is_unlocked(level_number: int) -> bool:
	return level_number >= MIN_LEVEL and level_number <= highest_unlocked


## Unlocks the level after `level_number`. Returns true only on a new unlock.
func mark_solved(level_number: int) -> bool:
	if not is_unlocked(level_number) or level_number >= LEVEL_COUNT:
		return false
	var next_level: int = level_number + 1
	if next_level <= highest_unlocked:
		return false
	highest_unlocked = next_level
	return true


## Test and screenshot hook: set the frontier without touching the save file.
func set_highest_unlocked(level_number: int) -> void:
	highest_unlocked = _clamp_level(level_number)


func _clamp_level(level_number: int) -> int:
	return clampi(level_number, MIN_LEVEL, LEVEL_COUNT)
