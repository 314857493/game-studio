# Evidence: story-001

Run result: OBSERVED — the 1152x648 frame captured with --demo=pushed is the 55° pitch / 45° yaw isometric view: the board reads as a diamond with the two far slate walls visible and the near side cut open; exactly one crate is on the (6, 2) goal (green ring) and the other two goals (2, 2) and (3, 7) are empty (cyan rings), with the player at (6, 3). The demo occupancy and player cell are asserted by the headless demo test.

- `story-001-1.png` — `python scripts/studio.py capture --out production/qa/evidence/story-001/story-001-1.png -- --demo=pushed`: the isometric demo-pushed frame; the crate on (6, 2) sits inside the green placed-goal ring, the empty goals at (2, 2) and (3, 7) show cyan rings, the other two crates stay on floor, and the diamond has the two far slate walls with the near side open.
- `check.log` — `python scripts/studio.py check` output: exit 0, `[check] import OK`, and the changed `src/game.gd` parses.
- `test.log` — `python scripts/studio.py test` output: exit 0, `PASS: 58 checks passed`; the demo test asserts exactly one crate on a goal, the other goals empty, and the player at (6, 3); the three `ERROR: level '<id>'` lines are the expected loader rejections.
- `capture.log` — `python scripts/studio.py capture --out production/qa/evidence/story-001/story-001-1.png -- --demo=pushed` output: exit 0, a 1152x648 PNG of 38981 bytes, user arguments `--demo=pushed`.
