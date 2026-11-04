---
id: story-003
status: done
updated: 2026-11-04
---

# Story: Game feel — move animations, input buffering, pause and the HUD

## Context

Implements R10 and R11 of [design/sokoban-core.md](../design/sokoban-core.md), plus the
move durations and the on-screen counters the design already names. Moves currently land
instantly and nothing on screen tells the player how many moves or pushes they have made;
there is no way to pause. This story makes the board read like a game rather than a debug
view.

## Acceptance

- [x] **Move animation.** A free step animates the player over 0.12 s and a push animates
      the player and the crate over 0.16 s, both taken from the design's numbers table. A
      blocked bump animates nothing but the turn and lasts 0.10 s. Counters advance when
      the move completes, not when the key is pressed.
- [x] **Input buffer (R11).** At most one move is buffered while a move animates; a newer
      press replaces the buffered one. When the animation ends the buffered move is
      attempted, and a blocked buffered move follows R6: the player turns, no cell and no
      counter changes.
- [x] **Pause (R10).** `Esc` opens a pause overlay and freezes play; `Esc` closes it and
      play resumes. A move that is animating when pause opens snaps to its end first, so
      the board never rests mid-tile. Losing window focus pauses automatically.
- [x] **HUD.** The move counter, the push counter and the level number are visible at all
      times during play, driven by signals rather than written by gameplay code.
- [x] **Existing rules still hold.** A win is reported only after the final move's
      animation completes, and undo during an animation snaps that move to its end before
      rewinding it.
- [x] **Evidence frame.** `capture_command` run with `-- --demo=pause` captures the frame
      where the pause overlay is open over a partially solved board.
- [x] `python scripts/studio.py check` and `python scripts/studio.py test` exit 0, and the
      headless tests cover the buffer (one slot, replacement, blocked buffered move), the
      pause state including a mid-animation pause, and the HUD values.

## Out of scope

- Level sequence, unlocks and level select (R12); more than one level.
- Audio, localization, a settings screen, a main menu.
- Camera movement of any kind (R13 already decided: fixed).

## Evidence

- `production/qa/evidence/story-003/index.md`
- `production/qa/evidence/story-003/story-003-1.png`
- `production/qa/evidence/story-003/check.log`
- `production/qa/evidence/story-003/test.log`
- `production/qa/evidence/story-003/capture.log`
