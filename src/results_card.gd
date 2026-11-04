extends CanvasLayer

## Results card for a solved level. It owns its UI nodes and is connected to
## game.gd's won / restarted / level_started signals from scenes/main.tscn.
##
## Solving any level but the last offers the next level; solving the last one
## shows the campaign-finished state instead.

signal next_level_requested()
signal level_select_requested()

const CampaignProgress = preload("res://src/campaign_progress.gd")

const SOLVED_TITLE := "Level solved"
const FINISHED_TITLE := "Campaign finished"
const STATS_FORMAT := "Moves: %d    Pushes: %d    Time: %.1f s"
const SOLVED_HINT := "R restarts · Enter starts the next level"
const FINISHED_HINT := "All 12 levels solved · choose a level to replay"
const NEXT_TEXT := "Next level"
const SELECT_TEXT := "Level select"

const PANEL_MIN_SIZE := Vector2(540.0, 320.0)
const PANEL_MARGIN := 28
const BOX_SEPARATION := 16
const BUTTON_MIN_SIZE := Vector2(180.0, 48.0)
const TITLE_FONT_SIZE := 30
const STATS_FONT_SIZE := 20
const HINT_FONT_SIZE := 18
const BUTTON_FONT_SIZE := 20
const PANEL_BORDER_WIDTH := 2
const PANEL_CORNER_RADIUS := 10

const TEXT_COLOR := Color("edf0f7")
## The solved board must stay readable through the card (design/vision.md,
## Readable depth), so the backdrop is a translucent tint, not a near-opaque panel.
const PANEL_COLOR := Color(0.07, 0.08, 0.12, 0.4)
const PANEL_BORDER_COLOR := Color("49d7ff")

var _overlay: Control
var _panel_style: StyleBoxFlat
var _title: Label
var _stats: Label
var _hint: Label
var _next_button: Button
var _select_button: Button
var _level_number: int = 0


func _ready() -> void:
	_ensure_built()
	_overlay.visible = false


func _on_won(moves: int, pushes: int, seconds: float, level_number: int) -> void:
	_ensure_built()
	_level_number = level_number
	_stats.text = STATS_FORMAT % [moves, pushes, seconds]
	var finished: bool = level_number >= CampaignProgress.LEVEL_COUNT
	_title.text = FINISHED_TITLE if finished else SOLVED_TITLE
	_hint.text = FINISHED_HINT if finished else SOLVED_HINT
	_next_button.visible = not finished
	_overlay.visible = true
	if is_inside_tree():
		_set_focus_neighbors()
		if finished:
			_select_button.grab_focus()
		else:
			_next_button.grab_focus()


func _on_restarted() -> void:
	_ensure_built()
	_overlay.visible = false


func _on_level_started(_level_number: int) -> void:
	_ensure_built()
	_overlay.visible = false


func _on_next_pressed() -> void:
	next_level_requested.emit()


func _on_select_pressed() -> void:
	level_select_requested.emit()


## Current card state, for the headless flow test.
func snapshot() -> Dictionary:
	_ensure_built()
	return {
		"title": _title.text,
		"stats": _stats.text,
		"hint": _hint.text,
		"next_visible": _next_button.visible,
		"select_visible": _select_button.visible,
		"panel_alpha": _panel_style.bg_color.a,
	}


func _ensure_built() -> void:
	if _overlay != null:
		return
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = PANEL_MIN_SIZE
	_panel_style = _make_panel_style()
	panel.add_theme_stylebox_override("panel", _panel_style)
	center.add_child(panel)
	var margin := MarginContainer.new()
	_set_margins(margin)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", BOX_SEPARATION)
	margin.add_child(box)
	_title = _make_label(TITLE_FONT_SIZE)
	_stats = _make_label(STATS_FONT_SIZE)
	_hint = _make_label(HINT_FONT_SIZE)
	box.add_child(_title)
	box.add_child(_stats)
	box.add_child(_hint)
	box.add_child(_make_buttons())
	_title.text = SOLVED_TITLE
	_hint.text = SOLVED_HINT


func _make_buttons() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", BOX_SEPARATION)
	_next_button = _make_button(NEXT_TEXT)
	_next_button.pressed.connect(_on_next_pressed)
	_select_button = _make_button(SELECT_TEXT)
	_select_button.pressed.connect(_on_select_pressed)
	row.add_child(_next_button)
	row.add_child(_select_button)
	return row


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = BUTTON_MIN_SIZE
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	return button


func _set_focus_neighbors() -> void:
	if _next_button == null or _select_button == null:
		return
	_next_button.focus_neighbor_left = _next_button.get_path_to(_next_button)
	_next_button.focus_neighbor_right = _next_button.get_path_to(_select_button)
	_select_button.focus_neighbor_left = _select_button.get_path_to(_next_button)
	_select_button.focus_neighbor_right = _select_button.get_path_to(_select_button)


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = PANEL_BORDER_COLOR
	style.set_border_width_all(PANEL_BORDER_WIDTH)
	style.set_corner_radius_all(PANEL_CORNER_RADIUS)
	return style


func _set_margins(margin: MarginContainer) -> void:
	margin.add_theme_constant_override("margin_left", PANEL_MARGIN)
	margin.add_theme_constant_override("margin_top", PANEL_MARGIN)
	margin.add_theme_constant_override("margin_right", PANEL_MARGIN)
	margin.add_theme_constant_override("margin_bottom", PANEL_MARGIN)


func _make_label(font_size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	return label
