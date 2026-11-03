---
id: story-001
status: ready
updated: 2026-11-03
---

# Story: Playable core — grid, movement and pushing

## Context

Implements R1–R6 of [design/sokoban-core.md](../design/sokoban-core.md), the first
slice a player can actually touch: a 3D board with a player, crates and goals,
driven by the keyboard. One level only; the level pipeline, win state and the
rest of the rules come later.

Visual direction follows the design's proposed "minimal geometric diorama":
pale stone floor tiles, slate wall blocks, warm orange crates, and glowing
sockets for goals. Camera sits at a fixed 40° pitch with yaw 0 over the level.

## Acceptance

- [ ] The level loads from `assets/data/levels/level-001.json` (one 9x9 grid, walls,
      floor, goals, crates, one player spawn) through a single loader function, and the
      loader rejects invalid data with the level id in the error: crate count differs
      from goal count, no player spawn, two objects on one cell.
- [ ] Pressing a direction key moves the player exactly one cell into an empty floor or
      goal cell, and the move counter increases by one.
- [ ] Pressing a direction key toward a crate whose far cell is empty moves the player
      one cell, moves the crate one cell, and increases both the move and push counters.
- [ ] Pressing a direction key toward a wall, or toward a crate whose far cell is blocked
      (wall, crate, or grid edge), changes no cell and no counter, but the player still
      turns to face that direction.
- [ ] The board renders in 3D in one frame at 1152x648: floor, walls, goals, crates and
      the player are all distinguishable, and a goal under a crate reads differently from
      an empty goal.
- [ ] `python scripts/studio.py check` and `python scripts/studio.py test` both exit 0,
      and the headless tests cover the three loader rejections plus R4, R5 and R6.

## Out of scope

- Win detection (R7), undo (R8), restart (R9), pause (R10), input buffering (R11),
  level sequence and unlocks (R12), per-level camera yaw (R13).
- A level editor, a level pipeline, a solver, scoring, timing, audio, localization.
- `design/`, `production/releases/`, `studio.yaml`, `project.godot`, `addons/`.

## Evidence

- `production/qa/evidence/story-001/index.md`
