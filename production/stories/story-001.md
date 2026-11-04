---
id: story-001
status: done
updated: 2026-11-04
---

# Story: Playable core — grid, movement and pushing

## Context

Implements R1–R6 of [design/sokoban-core.md](../design/sokoban-core.md), the first
slice a player can actually touch: a 3D board with a player, crates and goals,
driven by the keyboard. One level only; the level pipeline, win state and the
rest of the rules come later.

Visual direction follows the design's proposed "minimal geometric diorama":
pale stone floor tiles, slate wall blocks, warm orange crates, and glowing
sockets for goals. Camera sits at a fixed 55° pitch and 45° yaw (the isometric
corner view) over the level.

The screenshot-only `--demo=pushed` flag applies a fixed push sequence so the
evidence frame shows one placed crate. Normal runs never execute it.

## Acceptance

- [x] The level loads from `assets/data/levels/level-001.json` (one 9x9 grid, walls,
      floor, goals, crates, one player spawn) through a single loader function, and the
      loader rejects invalid data with the level id in the error: crate count differs
      from goal count, no player spawn, two objects on one cell.
- [x] Pressing a direction key moves the player exactly one cell into an empty floor or
      goal cell, and the move counter increases by one.
- [x] Pressing a direction key toward a crate whose far cell is empty moves the player
      one cell, moves the crate one cell, and increases both the move and push counters.
- [x] Pressing a direction key toward a wall, or toward a crate whose far cell is blocked
      (wall, crate, or grid edge), changes no cell and no counter, but the player still
      turns to face that direction.
- [x] `capture_command` run with `-- --demo=pushed` captures a frame where exactly one
      crate is on a goal and another goal is visibly empty; floor, walls, crates and the
      player stay distinguishable in the same 1152x648 3D frame, rendered at a 55° pitch
      and 45° yaw isometric view: the board reads as a diamond with the two far slate
      walls visible and the near side cut open.
- [x] `python scripts/studio.py check` and `python scripts/studio.py test` both exit 0;
      the headless tests cover the three loader rejections, R4, R5 and R6, and the
      `--demo=pushed` sequence ends with exactly one crate on a goal and the other goals
      empty.

## Out of scope

- Win detection (R7), undo (R8), restart (R9), pause (R10), input buffering (R11),
  level sequence and unlocks (R12), per-level camera yaw (R13).
- A level editor, a level pipeline, a solver, scoring, timing, audio, localization.
- `design/`, `production/releases/`, `studio.yaml`, `project.godot`, `addons/`.

## Evidence

- `production/qa/evidence/story-001/index.md`
- `production/qa/evidence/story-001/story-001-1.png`
- `production/qa/evidence/story-001/check.log`
- `production/qa/evidence/story-001/test.log`
- `production/qa/evidence/story-001/capture.log`
