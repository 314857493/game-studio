extends CanvasLayer

## Pause overlay. The game emits pause_changed; this script only shows or hides
## its own overlay and reports the player's chosen action through signals.

signal restart_requested()
signal resume_requested()
signal level_select_requested()

const Controls = preload("res://src/controls.gd")

const TITLE_TEXT := "Paused"
const RESTART_TEXT := "Restart level"
const RESUME_TEXT := "Resume"
const LEVEL_SELECT_TEXT := "Level select"
## The paused board must stay readable behind the overlay (design/vision.md,
## Readable depth), so the scrim is a light tint and the panel is translucent.
const DIM_COLOR := Color(0.0, 0.0, 0.0, 0.15)
const PANEL_COLOR := Color(0.07, 0.08, 0.12, 0.4)
const PANEL_BORDER_COLOR := Color("49d7ff")
const PANEL_BORDER_WIDTH := 2
const PANEL_CORNER_RADIUS := 10
const BUTTON_CORNER_RADIUS := 8
const PANEL_MIN_SIZE := Vector2(600.0, 224.0)
const BUTTON_MIN_SIZE := Vector2(170.0, 48.0)
const PANEL_MARGIN := 24
const BOX_SEPARATION := 12
const TITLE_FONT_SIZE := 32
const HINT_FONT_SIZE := 18
const BUTTON_FONT_SIZE := 18
const TEXT_COLOR := Color("edf0f7")

var _overlay: Control
var _dim: ColorRect
var _panel_style: StyleBoxFlat
var _title: Label
var _hint: Label
var _restart_button: Button
var _resume_button: Button
var _level_select_button: Button


func _ready() -> void:
	_build_overlay()
	_overlay.visible = false


func _on_pause_changed(paused: bool) -> void:
	_overlay.visible = paused
	if paused:
		_focus_resume()
	else:
		_release_focus()


## Current overlay state, for the headless menu and legibility tests.
func snapshot() -> Dictionary:
	if _overlay == null:
		_build_overlay()
	return {
		"title": _title.text,
		"hint": _hint.text,
		"restart": _restart_button.text,
		"resume": _resume_button.text,
		"level_select": _level_select_button.text,
		"visible": _overlay.visible,
		"focus_modes": [
			_restart_button.focus_mode,
			_resume_button.focus_mode,
			_level_select_button.focus_mode,
		],
		"min_button_height": _restart_button.custom_minimum_size.y,
		"panel_alpha": _panel_style.bg_color.a,
		"dim_alpha": _dim.color.a,
	}


func _build_overlay() -> void:
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	_dim = ColorRect.new()
	_dim.color = DIM_COLOR
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(_dim)
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
	_title.text = TITLE_TEXT
	box.add_child(_title)
	box.add_child(_make_buttons())
	_hint = _make_label(HINT_FONT_SIZE)
	_hint.text = Controls.pause_hint()
	box.add_child(_hint)


func _make_buttons() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", BOX_SEPARATION)
	_restart_button = _make_button(RESTART_TEXT)
	_restart_button.pressed.connect(_on_restart_pressed)
	_resume_button = _make_button(RESUME_TEXT)
	_resume_button.pressed.connect(_on_resume_pressed)
	_level_select_button = _make_button(LEVEL_SELECT_TEXT)
	_level_select_button.pressed.connect(_on_level_select_pressed)
	row.add_child(_restart_button)
	row.add_child(_resume_button)
	row.add_child(_level_select_button)
	return row


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = BUTTON_MIN_SIZE
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	button.add_theme_stylebox_override("focus", _make_focus_style())
	return button


func _on_restart_pressed() -> void:
	restart_requested.emit()


func _on_resume_pressed() -> void:
	resume_requested.emit()


func _on_level_select_pressed() -> void:
	level_select_requested.emit()


func _focus_resume() -> void:
	if not is_inside_tree():
		return
	_set_focus_neighbors()
	_resume_button.grab_focus()


func _release_focus() -> void:
	if not is_inside_tree():
		return
	var owner := get_viewport().gui_get_focus_owner()
	if owner != null and _overlay.is_ancestor_of(owner):
		get_viewport().gui_release_focus()


func _set_focus_neighbors() -> void:
	if _restart_button == null:
		return
	_restart_button.focus_neighbor_left = _restart_button.get_path_to(_restart_button)
	_restart_button.focus_neighbor_right = _restart_button.get_path_to(_resume_button)
	_restart_button.focus_neighbor_top = _restart_button.get_path_to(_restart_button)
	_restart_button.focus_neighbor_bottom = _restart_button.get_path_to(_restart_button)
	_resume_button.focus_neighbor_left = _resume_button.get_path_to(_restart_button)
	_resume_button.focus_neighbor_right = _resume_button.get_path_to(_level_select_button)
	_resume_button.focus_neighbor_top = _resume_button.get_path_to(_resume_button)
	_resume_button.focus_neighbor_bottom = _resume_button.get_path_to(_resume_button)
	_level_select_button.focus_neighbor_left = _level_select_button.get_path_to(_resume_button)
	_level_select_button.focus_neighbor_right = _level_select_button.get_path_to(_level_select_button)
	_level_select_button.focus_neighbor_top = _level_select_button.get_path_to(_level_select_button)
	_level_select_button.focus_neighbor_bottom = _level_select_button.get_path_to(_level_select_button)


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = PANEL_BORDER_COLOR
	style.set_border_width_all(PANEL_BORDER_WIDTH)
	style.set_corner_radius_all(PANEL_CORNER_RADIUS)
	return style


func _make_focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = PANEL_BORDER_COLOR
	style.set_border_width_all(PANEL_BORDER_WIDTH)
	style.set_corner_radius_all(BUTTON_CORNER_RADIUS)
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
