# Evidence: story-001

Run result: OBSERVED — the 1152x648 frame captured with --demo=pushed shows exactly one crate on the (6, 2) goal (green ring) and the other two goals (2, 2) and (3, 7) empty (cyan rings), with the player at (6, 3); the same occupancy and player cell are asserted by the headless demo test.

- `story-001-1.png` — `python scripts/studio.py capture --out production/qa/evidence/story-001/story-001-1.png -- --demo=pushed`: the demo-pushed frame; the crate on (6, 2) sits inside the green placed-goal ring, the empty goals at (2, 2) and (3, 7) show cyan rings, and the other two crates stay on floor.
- `check.log` — `python scripts/studio.py check` output: exit 0, `[check] import OK`, and all changed scripts (including `src/sokoban_demo.gd`) parse.
- `test.log` — `python scripts/studio.py test` output: exit 0, `PASS: 58 checks passed`; the demo test asserts exactly one crate on a goal, the other goals empty, and the player at (6, 3); the three `ERROR: level '<id>'` lines are the expected loader rejections.
- `capture.log` — `python scripts/studio.py capture --out production/qa/evidence/story-001/story-001-1.png -- --demo=pushed` output: exit 0, a 1152x648 PNG of 28379 bytes, user arguments `--demo=pushed`.
