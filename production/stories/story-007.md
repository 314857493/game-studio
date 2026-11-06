---
id: story-007
status: ready
updated: 2026-11-06
---

# Story: Controls you can find — an always-visible legend

## Context

Every control in the game is invisible until a player guesses it or finishes a level: undo,
restart and pause are only named on the results card (after winning) or inside the pause
overlay (after already pausing). A player who never presses `Esc` never learns that undo
exists. This story puts the controls on screen.

## Acceptance

- [ ] **Legend during play.** A controls legend is visible for the whole session, naming each
      action with its keys: move and push (arrow keys or `WASD`), undo (`Z` or `U`), restart
      (`R`), pause (`Esc`).
- [ ] **Legend on the level select.** The same legend is on the level-select screen, so a new
      player learns the controls before the first move.
- [ ] **It stays out of the way.** The legend is legible against the scene, never overlaps the
      level / moves / pushes counters or the board, and stays readable while paused.
- [ ] **One source of truth.** The key names come from one set of constants that the pause menu
      and results card reuse, so a rebind or a wording change cannot leave the screens disagreeing.
- [ ] **Evidence frames.** `capture_command` with `-- --demo=pushed` shows the legend while
      playing, and a plain launch capture shows it on the level select.
- [ ] `python scripts/studio.py check` and `python scripts/studio.py test` exit 0, with a test
      asserting the legend text and that it is present on both screens.

## Out of scope

- Rebinding keys, a settings screen, or a first-run tutorial.
- Changing any rule, level or the campaign flow.
- A help overlay that pauses the game.

## Evidence

- `production/qa/evidence/story-007/index.md`
