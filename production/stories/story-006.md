---
id: story-006
status: ready
updated: 2026-11-06
---

# Story: A restart you can see — pause menu buttons

## Context

R9 of [design/sokoban-core.md](../design/sokoban-core.md) says restart is available from the
`R` key **or the pause menu item**. The key exists; the menu item never shipped. The pause
overlay today shows only "Paused / Press Esc to resume", so a player who is stuck has no
visible way to start the level over and no way to leave for the level select. This story adds
those controls.

## Acceptance

- [ ] **Buttons.** The pause overlay offers **Restart level** and **Resume**, plus **Level
      select** to leave the level. Each is clickable with the mouse and reachable by
      keyboard focus, and none of them breaks the existing `Esc` toggle.
- [ ] **Restart from pause.** Choosing Restart level does exactly what `R` does: board back
      to the start, move and push counters reset, undo history cleared — and the game leaves
      the pause state, so the player is playing again rather than staring at an overlay.
- [ ] **Keyboard still works.** `R` restarts from both playing and paused, and `Esc` still
      opens and closes the pause overlay.
- [ ] **Legibility holds.** The overlay keeps the story-005 rule: the board stays readable
      behind it, and the tests that assert panel and scrim alpha still pass.
- [ ] **Evidence frame.** `capture_command` with `-- --demo=pause` captures the overlay with
      the three buttons visible and the board readable behind them.
- [ ] `python scripts/studio.py check` and `python scripts/studio.py test` exit 0, with a
      test covering restart-from-pause (board, counters, history and pause state) and
      level-select-from-pause.

## Out of scope

- Changing any rule, level or the campaign flow.
- A main menu, settings, audio or localization.
- Restarting a level from the level-select screen.

## Evidence

- `production/qa/evidence/story-006/index.md`
