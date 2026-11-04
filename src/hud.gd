extends CanvasLayer

## Always-on HUD: level number, move counter and push counter. The game emits
## hud_changed; this script only formats and writes its own labels.

const LEVEL_FORMAT := "Level %d"
const MOVES_FORMAT := "Moves: %d"
const PUSHES_FORMAT := "Pushes: %d"
const MARGIN := 20.0
const LINE_HEIGHT := 30.0
const LABEL_WIDTH := 220.0
const FONT_SIZE := 22
const TEXT_COLOR := Color("edf0f7")

var _level_label: Label
var _moves_label: Label
var _pushes_label: Label


func _ready() -> void:
	_ensure_built()
	_on_state_changed(0, 0, 1)


func _on_state_changed(moves: int, pushes: int, level_number: int) -> void:
	_ensure_built()
	_level_label.text = LEVEL_FORMAT % level_number
	_moves_label.text = MOVES_FORMAT % moves
	_pushes_label.text = PUSHES_FORMAT % pushes


## Current label texts, for the headless HUD test.
func snapshot() -> Dictionary:
	_ensure_built()
	return {
		"level": _level_label.text,
		"moves": _moves_label.text,
		"pushes": _pushes_label.text,
	}


func _ensure_built() -> void:
	if _level_label != null:
		return
	_level_label = _make_label(0.0)
	_moves_label = _make_label(LINE_HEIGHT)
	_pushes_label = _make_label(LINE_HEIGHT * 2.0)
	add_child(_level_label)
	add_child(_moves_label)
	add_child(_pushes_label)


func _make_label(vertical_offset: float) -> Label:
	var label := Label.new()
	label.position = Vector2(MARGIN, MARGIN + vertical_offset)
	label.size = Vector2(LABEL_WIDTH, LINE_HEIGHT)
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	return label
