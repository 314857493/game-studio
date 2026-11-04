---
id: story-004
status: ready
updated: 2026-11-04
---

# Story: A campaign — twelve levels, unlocks and level select

## Context

Implements R12 of [design/sokoban-core.md](../design/sokoban-core.md) and closes the
scope question the design left open: twelve levels, one at a time. Today there is a
single level and no way to reach another one. This story turns the prototype into
something a player can sit down and finish.

## Acceptance

- [ ] **Twelve levels.** `assets/data/levels/level-001.json` through `level-012.json` all
      exist. Each is a valid level: one player spawn, crates equal goals, no two objects on
      one cell, inside `5x5`–`16x16`. Level `001` keeps the board it has today.
- [ ] **Recorded solutions.** Every level file carries its `solution` (a string of move
      directions). A headless test replays each solution through the model and asserts the
      level ends solved, so an unsolvable or mis-recorded level fails the build.
- [ ] **Unlocking.** Solving level N unlocks level N+1, and the highest unlocked level
      persists between sessions in `user://`. Replay never removes an unlock.
- [ ] **Level select.** A level-select screen lists all twelve levels with their state
      (locked or unlocked). Only unlocked levels can be started. It is reachable at launch
      and from the results card.
- [ ] **Flow.** The results card offers the next level when one was just unlocked; solving
      the last level shows the campaign finished instead.
- [ ] **Evidence frame.** `capture_command` run with `-- --demo=select` captures the level
      select with earlier levels unlocked and later ones locked.
- [ ] `python scripts/studio.py check` and `python scripts/studio.py test` exit 0, and the
      tests cover solution replay for all twelve levels, the unlock boundary and the
      persistence format.

## Out of scope

- A level editor, a solver, procedurally generated levels.
- Audio, localization, a settings screen.
- Changing the rules from story-001 to story-003.

## Evidence

- `production/qa/evidence/story-004/index.md`
