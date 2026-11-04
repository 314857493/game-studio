extends Node3D

## Builds the 3D board for one level and applies the Sokoban movement rules.
##
## Implements story-001 (grid, movement, pushing) and story-002 (win, undo,
## restart) for level-001. Pause, input buffering and level sequencing are out
## of scope.

signal won(moves: int, pushes: int, seconds: float)
signal restarted()

const LevelData = preload("res://src/level_data.gd")
const LevelLoader = preload("res://src/level_loader.gd")
const SokobanModel = preload("res://src/sokoban_model.gd")
const SokobanDemo = preload("res://src/sokoban_demo.gd")

const LEVEL_PATH := "res://assets/data/levels/level-001.json"

const ACTION_UP := &"move_up"
const ACTION_DOWN := &"move_down"
const ACTION_LEFT := &"move_left"
const ACTION_RIGHT := &"move_right"
const ACTION_UNDO := &"undo"
const ACTION_RESTART := &"restart"

const HALF := 0.5
const CELL_SIZE := 1.0
const WALL_HEIGHT := 0.65
const FLOOR_THICKNESS := 0.2
const CRATE_SIZE := 0.8
const PLAYER_RADIUS := 0.28
const PLAYER_HEIGHT := 0.9
const NOSE_SIZE := 0.18
const NOSE_HEIGHT_RATIO := 0.72
const GOAL_Y := 0.04
const GOAL_INNER_RADIUS := 0.42
const GOAL_OUTER_RADIUS := 0.58
const GOAL_RINGS := 24
const GOAL_RING_SEGMENTS := 8

const CAMERA_DISTANCE := 20.0
const CAMERA_PITCH_DEGREES := 55.0
const CAMERA_YAW_DEGREES := 45.0
const CAMERA_SIZE := 12.0
const CAMERA_NEAR := 0.05
const CAMERA_FAR := 100.0
const SUN_ROTATION_DEGREES := Vector3(-55.0, -30.0, 0.0)
const SUN_ENERGY := 0.7
const AMBIENT_ENERGY := 0.28

const ROUGHNESS_FLOOR := 0.95
const ROUGHNESS_WALL := 0.85
const ROUGHNESS_CRATE := 0.55
const ROUGHNESS_PLAYER := 0.6

const COLOR_FLOOR_LIGHT := Color("cdc0a6")
const COLOR_FLOOR_DARK := Color("8b7f68")
const COLOR_WALL := Color("3a4050")
const COLOR_CRATE := Color("e0701c")
const COLOR_PLAYER := Color("2f8fdc")
const COLOR_GOAL_EMPTY := Color("49d7ff")
const COLOR_GOAL_PLACED := Color("5dff7a")
const COLOR_BACKGROUND := Color(0.06, 0.07, 0.1)
const COLOR_AMBIENT := Color(0.55, 0.6, 0.75)

@onready var _board: Node3D = $Board

var _level: LevelData
var _model: SokobanModel
var _won: bool = false
var _started_at_msec: int = 0
var _goal_nodes: Dictionary = {}
var _crate_nodes: Dictionary = {}
var _player_node: Node3D
var _floor_light: StandardMaterial3D
var _floor_dark: StandardMaterial3D
var _wall_material: StandardMaterial3D
var _crate_material: StandardMaterial3D
var _player_material: StandardMaterial3D
var _goal_empty_material: StandardMaterial3D
var _goal_placed_material: StandardMaterial3D


func _ready() -> void:
	_setup_environment()
	_setup_lighting()
	_setup_camera()
	_create_materials()
	_register_actions()
	var level: LevelData = LevelLoader.load_level(LEVEL_PATH)
	if not level.is_valid():
		push_error("playable core: %s" % level.error)
		return
	_level = level
	_model = SokobanModel.new()
	_model.setup(level)
	_started_at_msec = Time.get_ticks_msec()
	_build_board(level)
	_update_goal_rings()
	_update_player()
	var demo_mode: String = SokobanDemo.requested()
	if demo_mode == SokobanDemo.MODE_PUSHED:
		_apply_demo(SokobanDemo.pushed_moves())
	elif demo_mode == SokobanDemo.MODE_WIN:
		_apply_demo(SokobanDemo.win_moves())


func _unhandled_input(event: InputEvent) -> void:
	if _model == null:
		return
	if event is InputEventKey and (event as InputEventKey).is_echo():
		return
	if event.is_action_pressed(ACTION_RESTART):
		_restart()
		return
	if _won:
		return
	if event.is_action_pressed(ACTION_UNDO):
		_undo()
		return
	var direction := Vector2i.ZERO
	if event.is_action_pressed(ACTION_UP):
		direction = SokobanModel.DIR_UP
	elif event.is_action_pressed(ACTION_DOWN):
		direction = SokobanModel.DIR_DOWN
	elif event.is_action_pressed(ACTION_LEFT):
		direction = SokobanModel.DIR_LEFT
	elif event.is_action_pressed(ACTION_RIGHT):
		direction = SokobanModel.DIR_RIGHT
	if direction == Vector2i.ZERO:
		return
	_move(direction)


func _move(direction: Vector2i) -> void:
	var crates_before: Array = _model.crates.keys()
	var moved: bool = _model.try_move(direction)
	if moved:
		_sync_crates(crates_before)
		_update_goal_rings()
	_update_player()
	if moved and _model.is_solved():
		_win()


## Runs a fixed screenshot sequence through the normal move path. Only a demo
## mode reaches this; a normal run never applies it.
func _apply_demo(moves: Array) -> void:
	for direction in moves:
		_move(direction)


## R7: the next completed move put a crate on every goal, so lock input and
## tell the results card.
func _win() -> void:
	if _won:
		return
	_won = true
	var elapsed: float = maxf(0.0, float(Time.get_ticks_msec() - _started_at_msec) / 1000.0)
	won.emit(_model.move_count, _model.push_count, elapsed)


## R8: take the last completed move back and refresh the board.
func _undo() -> void:
	if _won:
		return
	if not _model.undo():
		return
	_rebuild_crates()
	_update_goal_rings()
	_update_player()


## R9: rebuild the level from its loaded start state and hide the card.
func _restart() -> void:
	if _level == null or _model == null:
		return
	_model.setup(_level)
	_clear_board()
	_build_board(_level)
	_update_goal_rings()
	_update_player()
	_won = false
	_started_at_msec = Time.get_ticks_msec()
	restarted.emit()


func _clear_board() -> void:
	for child in _board.get_children():
		child.free()
	_goal_nodes.clear()
	_crate_nodes.clear()
	_player_node = null


func _rebuild_crates() -> void:
	for cell in _crate_nodes.keys():
		var node: MeshInstance3D = _crate_nodes[cell]
		node.free()
	_crate_nodes.clear()
	for cell in _model.crates.keys():
		_add_crate(cell)


func _sync_crates(crates_before: Array) -> void:
	for old_cell in crates_before:
		if _model.crates.has(old_cell):
			continue
		var new_cell: Vector2i = _crate_destination(crates_before)
		if new_cell == old_cell:
			continue
		var node: MeshInstance3D = _crate_nodes[old_cell]
		_crate_nodes.erase(old_cell)
		_crate_nodes[new_cell] = node
		node.position = _cell_to_world(new_cell) + Vector3.UP * CRATE_SIZE * HALF
		return


func _crate_destination(crates_before: Array) -> Vector2i:
	for cell in _model.crates.keys():
		if not crates_before.has(cell):
			return cell
	return Vector2i(-1, -1)


func _build_board(level: LevelData) -> void:
	for y in level.height:
		for x in level.width:
			var cell := Vector2i(x, y)
			if level.walls.has(cell):
				_add_wall(cell)
			else:
				_add_floor(cell, (x + y) % 2 == 0)
	for goal in level.goals:
		_add_goal(goal)
	for crate in level.crates:
		_add_crate(crate)
	_add_player(level.player)


func _add_floor(cell: Vector2i, light: bool) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(CELL_SIZE, FLOOR_THICKNESS, CELL_SIZE)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _floor_light if light else _floor_dark
	node.position = _cell_to_world(cell) + Vector3.DOWN * FLOOR_THICKNESS * HALF
	_board.add_child(node)


func _add_wall(cell: Vector2i) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(CELL_SIZE, WALL_HEIGHT, CELL_SIZE)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _wall_material
	node.position = _cell_to_world(cell) + Vector3.UP * WALL_HEIGHT * HALF
	_board.add_child(node)


func _add_goal(cell: Vector2i) -> void:
	var mesh := TorusMesh.new()
	mesh.inner_radius = GOAL_INNER_RADIUS
	mesh.outer_radius = GOAL_OUTER_RADIUS
	mesh.rings = GOAL_RINGS
	mesh.ring_segments = GOAL_RING_SEGMENTS
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _goal_empty_material
	node.position = _cell_to_world(cell) + Vector3.UP * GOAL_Y
	_board.add_child(node)
	_goal_nodes[cell] = node


func _add_crate(cell: Vector2i) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(CRATE_SIZE, CRATE_SIZE, CRATE_SIZE)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _crate_material
	node.position = _cell_to_world(cell) + Vector3.UP * CRATE_SIZE * HALF
	_board.add_child(node)
	_crate_nodes[cell] = node


func _add_player(cell: Vector2i) -> void:
	_player_node = Node3D.new()
	_player_node.name = "Player"
	_player_node.position = _cell_to_world(cell)
	_board.add_child(_player_node)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = PLAYER_RADIUS
	capsule.height = PLAYER_HEIGHT
	body.mesh = capsule
	body.material_override = _player_material
	body.position = Vector3.UP * PLAYER_HEIGHT * HALF
	_player_node.add_child(body)
	var nose := MeshInstance3D.new()
	var nose_mesh := BoxMesh.new()
	nose_mesh.size = Vector3(NOSE_SIZE, NOSE_SIZE, NOSE_SIZE)
	nose.mesh = nose_mesh
	nose.material_override = _player_material
	nose.position = Vector3(0.0, PLAYER_HEIGHT * NOSE_HEIGHT_RATIO, -(PLAYER_RADIUS + NOSE_SIZE * HALF))
	_player_node.add_child(nose)


func _update_goal_rings() -> void:
	for goal_cell in _goal_nodes.keys():
		var node: MeshInstance3D = _goal_nodes[goal_cell]
		node.material_override = (
			_goal_placed_material if _model.crates.has(goal_cell) else _goal_empty_material
		)


func _update_player() -> void:
	_player_node.position = _cell_to_world(_model.player)
	_player_node.rotation.y = _facing_yaw(_model.facing)


func _facing_yaw(direction: Vector2i) -> float:
	return atan2(-float(direction.x), -float(direction.y))


func _cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3(
		(float(cell.x) - float(_model.width - 1) * HALF) * CELL_SIZE,
		0.0,
		(float(cell.y) - float(_model.height - 1) * HALF) * CELL_SIZE,
	)


func _setup_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = COLOR_BACKGROUND
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = COLOR_AMBIENT
	environment.ambient_light_energy = AMBIENT_ENERGY
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)


func _setup_lighting() -> void:
	var sun := get_node_or_null("Sun") as DirectionalLight3D
	if sun == null:
		return
	sun.rotation_degrees = SUN_ROTATION_DEGREES
	sun.light_energy = SUN_ENERGY
	sun.shadow_enabled = true


func _setup_camera() -> void:
	var camera := get_node_or_null("Camera") as Camera3D
	if camera == null:
		return
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = CAMERA_SIZE
	camera.near = CAMERA_NEAR
	camera.far = CAMERA_FAR
	var pitch := deg_to_rad(CAMERA_PITCH_DEGREES)
	var yaw := deg_to_rad(CAMERA_YAW_DEGREES)
	camera.position = Vector3(
		sin(yaw) * cos(pitch) * CAMERA_DISTANCE,
		sin(pitch) * CAMERA_DISTANCE,
		cos(yaw) * cos(pitch) * CAMERA_DISTANCE,
	)
	camera.look_at(Vector3.ZERO, Vector3.UP)


func _create_materials() -> void:
	_floor_light = _make_standard(COLOR_FLOOR_LIGHT, ROUGHNESS_FLOOR)
	_floor_dark = _make_standard(COLOR_FLOOR_DARK, ROUGHNESS_FLOOR)
	_wall_material = _make_standard(COLOR_WALL, ROUGHNESS_WALL)
	_crate_material = _make_standard(COLOR_CRATE, ROUGHNESS_CRATE)
	_player_material = _make_standard(COLOR_PLAYER, ROUGHNESS_PLAYER)
	_goal_empty_material = _make_glow(COLOR_GOAL_EMPTY)
	_goal_placed_material = _make_glow(COLOR_GOAL_PLACED)


func _make_standard(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _make_glow(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _register_actions() -> void:
	_add_action(ACTION_UP, [KEY_UP, KEY_W])
	_add_action(ACTION_DOWN, [KEY_DOWN, KEY_S])
	_add_action(ACTION_LEFT, [KEY_LEFT, KEY_A])
	_add_action(ACTION_RIGHT, [KEY_RIGHT, KEY_D])
	_add_action(ACTION_UNDO, [KEY_Z, KEY_U])
	_add_action(ACTION_RESTART, [KEY_R])


func _add_action(action: StringName, keys: Array) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)
