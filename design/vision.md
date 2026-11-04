# Vision: Sokoban 3D

_Owned by the creative director. Every design document must serve this page; a design that cannot name the pillar it serves is not ready._

## Vision statement

A quiet three-dimensional Sokoban for people who like to think with their hands: a diorama
you can read at a glance, crates that move exactly one tile at a time, and a level that ends
the moment the last crate settles. It leaves behind the feeling of a small, clean problem
solved — not a high score, not a streak.

## Pillars

- **Readable depth** — the player can see every crate, wall and goal relationship from one
  fixed isometric view, so the 3D presentation helps them plan instead of hiding the board.
- **Cheap mistakes** — a wrong push costs nothing: undo is instant, restart is instant, and
  neither is scored, timed or limited, so experimenting is always the right move.
- **Quiet satisfaction** — the game never rushes the player; there is no timer and no score,
  and the reward for solving a level is the board going still.

## Anti-goals

- Not a timed or scored arcade game, because a clock turns a thinking game into a reflex test.
- Not a story campaign, because narrative would compete with the puzzle for the player's attention.
- Not a procedural level generator, because hand-tuned levels are what make the twelve here worth finishing.
- Not a camera you can orbit, because a moving viewpoint makes a grid puzzle harder to read.

## Session shape

The player opens the level select, picks the first unlocked level, and reads the board for a
few seconds before touching a key. A first level takes about a minute; later ones take two to
five. A session is five to twelve levels — ten to fifteen minutes — and ends when the player
stops, not when the game decides they are done. Progress persists: the next session starts at
the level after the last one solved.

## Tone references

- *Monument Valley* — borrow the calm, framed, diorama-like presentation; do not borrow its
  optical trickery, which would fight a strict grid.
- *Sokoban* (the original) — borrow the rule purity: one tile per move, crates are pushed and
  never pulled; do not borrow its flat, unreadable presentation.
- *Patrick's Parabox* — borrow the "one more level" pacing that comes from a clean mechanic;
  do not borrow its recursive-box complexity, which is out of scope here.
