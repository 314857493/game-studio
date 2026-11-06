extends RefCounted

## Single source of truth for the player-facing control names (story-007).
##
## The always-visible legend, the pause menu and the results card all read their
## key names from here, so a rebind or a wording change cannot leave the screens
## disagreeing.

const MOVE_KEYS := "Arrow keys or WASD"
const UNDO_KEYS := "Z or U"
const RESTART_KEY := "R"
const PAUSE_KEY := "Esc"

const MOVE_LABEL := "Move / Push"
const UNDO_LABEL := "Undo"
const RESTART_LABEL := "Restart"
const PAUSE_LABEL := "Pause"

const ROW_FORMAT := "%s: %s"
const LEGEND_SEPARATOR := "  ·  "
const LEGEND_PREFIX := "Controls — "
const PAUSE_HINT_FORMAT := "Press %s to resume"
const RESULTS_SOLVED_HINT_FORMAT := "%s restarts · Enter starts the next level"


## One "action: keys" row per control, in the order the legend shows them.
static func legend_rows() -> Array[String]:
	var rows: Array[String] = []
	rows.append(ROW_FORMAT % [MOVE_LABEL, MOVE_KEYS])
	rows.append(ROW_FORMAT % [UNDO_LABEL, UNDO_KEYS])
	rows.append(ROW_FORMAT % [RESTART_LABEL, RESTART_KEY])
	rows.append(ROW_FORMAT % [PAUSE_LABEL, PAUSE_KEY])
	return rows


## The whole legend as one line, for the persistent bottom bar.
static func legend_text() -> String:
	return LEGEND_PREFIX + LEGEND_SEPARATOR.join(legend_rows())


## The pause menu's resume hint, built from PAUSE_KEY.
static func pause_hint() -> String:
	return PAUSE_HINT_FORMAT % PAUSE_KEY


## The results card's restart hint, built from RESTART_KEY.
static func results_solved_hint() -> String:
	return RESULTS_SOLVED_HINT_FORMAT % RESTART_KEY
