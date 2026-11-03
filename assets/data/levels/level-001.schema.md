# Level data schema

Applies to `level-001.json`. The single reader is `load_level()` in
`src/level_loader.gd`; a file that breaks a rule is rejected with
`level '<id>': <reason>`.

| Key | Type | Unit | Allowed | Meaning |
|---|---|---|---|---|
| id | string | - | non-empty | Level id used in errors and progress |
| width | integer | grid cells | 5-16 | Number of columns |
| height | integer | grid cells | 5-16 | Number of rows |
| tiles | array of strings | tile characters | height rows, width characters each | `#` wall, `.` floor |
| goals | array of `[x, y]` | grid cells, 0-based | inside the grid, on floor, no duplicates | Goal tiles |
| crates | array of `[x, y]` | grid cells, 0-based | inside the grid, not on a wall, no duplicates | Crate start cells; one may start on a goal |
| player | `[x, y]` | grid cells, 0-based | inside the grid, on floor or goal, not on a crate | The single player spawn |

The loader also enforces: at least one crate, crate count equals goal count, exactly one
player spawn, and no two objects on one cell (the player may not share a crate's cell).
Coordinates are integers; a goal under a crate is a placed crate and is not a duplicate.
