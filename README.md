# Sokoban 3D

A twelve-level 3D Sokoban built with Godot 4.7. Push every crate onto a goal; crates are
pushed, never pulled, and the level ends when the last crate settles.

## Run it

```sh
godot --path .
```

The first window is the level select. Levels unlock one at a time as you solve them, and the
unlock count persists between sessions.

## Controls

| Key | Action |
|---|---|
| Arrow keys / `W` `A` `S` `D` | Move and push, one tile per press |
| `Z` or `U` | Undo the last move |
| `R` | Restart the level |
| `Esc` | Pause and resume |

The camera is fixed: a 55° pitch at a 45° yaw, so the grid reads as a diamond. Each key moves
along a grid axis, which on screen means the four diagonals — `W` moves north (up-right),
`A` west (up-left), `S` south (down-left), `D` east (down-right).

## Layout

```
design/            vision, the systems index and the core design page
src/               level loading, the rules model, the 3D board, HUD, overlays, campaign flow
scenes/main.tscn   the one scene; wiring only
tests/             headless checks, run with scripts/studio.py test
assets/data/       the twelve levels, each with its recorded solution
production/        roadmap, stories and the QA evidence for each story
```

## Commands

| Command | What it does |
|---|---|
| `python scripts/studio.py check` | Parse and import check |
| `python scripts/studio.py test` | Headless test suite |
| `python scripts/studio.py run` | Play the game |
| `python scripts/studio.py capture --out <file>` | Screenshot the running game |

`run` and `capture` pass arguments after `--` to the game, for example
`capture --out shot.png -- --demo=win`.

## How it was built

This repository is the output of a GitHub-driven studio: requests arrive as issues, an agent
works in its own worktree and answers with a pull request carrying code, tests and a real
screenshot as evidence. The design page, the rules and the evidence indexes are part of the
deliverable, not documentation written afterwards. See `production/stories/` for the four
stories and `production/qa/evidence/` for what each one proved.
