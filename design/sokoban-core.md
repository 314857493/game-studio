# Design: Sokoban core

_Grid movement, crate pushing, and the one-screen puzzle loop for the 3D Sokoban game. Owner: game-designer._

Serves the **Readable depth** pillar of [vision.md](vision.md): the 3D view must make a puzzle easier to read, never hide it.

## Goals

- Deliver the classic Sokoban promise in 3D: every level is solved by pushing every crate onto a goal tile; crates are never pulled, carried, or lifted.
- Make the 3D presentation pay for itself: height, shadow, and framing let a player read crate, wall, and goal relationships at a glance from the default view, without moving the camera.
- Keep mistakes cheap: undo and restart are instant and never cost score, time, or a life.
- Give the team a deterministic core: the rules are a pure grid that can be tested headlessly, level data is plain and diffable, and every shipped level has a recorded solution.
- Judge success: a first-time player solves level 1 within 60 s; a build check rejects any level with an invalid structure or no recorded solution; a 12-level session runs 10-15 minutes and ends with every level solved.

## Player experience

The level appears as a compact diorama: pale stone floor tiles, slate wall blocks, warm orange crates, and glowing sockets where crates belong. The camera sits on a fixed three-quarter view over one level, and the whole puzzle fits in a single screen. The player presses a direction key, the small player figure steps one tile, and a crate slides ahead with a low thunk. There is no timer and no move limit, only a move counter, so the first minute is spent reading the room.

The loop: read the room, plan the order of pushes, execute one tile at a time, undo the wrong push as soon as it is seen, and watch the last crate click into place. The win is quiet: the sockets brighten, the results card shows moves, pushes, and time, and the next level is one confirm away. The 3D layer carries two readability promises: every crate on a goal shows a lit base ring, and every wall or crate edge that occludes a walkable tile casts a shadow that makes the blocking edge visible.

Movement stays grid-native: up moves one cell north (-Z), down south (+Z), left west (-X), right east (+X), whatever the camera does. The camera is fixed during play, so the mapping never changes mid-puzzle. Because the default yaw is 45 degrees, each cardinal direction reads as a screen diagonal: north up-right, west up-left, south down-left, east down-right. A screen-aligned mapping is impossible for a square grid seen at 45 degrees, so the four corners are what players learn in their first minutes.

## Rules

R1. **Grid.** A level is a rectangular grid of cells; each cell is wall, floor, or goal. Coordinates are integer (x, z) cells on a single elevation, and out-of-grid cells behave as walls. A level is invalid unless it has at least one crate and the number of crates equals the number of goals. MVP levels have no ramps, holes, or stacked floors.

R2. **Start state.** A valid level has exactly one player spawn on a floor or goal cell, and at least one crate. All crates start on floor cells, never directly on goals, so a level never starts solved. Two objects never share a cell, and the player may spawn on a goal; that goal stays empty until a crate arrives.

R3. **Move input.** Arrow keys and W/A/S/D both map to the four screen-relative directions. One key press is one move attempt, and OS key auto-repeat is ignored. The player faces the pressed direction even when the move is blocked. Diagonal input is never combined.

R4. **Free move.** For direction d, let t be the cell in front of the player. If t is floor or goal and empty, the player enters t, the move counter increases by 1, and the move is pushed onto the undo history.

R5. **Push.** If t holds a crate, let f be the cell beyond the crate. The move succeeds only when f is floor or goal and empty. On success the player enters t, the crate enters f, the move and push counters each increase by 1, and the state is pushed onto the undo history. A crate cannot be pushed onto a wall, onto another crate (no chain pushes), or past the grid edge.

R6. **Blocked move.** If t is wall, or t holds a crate and f is blocked, the player does not change cell. The bump animation plays, no counter changes, and no undo entry is added. The player still turns to face the direction.

R7. **Win.** A crate on a goal is placed. After a completed move, if every goal cell holds a crate, the level is solved: gameplay input locks, the win effect plays, and the results card shows moves, pushes, and elapsed time. A win is never evaluated mid-animation.

R8. **Undo.** Undo restores the last completed move: player cell, all crate cells, move counter, and push counter. The undo history is bounded at 999 moves, which is effectively unlimited in play. Undo at the start state is a no-op. Undo requested during an animation first snaps that move to its end, then rewinds it.

R9. **Restart.** Restart (R key, or the pause menu item) returns the level to its start state, resets both counters, and clears the undo history. Restart is instant and asks for no confirmation.

R10. **Pause.** Esc opens the pause overlay and freezes play; the same key closes it. A move that is animating when pause opens snaps to its end first, so the game never pauses on a half-tile. Losing window focus pauses automatically.

R11. **Input buffer.** At most one move is buffered while a move animation plays. A newer press replaces the buffered move. When the animation ends the buffered move is attempted, and a blocked buffered move follows R6.

R12. **Level sequence.** Levels run in level-file order and unlock one at a time; solving a level unlocks the next and persists the unlock between sessions. The level-select screen only starts unlocked levels. There is no level-fail state: a stuck player always has undo and restart.

R13. **Camera.** Each level defines a fixed yaw in multiples of 45 degrees (45 is the default and gives the isometric corner view), and the pitch is fixed at 55 degrees. The MVP camera does not orbit or follow the player, and gameplay never requires rotating it. Mouse input is not used for movement in the MVP.

## Numbers and tuning

The issue fixes none of these values. They are this page's proposal for the first playable and are tuned in playtest; values that change campaign scope or player experience are repeated in Open questions.

| Value | Default | Range | Unit | Tuned in |
|---|---|---|---|---|
| Grid cell size | 1.0 | 0.5-2.0 | world units per cell | Tile scene; larger cells read better but shrink the framed level |
| Level grid | 9x9 | 5x5-16x16 | cells | Level data; the level must fit one screen |
| MVP level count | 12 | 6-20 | levels | Campaign data; see Open questions |
| Max crates per level | 5 | 1-8 | crates | Level data; above 8 the screen gets noisy |
| Player move duration | 0.12 | 0.08-0.25 | seconds per cell | Player scene; shorter is snappier |
| Push duration | 0.16 | 0.10-0.30 | seconds per cell | Player scene; heavier than a free step |
| Blocked bump duration | 0.10 | 0.05-0.20 | seconds | Player scene |
| Input buffer depth | 1 | 0-2 | moves | Player controller; deeper feels laggy |
| Undo depth | 999 | 50-999 | moves | Session model; practical infinity |
| Undo latency | 0.1 | 0.0-0.1 | seconds | Session model; must feel instant |
| Camera pitch | 55 | 40-70 | degrees | Camera rig; higher reads more top-down, lower keeps more wall height |
| Camera yaw per level | 45 | any multiple of 45 | degrees | Level data; 45 is the isometric corner view, 0 faces the board head-on |
| Camera framing margin | 1.0 | 0.5-2.0 | cells | Camera rig; keeps outer walls visible |
| Level intro | 0.3 | 0.0-0.8 | seconds | HUD; level number before control |
| Win effect | 1.2 | 0.5-2.0 | seconds | HUD; before the results card |
| Session target | 12 | 5-30 | minutes for 12 levels | Campaign design; see Open questions |

## Edge cases

- Opposite directions pressed together: the most recent key event wins; if both arrive in the same frame, the key order reported by the input event decides. No diagonal move is ever produced.
- Undo during a push animation: the push completes instantly, then is rewound; counters return to their pre-push values.
- Restart during an animation or a buffered move: the level returns to start and both the animation and the buffer are discarded.
- Pause during a buffered move: the move completes, then pause freezes the result; the buffer is empty while paused.
- Win with a buffered move: the buffered move is discarded when the win locks input, and counters stop at the winning move.
- Crate pushed off a goal: it stops counting immediately; the win check runs only after the move completes.
- Two crates in a line: only the first crate can be pushed, and only when the cell beyond it is empty; chain pushes never happen.
- Player spawns on a goal: allowed; that goal remains empty and still needs a crate.
- Invalid level data: the loader rejects a level whose crates and goals differ, that has no player spawn, or that places two objects on one cell, and reports the level id instead of loading it.
- Unsolvable level: a level without a recorded solution is a build error, not a runtime state; the player never reaches it.
- Window focus lost: the game auto-pauses, so a held key cannot keep moving the player.
- Default 1152x648 window: the whole level must be inside the camera frame; a level that does not fit is a level-data error.

## Open questions

- ~~**Vision pillar.**~~ **Decided:** [vision.md](vision.md) now states the pillars, and this page serves **Readable depth**. (Owner: creative director.)
- ~~**Scope.**~~ **Decided:** 12 levels, a 10-15 minute session. (Owner: producer.)
- ~~**Camera.**~~ **Decided:** fixed yaw per level, 45 degrees by default, pitch 55 degrees; no orbit, no presets. (Owner: creative director with game-designer.)
- **Art direction.** Minimal geometric diorama (proposed) or a character-led, story-framed Sokoban? The choice changes the crates, goals, and player figure. Owner: creative director.
- **Timing and scoring.** No timer and no per-level score (proposed), or a timed/par-score mode with leaderboards? Owner: game-designer with producer.
- **Terrain extensions.** Holes, ice, one-way tiles, and multi-height ramps are out of the MVP. Are any of them required for the first release? Owner: producer.
- **Input devices.** Keyboard only in the MVP (proposed), or gamepad support before the first playable? Owner: producer.
- ~~**Level validation.**~~ **Decided:** every shipped level carries a recorded solution, and a headless test replays it to prove the level is solvable; no build-time solver. (Owner: tech director.)
- **Presentation scope.** Are audio and Chinese/English localization required in the first playable? The issue does not say. Owner: producer with creative director.

## Links

- Systems index: [systems-index.md](systems-index.md)
- Vision: [vision.md](vision.md)
- Stories: none yet; the producer splits this page into stories after review.
- Evidence: none; this page has no runtime behavior.
