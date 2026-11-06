extends CanvasLayer

## The always-visible controls legend (story-007). The game never hides this bar:
## the same line is on the level select, during play, over the pause overlay and
## over the results card. Every key name comes from src/controls.gd; this script
## only lays the rows out and draws them.
##
## It sits below the board and above the level-select backdrop, so it never
## covers the level / moves / pushes counters or the board, and it stays
## readable while paused.

const Controls = preload("res://src/controls.gd")

## Above the level-select screen (layer 50) and every play overlay, so the
## legend is on screen even on the level select and while paused.
const LEGEND_LAYER := 60

const FONT_SIZE := 16
const TEXT_COLOR := Color("edf0f7")
const PANEL_COLOR := Color(0.05, 0.06, 0.09, 0.82)
const PANEL_BORDER_COLOR := Color(0.286, 0.843, 1.0, 0.5)
const PANEL_BORDER_WIDTH := 1
const PANEL_CORNER_RADIUS := 8
const SCREEN_MARGIN := 14
const CONTENT_MARGIN := Vector2(12.0, 7.0)

var _panel: PanelContainer
var _label: Label


func _ready() -> void:
	_ensure_built()


## Current legend state, for the headless controls test.
func snapshot() -> Dictionary:
	_ensure_built()
	return {
		"text": _label.text,
		"visible": visible,
		"layer": layer,
		"mouse_filter": _panel.mouse_filter,
	}


func _ensure_built() -> void:
	if _panel != null:
		return
	layer = LEGEND_LAYER
	var root := Control.new()
	root.name = "LegendRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var screen := MarginContainer.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_margins(screen, Vector2(SCREEN_MARGIN, SCREEN_MARGIN))
	root.add_child(screen)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_END
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(column)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(row)
	_panel = PanelContainer.new()
	_panel.name = "LegendPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override("panel", _make_panel_style())
	row.add_child(_panel)
	var content := MarginContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_margins(content, CONTENT_MARGIN)
	_panel.add_child(content)
	_label = Label.new()
	_label.name = "LegendText"
	_label.text = Controls.legend_text()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.add_theme_color_override("font_color", TEXT_COLOR)
	content.add_child(_label)


func _set_margins(margin: MarginContainer, amount: Vector2) -> void:
	margin.add_theme_constant_override("margin_left", int(amount.x))
	margin.add_theme_constant_override("margin_top", int(amount.y))
	margin.add_theme_constant_override("margin_right", int(amount.x))
	margin.add_theme_constant_override("margin_bottom", int(amount.y))


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = PANEL_BORDER_COLOR
	style.set_border_width_all(PANEL_BORDER_WIDTH)
	style.set_corner_radius_all(PANEL_CORNER_RADIUS)
	return style
