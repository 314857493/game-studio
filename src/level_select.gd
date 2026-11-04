extends CanvasLayer

## Level-select screen for the twelve-level campaign (story-004, design R12).
##
## It owns no game state: the game sends the current unlock frontier through
## `level_select_opened`, and this screen emits `level_chosen` only for an
## unlocked entry. All twelve levels are listed; locked entries are disabled and
## labelled so the state is readable in a screenshot.

signal level_chosen(level_number: int)

const CampaignProgress = preload("res://src/campaign_progress.gd")

const TITLE_TEXT := "Select a level"
const UNLOCKED_FORMAT := "Level %d — Unlocked"
const LOCKED_FORMAT := "Level %d — Locked"
const HINT_TEXT := "Only unlocked levels can be started"
const COLUMNS := 4

const TITLE_FONT_SIZE := 32
const BUTTON_FONT_SIZE := 18
const HINT_FONT_SIZE := 16
const TITLE_VARIATION := &"LevelSelectTitle"
const HINT_VARIATION := &"LevelSelectHint"

const BUTTON_MIN_SIZE := Vector2(190.0, 56.0)
const PANEL_MIN_SIZE := Vector2(900.0, 420.0)
const PANEL_MARGIN := 28
const BOX_SEPARATION := 20
const GRID_SEPARATION := 14
const PANEL_CORNER_RADIUS := 12
const PANEL_BORDER_WIDTH := 2
const BUTTON_CORNER_RADIUS := 8

const BACKDROP_COLOR := Color(0.05, 0.06, 0.09)
const PANEL_COLOR := Color(0.08, 0.09, 0.13)
const PANEL_BORDER_COLOR := Color("49d7ff")
const BUTTON_COLOR := Color("1b2230")
const BUTTON_HOVER_COLOR := Color("283447")
const BUTTON_PRESSED_COLOR := Color("10151f")
const BUTTON_DISABLED_COLOR := Color("12161e")
const TEXT_COLOR := Color("edf0f7")
const LOCKED_TEXT_COLOR := Color("7a8296")

var _buttons: Array[Button] = []
var _highest_unlocked: int = CampaignProgress.MIN_LEVEL
var _built: bool = false


func _ready() -> void:
	_ensure_built()
	visible = false


## Shows the screen with `highest_unlocked` as the frontier. Connected to the
## game's `level_select_opened` signal from scenes/main.tscn.
func _on_level_select_opened(highest_unlocked: int) -> void:
	present(highest_unlocked)


## Hides the screen when a level starts. Connected from scenes/main.tscn.
func _on_level_started(_level_number: int) -> void:
	visible = false


func present(highest_unlocked: int) -> void:
	_ensure_built()
	_highest_unlocked = clampi(
		highest_unlocked, CampaignProgress.MIN_LEVEL, CampaignProgress.LEVEL_COUNT
	)
	_refresh()
	visible = true
	if is_inside_tree():
		_set_focus_neighbors()
		_focus_first_unlocked()


func button_count() -> int:
	_ensure_built()
	return _buttons.size()


func button_text(level_number: int) -> String:
	_ensure_built()
	if level_number < 1 or level_number > _buttons.size():
		return ""
	return _buttons[level_number - 1].text


func is_locked(level_number: int) -> bool:
	_ensure_built()
	if level_number < 1 or level_number > _buttons.size():
		return true
	return _buttons[level_number - 1].disabled


func _refresh() -> void:
	for index in _buttons.size():
		var level_number: int = index + 1
		var unlocked: bool = level_number <= _highest_unlocked
		var button: Button = _buttons[index]
		button.text = (UNLOCKED_FORMAT if unlocked else LOCKED_FORMAT) % level_number
		button.disabled = not unlocked
		button.focus_mode = Control.FOCUS_ALL if unlocked else Control.FOCUS_NONE


func _on_button_pressed(level_number: int) -> void:
	if level_number < 1 or level_number > _highest_unlocked:
		return
	level_chosen.emit(level_number)


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	var root := Control.new()
	root.name = "LevelSelectRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.theme = _make_theme()
	add_child(root)
	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP_COLOR
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = PANEL_MIN_SIZE
	center.add_child(panel)
	var margin := MarginContainer.new()
	panel.add_child(margin)
	var box := VBoxContainer.new()
	margin.add_child(box)
	box.add_child(_make_title())
	box.add_child(_make_grid())
	box.add_child(_make_hint())


func _make_title() -> Label:
	var label := Label.new()
	label.text = TITLE_TEXT
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.theme_type_variation = TITLE_VARIATION
	return label


func _make_hint() -> Label:
	var label := Label.new()
	label.text = HINT_TEXT
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.theme_type_variation = HINT_VARIATION
	return label


func _make_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	for index in CampaignProgress.LEVEL_COUNT:
		var level_number: int = index + 1
		var button := Button.new()
		button.custom_minimum_size = BUTTON_MIN_SIZE
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_on_button_pressed.bind(level_number))
		grid.add_child(button)
		_buttons.append(button)
	return grid


func _set_focus_neighbors() -> void:
	for index in _buttons.size():
		var button: Button = _buttons[index]
		var column: int = index % COLUMNS
		var up: int = index - COLUMNS
		var down: int = index + COLUMNS
		var left: int = index - 1 if column > 0 else index
		var right: int = index + 1 if column < COLUMNS - 1 and index + 1 < _buttons.size() else index
		button.focus_neighbor_top = button.get_path_to(_buttons[maxi(up, 0)])
		button.focus_neighbor_bottom = button.get_path_to(
			_buttons[mini(down, _buttons.size() - 1)]
		)
		button.focus_neighbor_left = button.get_path_to(_buttons[left])
		button.focus_neighbor_right = button.get_path_to(_buttons[right])


func _focus_first_unlocked() -> void:
	if not visible:
		return
	for button in _buttons:
		if not button.disabled:
			button.grab_focus()
			return


func _make_theme() -> Theme:
	var style := Theme.new()
	style.set_font_size("font_size", "Button", BUTTON_FONT_SIZE)
	style.set_font_size("font_size", "Label", BUTTON_FONT_SIZE)
	style.set_font_size("font_size", TITLE_VARIATION, TITLE_FONT_SIZE)
	style.set_type_variation(TITLE_VARIATION, "Label")
	style.set_font_size("font_size", HINT_VARIATION, HINT_FONT_SIZE)
	style.set_type_variation(HINT_VARIATION, "Label")
	style.set_color("font_color", "Button", TEXT_COLOR)
	style.set_color("font_disabled_color", "Button", LOCKED_TEXT_COLOR)
	style.set_color("font_color", "Label", TEXT_COLOR)
	style.set_stylebox("normal", "Button", _box(BUTTON_COLOR, BUTTON_CORNER_RADIUS))
	style.set_stylebox("hover", "Button", _box(BUTTON_HOVER_COLOR, BUTTON_CORNER_RADIUS))
	style.set_stylebox("pressed", "Button", _box(BUTTON_PRESSED_COLOR, BUTTON_CORNER_RADIUS))
	style.set_stylebox("disabled", "Button", _box(BUTTON_DISABLED_COLOR, BUTTON_CORNER_RADIUS))
	style.set_stylebox("focus", "Button", _focus_box())
	style.set_stylebox("panel", "PanelContainer", _panel_box())
	style.set_constant("h_separation", "GridContainer", GRID_SEPARATION)
	style.set_constant("v_separation", "GridContainer", GRID_SEPARATION)
	style.set_constant("separation", "VBoxContainer", BOX_SEPARATION)
	style.set_constant("margin_left", "MarginContainer", PANEL_MARGIN)
	style.set_constant("margin_top", "MarginContainer", PANEL_MARGIN)
	style.set_constant("margin_right", "MarginContainer", PANEL_MARGIN)
	style.set_constant("margin_bottom", "MarginContainer", PANEL_MARGIN)
	return style


func _box(color: Color, corner_radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(corner_radius)
	return box


func _focus_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color.TRANSPARENT
	box.border_color = PANEL_BORDER_COLOR
	box.set_border_width_all(PANEL_BORDER_WIDTH)
	box.set_corner_radius_all(BUTTON_CORNER_RADIUS)
	return box


func _panel_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL_COLOR
	box.border_color = PANEL_BORDER_COLOR
	box.set_border_width_all(PANEL_BORDER_WIDTH)
	box.set_corner_radius_all(PANEL_CORNER_RADIUS)
	return box
