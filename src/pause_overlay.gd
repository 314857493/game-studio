extends CanvasLayer

## Pause overlay. The game emits pause_changed; this script only shows or hides
## its own overlay.

const TITLE_TEXT := "Paused"
const HINT_TEXT := "Press Esc to resume"
const DIM_COLOR := Color(0.0, 0.0, 0.0, 0.55)
const PANEL_COLOR := Color(0.07, 0.08, 0.12, 0.94)
const PANEL_BORDER_COLOR := Color("49d7ff")
const PANEL_BORDER_WIDTH := 2
const PANEL_CORNER_RADIUS := 10
const PANEL_MIN_SIZE := Vector2(360.0, 160.0)
const PANEL_MARGIN := 24
const BOX_SEPARATION := 12
const TITLE_FONT_SIZE := 32
const HINT_FONT_SIZE := 18
const TEXT_COLOR := Color("edf0f7")

var _overlay: Control
var _title: Label
var _hint: Label


func _ready() -> void:
	_build_overlay()
	_overlay.visible = false


func _on_pause_changed(paused: bool) -> void:
	_overlay.visible = paused


func _build_overlay() -> void:
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	var dim := ColorRect.new()
	dim.color = DIM_COLOR
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = PANEL_MIN_SIZE
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	center.add_child(panel)
	var margin := MarginContainer.new()
	_set_margins(margin)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", BOX_SEPARATION)
	margin.add_child(box)
	_title = _make_label(TITLE_FONT_SIZE)
	_title.text = TITLE_TEXT
	_hint = _make_label(HINT_FONT_SIZE)
	_hint.text = HINT_TEXT
	box.add_child(_title)
	box.add_child(_hint)


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
