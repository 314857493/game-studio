# Level data schema

Applies to `level-001.json` through `level-012.json`. The single reader is
`load_level()` in `src/level_loader.gd`; a file that breaks a rule is rejected with
`level '<id>': <reason>`.

| Key | Type | Unit | Allowed | Meaning |
|---|---|---|---|---|
| id | string | - | non-empty, `level-NNN` | Level id used in errors and progress |
| width | integer | grid cells | 5-16 | Number of columns |
| height | integer | grid cells | 5-16 | Number of rows |
| tiles | array of strings | tile characters | height rows, width characters each | `#` wall, `.` floor |
| goals | array of `[x, y]` | grid cells, 0-based | inside the grid, on floor, no duplicates | Goal tiles |
| crates | array of `[x, y]` | grid cells, 0-based | inside the grid, not on a wall, no duplicates | Crate start cells |
| player | `[x, y]` | grid cells, 0-based | inside the grid, on floor or goal, not on a crate | The single player spawn |
| solution | string | moves | non-empty, characters `U` `D` `L` `R` | Recorded solve replayed by the build check |

The loader also enforces: at least one crate, crate count equals goal count, exactly one
player spawn, and no two objects on one cell (the player may not share a crate's cell).
Coordinates are integers; a goal under a crate is a placed crate and is not a duplicate.

Campaign levels 001-012 follow design R2: crates start on floor cells, never on a goal,
so a level never starts solved. The loader still accepts a crate on a goal for older
fixtures; the campaign test rejects a shipped level that starts solved.

`U`, `D`, `L`, `R` are grid directions: up is `-y`, down is `+y`, left is `-x`, right is
`+x`. The solution records only successful moves; the headless test replays it through
`SokobanModel.try_move()` and fails the build when any move is blocked or a goal is empty
at the end.
