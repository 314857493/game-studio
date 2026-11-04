# Evidence: story-002

Run result: OBSERVED — the 1152x648 frame captured with --demo=win shows the results card over the solved level: "Level solved", "Moves: 21    Pushes: 7    Time: 0.0 s", and "Press R to restart"; behind it every crate sits on a goal. The headless tests prove the winning position, undo fidelity, the 999-move history bound and restart.

- `story-002-1.png` — `python scripts/studio.py capture --out production/qa/evidence/story-002/story-002-1.png -- --demo=win`: the results card over the solved level; the card shows 21 moves, 7 pushes and the elapsed 0.0 s for the recorded solve, and the green goal rings sit under all three crates.
- `check.log` — `python scripts/studio.py check` output: exit 0, `[check] import OK`, and the changed scripts parse.
- `test.log` — `python scripts/studio.py test` output: exit 0, `PASS: 82 checks passed`; the R7 win check, R8 undo fidelity and 999-move bound, and R9 restart are covered; the three `ERROR: level '<id>'` lines are the expected loader rejections.
- `capture.log` — `python scripts/studio.py capture --out production/qa/evidence/story-002/story-002-1.png -- --demo=win` output: exit 0, a 1152x648 PNG of 46270 bytes, user arguments `--demo=win`.
