# Systems index

One row per system. Add the row in the same pull request that adds the design doc. The vision lives in [vision.md](vision.md); every row should serve one of its pillars.

| System | Owner | Status | Doc | Summary | Depends on |
|---|---|---|---|---|---|
| Sokoban core | game-designer | in review | design/sokoban-core.md | Classic crate-pushing on a grid with a fixed-camera 3D presentation, practically unlimited undo, and a 12-level sequence. | No system yet; the vision pillars and the camera/level pipeline are open questions. |

Status values:

- draft: being written, not yet a commitment.
- in review: waiting on a human decision.
- approved: implementable, and stories may cite it.
- shipped: implemented and covered by evidence.
- outdated: kept for history, do not implement from it.

Rules:

- Every design doc under design/ has exactly one row here.
- The Doc cell uses forward slashes and starts with design/.
- Owner is a role from .dsh/agents/, not a person's name.
- Moving a row to shipped requires an evidence index under production/qa/evidence/ that reports Run result: OBSERVED.
