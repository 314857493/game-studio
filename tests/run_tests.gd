extends SceneTree

## Headless checks for the playable core (story-001), the finish/recover slice
## (story-002) and the game-feel slice (story-003).
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
const GameFlow = preload("res://src/game_flow.gd")
const HUD_SCRIPT = preload("res://src/hud.gd")

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
	_test_win_check()
	_test_undo_fidelity()
	_test_history_bound()
	_test_restart()
	_test_animation_durations()
	_test_buffer_rules()
	_test_blocked_buffered()
	_test_pause_mid_animation()
	_test_hud_values()
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


func _test_win_check() -> void:
	var level: LevelData = LevelLoader.load_level(LEVEL_PATH)
	if level == null or not level.is_valid():
		_check(false, "the --demo=win level loads")
		return
	var model := SokobanModel.new()
	model.setup(level)
	_check(not model.is_solved(), "R7: level-001 starts unsolved")
	var failures := 0
	for direction in SokobanDemo.win_moves():
		if not model.try_move(direction):
			failures += 1
	_check(failures == 0, "R7: the --demo=win solve is legal")
	_check(model.is_solved(), "R7: the --demo=win solve leaves every goal occupied")
	var placed := 0
	for goal in model.goals.keys():
		if model.crates.has(goal):
			placed += 1
	_check(placed == model.goals.size(), "R7: all three goals hold crates")
	_check(model.move_count == 21 and model.push_count == 7, "R7: the recorded solve ends at 21 moves and 7 pushes")


func _test_undo_fidelity() -> void:
	var level: LevelData = LevelLoader.load_level(LEVEL_PATH)
	if level == null or not level.is_valid():
		_check(false, "the undo level loads")
		return
	var model := SokobanModel.new()
	model.setup(level)
	var expected := SokobanModel.new()
	expected.setup(level)
	var fresh := SokobanModel.new()
	fresh.setup(level)
	var moves: Array[Vector2i] = SokobanDemo.win_moves()
	for i in 5:
		_check(model.try_move(moves[i]), "R8: setup move %d succeeds" % i)
		if i < 4:
			expected.try_move(moves[i])
	_check(model.undo(), "R8: undo restores the last completed move")
	_check(_same_state(model, expected), "R8: undo restores player, crates, counters and history depth")
	var undone := 1
	while model.undo():
		undone += 1
	_check(undone == 5, "R8: five moves can be undone")
	_check(_same_state(model, fresh), "R8: undoing every move restores the loaded start state")
	_check(model.undo() == false, "R8: undo at the start is a no-op")
	_check(_same_state(model, fresh), "R8: the no-op undo leaves the start state unchanged")


func _test_history_bound() -> void:
	var model := _make_model(5, 5, Vector2i(1, 1))
	var failures := 0
	for i in 1000:
		var direction := SokobanModel.DIR_RIGHT if i % 2 == 0 else SokobanModel.DIR_LEFT
		if not model.try_move(direction):
			failures += 1
	_check(failures == 0, "R8: the 1000-move loop is legal")
	_check(model.history_size() == 999, "R8: the undo history keeps at most 999 moves")
	var undone := 0
	while model.undo():
		undone += 1
	_check(undone == 999, "R8: undo restores the 999 retained moves")
	_check(model.player == Vector2i(2, 1) and model.move_count == 1, "R8: the dropped oldest entry leaves undo stopping at move 1")


func _test_restart() -> void:
	var level: LevelData = LevelLoader.load_level(LEVEL_PATH)
	if level == null or not level.is_valid():
		_check(false, "the restart level loads")
		return
	var model := SokobanModel.new()
	model.setup(level)
	var fresh := SokobanModel.new()
	fresh.setup(level)
	var moves: Array[Vector2i] = SokobanDemo.win_moves()
	for i in 5:
		model.try_move(moves[i])
	model.setup(level)
	_check(_same_state(model, fresh), "R9: restart returns the loaded start state")
	_check(model.history_size() == 0 and model.move_count == 0 and model.push_count == 0, "R9: restart clears the undo history and both counters")


func _test_animation_durations() -> void:
	var flow := GameFlow.new()
	_check(is_equal_approx(GameFlow.MOVE_DURATION, 0.12), "R1: a free step lasts 0.12 s")
	_check(is_equal_approx(GameFlow.PUSH_DURATION, 0.16), "R1: a push lasts 0.16 s")
	_check(is_equal_approx(GameFlow.BUMP_DURATION, 0.10), "R1: a blocked bump lasts 0.10 s")
	_check(is_equal_approx(flow.move_duration(false), 0.12), "R1: a free step uses the step duration")
	_check(is_equal_approx(flow.move_duration(true), 0.16), "R1: a push uses the push duration")


func _test_buffer_rules() -> void:
	var flow := GameFlow.new()
	_check(not flow.has_buffered(), "R11: the buffer starts empty")
	flow.buffer_move(SokobanModel.DIR_RIGHT)
	_check(flow.has_buffered(), "R11: a move buffers while one animates")
	flow.buffer_move(SokobanModel.DIR_UP)
	_check(flow.take_buffered() == SokobanModel.DIR_UP, "R11: a newer press replaces the buffered move")
	_check(not flow.has_buffered(), "R11: the buffer holds only one move")
	flow.buffer_move(SokobanModel.DIR_LEFT)
	flow.clear_buffer()
	_check(not flow.has_buffered(), "R11: the buffer can be cleared")


func _test_blocked_buffered() -> void:
	var flow := GameFlow.new()
	flow.buffer_move(SokobanModel.DIR_RIGHT)
	var model := _make_model(5, 5, Vector2i(2, 2), [], [Vector2i(3, 2)])
	var moved: bool = model.try_move(flow.take_buffered())
	_check(not moved, "R11: a blocked buffered move is refused")
	_check(
		model.player == Vector2i(2, 2) and model.move_count == 0 and model.push_count == 0,
		"R11: a blocked buffered move changes no cell and no counter",
	)
	_check(model.facing == SokobanModel.DIR_RIGHT, "R11: a blocked buffered move still turns the player")


func _test_pause_mid_animation() -> void:
	var flow := GameFlow.new()
	flow.begin_animation()
	flow.buffer_move(SokobanModel.DIR_RIGHT)
	var snapped: bool = flow.pause()
	_check(snapped, "R10: pausing during an animation snaps it to its end")
	_check(not flow.is_animating() and flow.is_paused(), "R10: the pause freezes after the snap")
	_check(not flow.has_buffered(), "R10: the pause clears the buffered move")
	flow.resume()
	_check(not flow.is_paused(), "R10: resume leaves the pause")
	var idle := GameFlow.new()
	_check(idle.pause() == false and idle.is_paused(), "R10: pause without an animation still pauses")


func _test_hud_values() -> void:
	var hud = HUD_SCRIPT.new()
	hud._on_state_changed(3, 2, 1)
	var texts: Dictionary = hud.snapshot()
	_check(texts["level"] == "Level 1", "HUD: the level number is shown")
	_check(texts["moves"] == "Moves: 3", "HUD: the move counter is shown")
	_check(texts["pushes"] == "Pushes: 2", "HUD: the push counter is shown")
	hud.free()


func _same_state(left: SokobanModel, right: SokobanModel) -> bool:
	if left.player != right.player:
		return false
	if left.move_count != right.move_count or left.push_count != right.push_count:
		return false
	if left.history_size() != right.history_size():
		return false
	if left.crates.size() != right.crates.size():
		return false
	for cell in left.crates.keys():
		if not right.crates.has(cell):
			return false
	return true


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
	_check(root.get_node_or_null("Board") is Node3D, "main scene has a Board")
	_check(root.get_node_or_null("Camera") is Camera3D, "main scene has a Camera3D")
	_check(root.get_node_or_null("HUD") is CanvasLayer, "main scene has the HUD")
	_check(root.get_node_or_null("PauseOverlay") is CanvasLayer, "main scene has the pause overlay")
	_check(root.get_node_or_null("ResultsCard") is CanvasLayer, "main scene has the results card")
	root.free()


func _test_project_settings() -> void:
	_check(ProjectSettings.get_setting("application/run/main_scene", "") == MAIN_SCENE_PATH, "main scene is registered in project.godot")
	_check(ProjectSettings.get_setting("autoload/StudioCapture", "") == "*" + CAPTURE_SCRIPT_PATH, "StudioCapture autoload points at the capture addon")
	_check(int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)) == 1152, "viewport width is 1152")
	_check(int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)) == 648, "viewport height is 648")
