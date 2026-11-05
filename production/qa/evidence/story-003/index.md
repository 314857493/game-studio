# Evidence: story-003

Run result: OBSERVED — the 1152x648 frame captured with --demo=pause shows the pause overlay ("Paused", "Press Esc to resume") over a partially solved board: the crate at (3, 7) already sits on a goal, the other two goals are empty, and the HUD reads "Level 1 / Moves: 3 / Pushes: 1". The headless tests cover the one-slot buffer, its replacement and blocked buffered move, the mid-animation pause snap, and the HUD values.

- `story-003-1.png` — `python scripts/studio.py capture --out production/qa/evidence/story-003/story-003-1.png -- --demo=pause`: the pause overlay over the partial solve; the HUD shows Level 1, Moves 3, Pushes 1; the crate on the goal at (3, 7) has a green ring and the other goals are still empty.
- `check.log` — `python scripts/studio.py check` output: exit 0, `[check] import OK`, and the changed scripts parse.
- `test.log` — `python scripts/studio.py test` output: exit 0, `PASS: 105 checks passed`; covers the one-slot buffer, its replacement and blocked buffered move, the mid-animation pause snap and resume, the HUD values, and the story-001/002 regressions; the three `ERROR: level '<id>'` lines are the expected loader rejections.
- `capture.log` — `python scripts/studio.py capture --out production/qa/evidence/story-003/story-003-1.png -- --demo=pause` output: exit 0, a 1152x648 PNG of 51913 bytes, user arguments `--demo=pause`.
