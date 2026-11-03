extends SceneTree

## Headless checks for the playable core (story-001).
##
## Run with:
##   godot --headless --path . -s res://tests/run_tests.gd
##
## Prints one PASS line per successful check and exits 0 only when every
## check passes; any failure exits 1.

const LevelData = preload("res://src/level_data.gd")
const LevelLoader = preload("res://src/level_loader.gd")
const SokobanModel = preload("res://src/sokoban_model.gd")
const SokobanDemo = preload("res://src/sokoban_demo.gd")

const LEVEL_PATH := "res://assets/data/levels/level-001.json"
const FIXTURE_DIR := "res://tests/fixtures/"
const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const CAPTURE_SCRIPT_PATH := "res://addons/studio_capture/capture.gd"

var _passed := 0
var _failed := 0


func _init() -> void:
	_test_valid_level()
	_test_demo_pushed()
	_test_loader_rejections()
	_test_free_move()
	_test_push()
	_test_blocked_moves()
	_test_main_scene()
	_test_project_settings()

	if _failed == 0:
		print("PASS: %d checks passed" % _passed)
		quit(0)
		return

	printerr("FAIL: %d of %d checks failed" % [_failed, _passed + _failed])
	quit(1)


func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % label)
	else:
		_failed += 1
		printerr("FAIL: %s" % label)


func _test_valid_level() -> void:
	var level: LevelData = LevelLoader.load_level(LEVEL_PATH)
	_check(level != null and level.is_valid(), "level-001 loads through the loader")
	if level == null or not level.is_valid():
		return
	_check(level.id == "level-001", "level-001 keeps its id")
	_check(level.width == 9 and level.height == 9, "level-001 is a 9x9 grid")
	_check(level.crates.size() == 3, "level-001 has three crates")
	_check(level.goals.size() == 3, "level-001 has three goals")
	_check(not level.walls.has(level.player), "level-001 spawns the player on floor")
	var placed := 0
	for goal in level.goals:
		if level.crates.has(goal):
			placed += 1
	_check(placed == 0, "level-001 starts with no crate on a goal (design R2)")
	_check(placed < level.goals.size(), "level-001 does not start solved")


func _test_demo_pushed() -> void:
	var level: LevelData = LevelLoader.load_level(LEVEL_PATH)
	_check(level != null and level.is_valid(), "the --demo=pushed level loads")
	if level == null or not level.is_valid():
		return
	var model := SokobanModel.new()
	model.setup(level)
	for direction in SokobanDemo.pushed_moves():
		_check(model.try_move(direction), "the --demo=pushed move %s succeeds" % direction)
	var placed := 0
	for goal in model.goals.keys():
		if model.crates.has(goal):
			placed += 1
	_check(placed == 1, "the --demo=pushed sequence leaves exactly one crate on a goal")
	_check(model.crates.has(Vector2i(6, 2)), "the demo crate lands on goal (6, 2)")
	_check(not model.crates.has(Vector2i(2, 2)), "goal (2, 2) stays empty after the demo")
	_check(not model.crates.has(Vector2i(3, 7)), "goal (3, 7) stays empty after the demo")
	_check(model.player == Vector2i(6, 3), "the demo player ends at (6, 3)")


func _test_loader_rejections() -> void:
	var cases := [
		["bad-count.json", "bad-count", "crate count"],
		["bad-no-player.json", "bad-no-player", "player"],
		["bad-overlap.json", "bad-overlap", "share"],
	]
	for entry in cases:
		var file: String = entry[0]
		var level_id: String = entry[1]
		var reason: String = entry[2]
		var level: LevelData = LevelLoader.load_level(FIXTURE_DIR + file)
		_check(level != null and not level.is_valid(), "%s is rejected" % file)
		_check(level != null and level.error.contains(level_id), "%s error names the level id" % file)
		_check(level != null and level.error.to_lower().contains(reason), "%s error explains the failure" % file)


func _test_free_move() -> void:
	var model := _make_model(5, 5, Vector2i(2, 2))
	_check(model.try_move(SokobanModel.DIR_RIGHT), "R4: a free move succeeds")
	_check(model.player == Vector2i(3, 2), "R4: the player moves exactly one cell right")
	_check(model.move_count == 1 and model.push_count == 0, "R4: the move counter increments and pushes stay zero")
	_check(model.facing == SokobanModel.DIR_RIGHT, "R4: the player faces the move direction")

	var goal_model := _make_model(5, 5, Vector2i(2, 2), [], [], [Vector2i(3, 2)])
	_check(goal_model.try_move(SokobanModel.DIR_RIGHT), "R4: a goal cell is walkable")
	_check(goal_model.player == Vector2i(3, 2), "R4: the player may stand on a goal")


func _test_push() -> void:
	var model := _make_model(5, 5, Vector2i(2, 2), [Vector2i(3, 2)])
	_check(model.try_move(SokobanModel.DIR_RIGHT), "R5: a push succeeds when the far cell is empty")
	_check(model.player == Vector2i(3, 2), "R5: the player enters the crate's old cell")
	_check(model.crates.has(Vector2i(4, 2)) and not model.crates.has(Vector2i(3, 2)), "R5: the crate moves exactly one cell")
	_check(model.move_count == 1 and model.push_count == 1, "R5: move and push counters each increment")


func _test_blocked_moves() -> void:
	var wall_model := _make_model(5, 5, Vector2i(2, 2), [], [Vector2i(3, 2)])
	_check(not wall_model.try_move(SokobanModel.DIR_RIGHT), "R6: moving into a wall is refused")
	_check(wall_model.player == Vector2i(2, 2), "R6: a wall leaves the player cell unchanged")
	_check(wall_model.move_count == 0 and wall_model.push_count == 0, "R6: a wall changes no counter")
	_check(wall_model.facing == SokobanModel.DIR_RIGHT, "R6: a wall still turns the player")

	var blocked_wall := _make_model(5, 5, Vector2i(2, 2), [Vector2i(3, 2)], [Vector2i(4, 2)])
	_check(not blocked_wall.try_move(SokobanModel.DIR_RIGHT), "R6: a crate pushed toward a wall is refused")
	_check(
		blocked_wall.player == Vector2i(2, 2)
		and blocked_wall.crates.has(Vector2i(3, 2))
		and blocked_wall.move_count == 0,
		"R6: a blocked push moves no cell and changes no counter",
	)

	var blocked_crate := _make_model(5, 5, Vector2i(2, 2), [Vector2i(3, 2), Vector2i(4, 2)])
	_check(not blocked_crate.try_move(SokobanModel.DIR_RIGHT), "R6: a crate pushed toward another crate is refused")
	_check(blocked_crate.crates.size() == 2 and blocked_crate.push_count == 0, "R6: a blocked crate push changes no counter")

	var edge := _make_model(5, 5, Vector2i(3, 2), [Vector2i(4, 2)])
	_check(not edge.try_move(SokobanModel.DIR_RIGHT), "R6: a crate pushed toward the grid edge is refused")
	_check(edge.player == Vector2i(3, 2) and edge.facing == SokobanModel.DIR_RIGHT, "R6: a grid edge leaves the cell but still turns")


func _make_model(width: int, height: int, player: Vector2i, crates: Array = [], walls: Array = [], goals: Array = []) -> SokobanModel:
	var level := LevelData.new()
	level.id = "test"
	level.width = width
	level.height = height
	level.player = player
	for wall in walls:
		level.walls[wall] = true
	level.goals.assign(goals)
	level.crates.assign(crates)
	var model := SokobanModel.new()
	model.setup(level)
	return model


func _test_main_scene() -> void:
	_check(ResourceLoader.exists(MAIN_SCENE_PATH), "scenes/main.tscn exists")

	var packed := load(MAIN_SCENE_PATH) as PackedScene
	_check(packed != null, "scenes/main.tscn loads as a PackedScene")
	if packed == null:
		return

	var root := packed.instantiate()
	_check(root is Node3D, "main scene root is a Node3D")
	_check(str(root.name) == "Main", "main scene root is named Main")
	var attached := root.get_script() as Script
	_check(attached != null and attached.resource_path == "res://src/game.gd", "main scene root runs src/game.gd")
	_check(root.get_node_or_null("Camera") is Camera3D, "main scene has a Camera3D")
	root.free()


func _test_project_settings() -> void:
	_check(ProjectSettings.get_setting("application/run/main_scene", "") == MAIN_SCENE_PATH, "main scene is registered in project.godot")
	_check(ProjectSettings.get_setting("autoload/StudioCapture", "") == "*" + CAPTURE_SCRIPT_PATH, "StudioCapture autoload points at the capture addon")
	_check(int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)) == 1152, "viewport width is 1152")
	_check(int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)) == 648, "viewport height is 648")
