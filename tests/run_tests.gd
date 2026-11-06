extends SceneTree

## Headless checks for the playable core (story-001), the finish/recover slice
## (story-002), the game-feel slice (story-003), the campaign slice (story-004:
## twelve levels, recorded solutions, unlocks and level select), the overlays
## (story-005), the pause menu (story-006) and the always-visible controls legend
## (story-007).
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
const CampaignProgress = preload("res://src/campaign_progress.gd")
const Controls = preload("res://src/controls.gd")
const HUD_SCRIPT = preload("res://src/hud.gd")
const LEVEL_SELECT_SCRIPT = preload("res://src/level_select.gd")
const RESULTS_CARD_SCRIPT = preload("res://src/results_card.gd")
const PAUSE_OVERLAY_SCRIPT = preload("res://src/pause_overlay.gd")
const CONTROLS_LEGEND_SCRIPT = preload("res://src/controls_legend.gd")

const LEVEL_PATH := "res://assets/data/levels/level-001.json"
const LEVEL_DIR := "res://assets/data/levels/"
const FIXTURE_DIR := "res://tests/fixtures/"
const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const CAPTURE_SCRIPT_PATH := "res://addons/studio_capture/capture.gd"
const PROGRESS_TEST_PATH := "user://campaign_test.json"

## Readability budget from story-005: a backdrop above this alpha would hide the
## board it covers, and the board must keep at least half its brightness.
const MAX_PANEL_ALPHA := 0.5
const MAX_DIM_ALPHA := 0.25
const MIN_BOARD_VISIBILITY := 0.5

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
	_test_level_solution_contract()
	_test_campaign_levels()
	_test_level_one_board_unchanged()
	_test_unlock_boundary()
	_test_progress_persistence()
	_test_level_select_entries()
	_test_results_card_flow()
	_test_overlay_legibility()
	_test_pause_menu_buttons()
	_test_controls_legend()
	_test_demo_flags()
	_test_main_scene()
	_test_project_settings()

	# The scene test builds and frees the 3D board, so it runs after the first
	# frame; freeing renderer objects during _init leaks their RIDs at exit.
	_run_pause_menu_game_flow.call_deferred()


func _run_pause_menu_game_flow() -> void:
	await _test_pause_menu_game_flow()
	await _test_legend_on_both_screens()
	await process_frame
	await process_frame
	_finish()


func _finish() -> void:
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
	_check(not level.solution.is_empty(), "level-001 carries a recorded solution")


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


func _test_level_solution_contract() -> void:
	var missing: LevelData = LevelLoader.load_level(FIXTURE_DIR + "bad-no-solution.json")
	_check(missing != null and not missing.is_valid(), "a level without a solution is rejected")
	_check(
		missing != null and missing.error.to_lower().contains("solution"),
		"the missing-solution error names the contract",
	)
	var bad_move: LevelData = LevelLoader.load_level(FIXTURE_DIR + "bad-solution-char.json")
	_check(bad_move != null and not bad_move.is_valid(), "a solution with an unknown move is rejected")
	_check(
		bad_move != null and bad_move.error.contains("unknown move"),
		"the bad-solution error names the move",
	)


func _test_campaign_levels() -> void:
	var loaded := 0
	for level_number in range(1, CampaignProgress.LEVEL_COUNT + 1):
		var file: String = "level-%s.json" % str(level_number).pad_zeros(3)
		var level: LevelData = LevelLoader.load_level(LEVEL_DIR + file)
		_check(level != null and level.is_valid(), "%s loads and validates" % file)
		if level == null or not level.is_valid():
			continue
		loaded += 1
		_check(level.id == "level-%s" % str(level_number).pad_zeros(3), "%s keeps its id" % file)
		_check(
			level.width >= 5 and level.width <= 16 and level.height >= 5 and level.height <= 16,
			"%s is inside the 5x5-16x16 range" % file,
		)
		_check(
			level.crates.size() == level.goals.size() and not level.crates.is_empty(),
			"%s has one crate per goal" % file,
		)
		_check(not level.solution.is_empty(), "%s carries a recorded solution" % file)
		var placed := 0
		for goal in level.goals:
			if level.crates.has(goal):
				placed += 1
		_check(placed == 0, "%s starts with no crate on a goal (design R2)" % file)
		var model := SokobanModel.new()
		model.setup(level)
		_check(not model.is_solved(), "%s does not start solved" % file)
		var blocked := 0
		for direction in _solution_moves(level.solution):
			if not model.try_move(direction):
				blocked += 1
		_check(blocked == 0, "%s solution has no blocked move" % file)
		_check(model.is_solved(), "%s recorded solution solves the level" % file)
	_check(loaded == CampaignProgress.LEVEL_COUNT, "all twelve campaign level files load")


func _test_level_one_board_unchanged() -> void:
	var level: LevelData = LevelLoader.load_level(LEVEL_PATH)
	if level == null or not level.is_valid():
		_check(false, "level-001 loads for the unchanged-board check")
		return
	_check(level.width == 9 and level.height == 9, "level-001 keeps its 9x9 grid")
	var board_ok: bool = level.walls.size() == 25
	for x in level.width:
		if not level.walls.has(Vector2i(x, 0)):
			board_ok = false
	for y in range(1, level.height):
		for x in level.width:
			var expected_side_wall: bool = x == 0 or x == level.width - 1
			if level.walls.has(Vector2i(x, y)) != expected_side_wall:
				board_ok = false
	_check(board_ok, "level-001 keeps its far and side walls with the near edge open")
	var expected_goals: Array[Vector2i] = [Vector2i(2, 2), Vector2i(6, 2), Vector2i(3, 7)]
	var expected_crates: Array[Vector2i] = [Vector2i(4, 4), Vector2i(6, 4), Vector2i(4, 7)]
	_check(level.goals == expected_goals, "level-001 keeps its three goals")
	_check(level.crates == expected_crates, "level-001 keeps its three crate cells")
	_check(level.player == Vector2i(4, 6), "level-001 keeps its player spawn")


func _test_unlock_boundary() -> void:
	var progress := CampaignProgress.new()
	_check(progress.highest_unlocked == 1, "a fresh campaign starts with only level 1 unlocked")
	_check(progress.is_unlocked(1) and not progress.is_unlocked(2), "the fresh frontier is exactly level 1")
	_check(not progress.mark_solved(2), "a locked level cannot unlock the next")
	_check(progress.mark_solved(1), "solving level 1 unlocks level 2")
	_check(
		progress.highest_unlocked == 2 and progress.is_unlocked(2) and not progress.is_unlocked(3),
		"level 2 opens and level 3 stays locked",
	)
	_check(not progress.mark_solved(1), "replaying level 1 does not unlock past the frontier")
	_check(progress.highest_unlocked == 2, "replaying level 1 keeps the frontier")
	_check(progress.mark_solved(2), "solving level 2 unlocks level 3")
	_check(not progress.mark_solved(1), "replaying an old level never removes an unlock")
	_check(progress.highest_unlocked == 3, "the frontier stays at level 3")
	progress.set_highest_unlocked(CampaignProgress.LEVEL_COUNT)
	_check(
		not progress.mark_solved(CampaignProgress.LEVEL_COUNT),
		"solving the last level has no next level",
	)
	_check(
		progress.highest_unlocked == CampaignProgress.LEVEL_COUNT,
		"the last level keeps the frontier at 12",
	)


func _test_progress_persistence() -> void:
	_remove_user_file(PROGRESS_TEST_PATH)
	var progress := CampaignProgress.new()
	progress.path = PROGRESS_TEST_PATH
	progress.load_progress()
	_check(progress.highest_unlocked == 1, "a missing progress file starts at level 1")
	_check(progress.mark_solved(1), "the persistence fixture unlocks level 2")
	_check(progress.save_progress(), "progress saves to user://")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROGRESS_TEST_PATH))
	_check(typeof(parsed) == TYPE_DICTIONARY, "the progress file is JSON")
	if typeof(parsed) == TYPE_DICTIONARY:
		var data: Dictionary = parsed as Dictionary
		_check(
			int(data.get("version", 0)) == CampaignProgress.FORMAT_VERSION,
			"the progress file carries format version 1",
		)
		_check(
			int(data.get("highest_unlocked", 0)) == 2,
			"the progress file stores the frontier",
		)
	var reloaded := CampaignProgress.new()
	reloaded.path = PROGRESS_TEST_PATH
	reloaded.load_progress()
	_check(reloaded.highest_unlocked == 2, "a saved frontier loads in a new session")
	reloaded.set_highest_unlocked(9)
	_check(reloaded.save_progress(), "a later frontier saves again")
	var second := CampaignProgress.new()
	second.path = PROGRESS_TEST_PATH
	second.load_progress()
	_check(second.highest_unlocked == 9, "the second save round-trips")
	_write_user_file(PROGRESS_TEST_PATH, "{\"version\": 1, \"highest_unlocked\": 99}")
	var clamped := CampaignProgress.new()
	clamped.path = PROGRESS_TEST_PATH
	clamped.load_progress()
	_check(clamped.highest_unlocked == 12, "a frontier above 12 clamps to 12")
	_write_user_file(PROGRESS_TEST_PATH, "{\"version\": 1, \"highest_unlocked\": 0}")
	var low := CampaignProgress.new()
	low.path = PROGRESS_TEST_PATH
	low.load_progress()
	_check(low.highest_unlocked == 1, "a frontier below 1 clamps to 1")
	_write_user_file(PROGRESS_TEST_PATH, "not json")
	var corrupt := CampaignProgress.new()
	corrupt.path = PROGRESS_TEST_PATH
	corrupt.load_progress()
	_check(corrupt.highest_unlocked == 1, "a malformed progress file falls back to level 1")
	_write_user_file(PROGRESS_TEST_PATH, "{\"version\": 99, \"highest_unlocked\": 7}")
	var future := CampaignProgress.new()
	future.path = PROGRESS_TEST_PATH
	future.load_progress()
	_check(future.highest_unlocked == 1, "an unknown progress format falls back to level 1")
	_remove_user_file(PROGRESS_TEST_PATH)


func _test_level_select_entries() -> void:
	var select = LEVEL_SELECT_SCRIPT.new()
	select.present(5)
	_check(select.button_count() == CampaignProgress.LEVEL_COUNT, "the level select lists all twelve levels")
	var unlocked_ok := true
	var locked_ok := true
	for level_number in range(1, CampaignProgress.LEVEL_COUNT + 1):
		if level_number <= 5:
			if select.is_locked(level_number) or not select.button_text(level_number).contains("Unlocked"):
				unlocked_ok = false
		else:
			if not select.is_locked(level_number) or not select.button_text(level_number).contains("Locked"):
				locked_ok = false
	_check(unlocked_ok, "levels at or below the frontier show as unlocked")
	_check(locked_ok, "levels past the frontier show as locked")
	var chosen: Array = []
	select.level_chosen.connect(func(level_number: int) -> void: chosen.append(level_number))
	select._on_button_pressed(1)
	select._on_button_pressed(CampaignProgress.LEVEL_COUNT)
	_check(chosen == [1], "only an unlocked level can be started")
	select.free()


func _test_results_card_flow() -> void:
	var card = RESULTS_CARD_SCRIPT.new()
	card._on_won(21, 7, 12.5, 1)
	var solved: Dictionary = card.snapshot()
	_check(solved["title"] == "Level solved", "a solved level shows the level-solved title")
	_check(bool(solved["next_visible"]), "a solved level offers the next level")
	_check(bool(solved["select_visible"]), "the results card offers level select")
	card._on_won(95, 39, 55.0, CampaignProgress.LEVEL_COUNT)
	var finished: Dictionary = card.snapshot()
	_check(finished["title"] == "Campaign finished", "the last level shows the campaign finished")
	_check(not bool(finished["next_visible"]), "the campaign finished state has no next level")
	_check(bool(finished["select_visible"]), "the campaign finished state still offers level select")
	card.free()


## story-005: both overlays must leave the board readable behind them while
## keeping the values they showed before.
func _test_overlay_legibility() -> void:
	var card = RESULTS_CARD_SCRIPT.new()
	card._on_won(21, 7, 12.5, 1)
	var solved: Dictionary = card.snapshot()
	var card_alpha: float = solved["panel_alpha"]
	_check(card_alpha <= MAX_PANEL_ALPHA, "the results card backdrop lets the solved board read through")
	_check(
		(1.0 - card_alpha) >= MIN_BOARD_VISIBILITY,
		"the results card keeps at least half the board's brightness",
	)
	_check(solved["stats"] == "Moves: 21    Pushes: 7    Time: 12.5 s", "the results card still shows moves, pushes and time")
	card.free()

	var pause = PAUSE_OVERLAY_SCRIPT.new()
	var paused: Dictionary = pause.snapshot()
	var pause_alpha: float = paused["panel_alpha"]
	var dim_alpha: float = paused["dim_alpha"]
	_check(pause_alpha <= MAX_PANEL_ALPHA, "the pause panel lets the paused board read through")
	_check(dim_alpha <= MAX_DIM_ALPHA, "the pause scrim keeps the rest of the board readable")
	_check(
		(1.0 - pause_alpha) * (1.0 - dim_alpha) >= MIN_BOARD_VISIBILITY,
		"the paused board keeps at least half its brightness behind the panel",
	)
	_check(paused["title"] == "Paused", "the pause overlay still shows the paused title")
	_check(paused["hint"] == "Press Esc to resume", "the pause overlay still shows the resume hint")
	pause.free()


## story-006: the pause menu offers restart, resume and level select, and each
## button is keyboard-focusable and reports its intent.
func _test_pause_menu_buttons() -> void:
	var pause = PAUSE_OVERLAY_SCRIPT.new()
	var intents: Dictionary = {"restart": 0, "resume": 0, "select": 0}
	pause.restart_requested.connect(func() -> void: intents["restart"] += 1)
	pause.resume_requested.connect(func() -> void: intents["resume"] += 1)
	pause.level_select_requested.connect(func() -> void: intents["select"] += 1)
	var state: Dictionary = pause.snapshot()
	_check(state["restart"] == "Restart level", "the pause menu offers Restart level")
	_check(state["resume"] == "Resume", "the pause menu offers Resume")
	_check(state["level_select"] == "Level select", "the pause menu offers Level select")
	_check(
		float(state["min_button_height"]) >= 44.0,
		"pause menu buttons meet the 44 px target",
	)
	_check(
		state["focus_modes"] == [Control.FOCUS_ALL, Control.FOCUS_ALL, Control.FOCUS_ALL],
		"pause menu buttons are keyboard focusable",
	)
	pause._on_restart_pressed()
	pause._on_resume_pressed()
	pause._on_level_select_pressed()
	_check(intents["restart"] == 1, "the pause restart button emits restart")
	_check(intents["resume"] == 1, "the pause resume button emits resume")
	_check(intents["select"] == 1, "the pause level select button emits level select")
	pause.free()


## story-007: one set of key-name constants feeds the legend, the pause menu
## and the results card.
func _test_controls_legend() -> void:
	var rows: Array[String] = Controls.legend_rows()
	_check(rows.size() == 4, "the legend names four controls")
	_check(rows[0].ends_with(Controls.MOVE_KEYS), "the legend's move row uses the shared move keys")
	_check(rows[1].ends_with(Controls.UNDO_KEYS), "the legend's undo row uses the shared undo keys")
	_check(rows[2].ends_with(Controls.RESTART_KEY), "the legend's restart row uses the shared restart key")
	_check(rows[3].ends_with(Controls.PAUSE_KEY), "the legend's pause row uses the shared pause key")
	_check(
		rows[0].contains("Arrow keys") and rows[0].contains("WASD"),
		"the legend names arrow keys and WASD for movement",
	)
	_check(rows[1].contains("Z") and rows[1].contains("U"), "the legend names Z and U for undo")

	var legend = CONTROLS_LEGEND_SCRIPT.new()
	var state: Dictionary = legend.snapshot()
	var text: String = state["text"]
	_check(text == Controls.legend_text(), "the legend draws the shared legend text")
	for key_name in [Controls.MOVE_KEYS, Controls.UNDO_KEYS, Controls.RESTART_KEY, Controls.PAUSE_KEY]:
		_check(text.contains(key_name), "the legend names %s" % key_name)
	_check(bool(state["visible"]), "the legend is visible as soon as it is built")
	_check(
		int(state["mouse_filter"]) == Control.MOUSE_FILTER_IGNORE,
		"the legend lets clicks through to the screen behind it",
	)
	legend.free()

	var pause = PAUSE_OVERLAY_SCRIPT.new()
	var pause_hint: String = pause.snapshot()["hint"]
	_check(pause_hint == Controls.pause_hint(), "the pause menu reuses the shared pause hint")
	_check(pause_hint.contains(Controls.PAUSE_KEY), "the pause hint names the shared pause key")
	pause.free()

	var card = RESULTS_CARD_SCRIPT.new()
	card._on_won(21, 7, 12.5, 1)
	var card_hint: String = card.snapshot()["hint"]
	_check(card_hint == Controls.results_solved_hint(), "the results card reuses the shared restart hint")
	_check(card_hint.contains(Controls.RESTART_KEY), "the results hint names the shared restart key")
	card.free()


## story-006: restart and level select from the pause menu use the same game
## paths as the keyboard, and R / Esc keep working.
func _test_pause_menu_game_flow() -> void:
	var packed := load(MAIN_SCENE_PATH) as PackedScene
	if packed == null:
		_check(false, "the pause-menu scene loads")
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	var overlay: CanvasLayer = game.get_node("PauseOverlay")
	var select: CanvasLayer = game.get_node("LevelSelect")
	game._start_level(1)
	var start_player: Vector2i = game._model.player
	game._apply_demo(SokobanDemo.pause_moves())
	_check(
		game._model.move_count == 3
		and game._model.push_count == 1
		and game._model.history_size() == 3,
		"the pause-menu fixture reaches a moved board",
	)
	game._set_paused(true)
	_check(
		game._flow.is_paused() and bool(overlay.snapshot()["visible"]),
		"the pause menu opens over the paused board",
	)
	_check(overlay._resume_button.has_focus(), "the pause menu focuses a button when it opens")
	overlay._on_restart_pressed()
	_check(
		game._model.player == start_player
		and game._model.move_count == 0
		and game._model.push_count == 0,
		"restart from the pause menu resets the board and both counters",
	)
	_check(
		game._model.history_size() == 0,
		"restart from the pause menu clears the undo history",
	)
	_check(
		not game._flow.is_paused() and not bool(overlay.snapshot()["visible"]),
		"restart from the pause menu leaves the pause state",
	)

	game._apply_demo(SokobanDemo.pause_moves())
	game._set_paused(true)
	overlay._on_level_select_pressed()
	_check(
		not game._flow.is_paused() and not bool(overlay.snapshot()["visible"]),
		"level select from the pause menu leaves the pause state",
	)
	_check(game._select_open and select.visible, "level select from the pause menu opens the level select")

	game._start_level(1)
	await _press_key(game, KEY_ESCAPE)
	_check(game._flow.is_paused(), "Esc still opens the pause overlay")
	await _press_key(game, KEY_ESCAPE)
	_check(not game._flow.is_paused(), "Esc still closes the pause overlay")
	game._apply_demo(SokobanDemo.pause_moves())
	await _press_key(game, KEY_R)
	_check(
		game._model.move_count == 0 and not game._flow.is_paused(),
		"R still restarts while playing",
	)
	game._apply_demo(SokobanDemo.pause_moves())
	game._set_paused(true)
	await _press_key(game, KEY_R)
	_check(
		game._model.move_count == 0
		and not game._flow.is_paused()
		and not bool(overlay.snapshot()["visible"]),
		"R still restarts from the paused state",
	)
	game.queue_free()


## story-007: the legend is on the level select, and it stays on screen when a
## level starts and while the game is paused.
func _test_legend_on_both_screens() -> void:
	var packed := load(MAIN_SCENE_PATH) as PackedScene
	if packed == null:
		_check(false, "the legend scene loads")
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	var legend := game.get_node_or_null("ControlsLegend") as CanvasLayer
	var select := game.get_node_or_null("LevelSelect") as CanvasLayer
	_check(legend != null, "the main scene carries the controls legend")
	if legend == null or select == null:
		game.queue_free()
		return
	_check(legend.visible, "the controls legend is visible on the level select")
	_check(select.visible, "the game opens on the level select")
	_check(
		legend.layer > select.layer,
		"the legend draws above the level-select backdrop",
	)
	var pause := game.get_node_or_null("PauseOverlay") as CanvasLayer
	_check(
		pause != null and legend.layer > pause.layer,
		"the legend draws above the pause scrim",
	)
	var text: String = legend.snapshot()["text"]
	for key_name in [Controls.MOVE_KEYS, Controls.UNDO_KEYS, Controls.RESTART_KEY, Controls.PAUSE_KEY]:
		_check(text.contains(key_name), "the level-select legend names %s" % key_name)
	game._start_level(1)
	_check(
		legend.visible and not select.visible,
		"the legend stays on screen when a level starts",
	)
	_check(bool(legend.snapshot()["visible"]), "the legend is still drawn during play")
	game._set_paused(true)
	_check(game._flow.is_paused() and legend.visible, "the legend stays readable while paused")
	game._set_paused(false)
	game.queue_free()


func _make_key_event(keycode: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = true
	return event


## Sends one key press through the viewport, so the check covers the real GUI
## focus path instead of calling the game's input handler directly.
func _press_key(game: Node, keycode: int) -> void:
	game.get_viewport().push_input(_make_key_event(keycode))
	await process_frame


func _test_demo_flags() -> void:
	_check(
		SokobanDemo.parse(PackedStringArray(["--demo=select"])) == SokobanDemo.MODE_SELECT,
		"the --demo=select flag is parsed",
	)
	_check(
		SokobanDemo.parse(PackedStringArray(["--demo=win"])) == SokobanDemo.MODE_WIN,
		"the --demo=win flag is parsed",
	)
	_check(
		SokobanDemo.parse(PackedStringArray([])) == SokobanDemo.MODE_NONE,
		"a normal run has no demo mode",
	)
	_check(
		SokobanDemo.SELECT_UNLOCKED_LEVELS >= 1
		and SokobanDemo.SELECT_UNLOCKED_LEVELS < CampaignProgress.LEVEL_COUNT,
		"the select demo leaves later levels locked",
	)


func _solution_moves(solution: String) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	for index in solution.length():
		match solution[index]:
			"U":
				moves.append(SokobanModel.DIR_UP)
			"D":
				moves.append(SokobanModel.DIR_DOWN)
			"L":
				moves.append(SokobanModel.DIR_LEFT)
			"R":
				moves.append(SokobanModel.DIR_RIGHT)
	return moves


func _write_user_file(path: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_check(false, "the test could write %s" % path)
		return
	file.store_string(text)
	file.close()


func _remove_user_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


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
	var select_node := root.get_node_or_null("LevelSelect") as CanvasLayer
	_check(select_node != null, "main scene has the level select")
	var select_script: Script = select_node.get_script() if select_node != null else null
	_check(
		select_script != null and select_script.resource_path == "res://src/level_select.gd",
		"the level select runs src/level_select.gd",
	)
	root.free()


func _test_project_settings() -> void:
	_check(ProjectSettings.get_setting("application/run/main_scene", "") == MAIN_SCENE_PATH, "main scene is registered in project.godot")
	_check(ProjectSettings.get_setting("autoload/StudioCapture", "") == "*" + CAPTURE_SCRIPT_PATH, "StudioCapture autoload points at the capture addon")
	_check(int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)) == 1152, "viewport width is 1152")
	_check(int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)) == 648, "viewport height is 648")
