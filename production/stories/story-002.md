---
id: story-002
status: ready
updated: 2026-11-04
---

# Story: Finish and recover a level — win, undo, restart

## Context

Implements R7–R9 of [design/sokoban-core.md](../design/sokoban-core.md) on top of the
playable core from story-001. Today a player can push crates but cannot win a level,
take a move back, or start over. This story makes one level finishable and mistakes
cheap.

## Acceptance

- [ ] **Win (R7).** When a completed move leaves a crate on every goal, gameplay input
      locks and a results card appears showing moves, pushes and elapsed time. A win is
      never evaluated while a move is still resolving; only after it completes.
- [ ] **Undo (R8).** Pressing `Z` or `U` restores the state before the last completed
      move: player cell, every crate cell, the move counter and the push counter. Undo at
      the start state changes nothing. The history holds at most 999 moves; older entries
      are dropped and undo still restores the remaining ones exactly.
- [ ] **Restart (R9).** Pressing `R` returns the level to its start state, resets both
      counters and clears the undo history, with no confirmation.
- [ ] **Recoverable.** After any sequence of moves, undo back to the start and restart
      produce the same board as loading the level: same player cell, same crate cells,
      same counters, and the same number of undo steps available afterwards.
- [ ] **Evidence frame.** `capture_command` run with `-- --demo=win` plays a short recorded
      solve of `level-001` and captures the frame where the results card is visible.
- [ ] `python scripts/studio.py check` and `python scripts/studio.py test` exit 0, and the
      headless tests cover the win check, undo fidelity, the 999-move bound and restart.

## Out of scope

- Pause and input buffering (R10, R11), the always-on HUD, level sequence and unlocks
  (R12), more than one level.
- Move animations: moves still resolve instantly, so "snap to end" has nothing to snap.
- Audio, localization, menus beyond the results card and the restart key.

## Evidence

- `production/qa/evidence/story-002/index.md`
