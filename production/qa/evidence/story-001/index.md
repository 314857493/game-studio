# Evidence: story-001

Run result: OBSERVED — the 1152x648 window shows the 3D diorama: a pale checker floor inside slate walls, three orange crates, a blue player capsule, two cyan empty goal rings, and one green placed-goal ring under the crate at (3, 7).

- `story-001-1.png` — `python scripts/studio.py capture --out production/qa/evidence/story-001/story-001-1.png`: the playable board at start; the crate on the goal shows the green ring, while the two empty goals at (2, 2) and (6, 2) show cyan rings.
- `check.log` — `python scripts/studio.py check` output: exit 0, `[check] import OK`, and all five changed scripts parse.
- `test.log` — `python scripts/studio.py test` output: exit 0, `PASS: 46 checks passed`; the three `ERROR: level '<id>'` lines are the expected loader rejections asserted by the test.
- `capture.log` — `python scripts/studio.py capture --out production/qa/evidence/story-001/story-001-1.png` output: exit 0, a 1152x648 PNG of 28391 bytes, no script errors.
