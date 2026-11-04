---
id: story-005
status: done
updated: 2026-11-04
---

# Story: Legible overlays — keep the board visible behind the cards

## Context

The results card (story-002) and the pause overlay (story-003) both sit on a near-opaque
panel in the middle of the frame, so the solved board and the paused board are hidden at the
exact moment a player wants to look at them. This is a review finding against the
**Readable depth** pillar in [design/vision.md](../design/vision.md): the 3D view must make
the puzzle easier to read, never hide it.

## Acceptance

- [x] **Results card.** When a level is solved, every crate on its goal stays visible in the
      same 1152x648 frame as the card. The card's backdrop is either translucent enough to
      read the board through it or sized and placed so it does not cover the board.
- [x] **Pause overlay.** The same rule holds while paused: the board under the overlay stays
      readable, including a crate already on a goal.
- [x] **No regression.** The cards keep showing the values they show today (moves, pushes,
      time on the results card; the resume hint on the pause overlay), and the HUD, undo,
      restart and buffering behave exactly as before.
- [x] **Evidence frames.** `capture_command` with `-- --demo=win` and with `-- --demo=pause`
      both capture frames where the board is still readable behind the card.
- [x] `python scripts/studio.py check` and `python scripts/studio.py test` exit 0, with the
      existing suite still passing.

## Out of scope

- Any change to the rules, the level data or the campaign flow.
- New UI screens, audio, localization.
- Move animations and the camera.

## Evidence

- `production/qa/evidence/story-005/index.md`
