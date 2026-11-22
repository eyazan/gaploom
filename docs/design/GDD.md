# GAPLOOM — Game Design Document (P0)

*Working slogan: Nothing changes everything.* Name provisional.

## 1. Pitch
Restore tiny broken worlds by moving **gaps** — functional emptiness — between clay-like slabs.
A glass gap lets light through; a groove gap lets a little cart pass. Every time you take a gap,
its old place turns solid. The light and the carts themselves decide where a gap may land.

## 2. Pillars
1. **Emptiness is the piece.** You never move solid things; you move what is missing.
2. **The world tells you where.** Gaps can only land where their own force is pressing (glowing hot-spots).
3. **Every move costs something.** Conservation: a gap you take leaves solid stone behind.
4. **Cozy payoff.** Each solved board restores part of a miniature diorama.

## 3. Core loop
Observe → Understand → Transfer → Transform → Activate → Complete → Discover.

## 4. Rules (authoritative: `src/interactions/transfer_validator.gd`)

| Element | Behaviour |
|---|---|
| Slab | Polyomino of cells; each cell is SOLID, LIGHT gap or MOTION gap. Solid material must stay one 4-connected piece. |
| Light gap (glass) | Passes light, blocks carts. Icon: glowing ring. |
| Motion gap (groove) | Passes carts, blocks light. Icon: rounded square with rails. |
| Emitter (lantern) | Casts a beam in a fixed direction. |
| Receiver (flower) | Goal: must be lit. Blooms when lit. |
| Mirror `/` `\` | Turns beams 90°. Blocks carts. |
| Stone wall | Fixed, never takes gaps. |
| Cart | Moves forward until blocked; solid body (blocks light). |
| Solar cart | Moves only while lit. |
| Dock | Goal: must hold a cart. |

**Transfer:** select a gap (any slab, not under a cart) → place on a solid slab cell that its force presses on
(first solid cell hit by a beam / solid cell in front of an active cart) → integrity check → carts settle.

**Win:** all flowers lit and all docks filled simultaneously.

**Stars:** ≤ par = 3, ≤ par+2 = 2, else 1. Par = solver optimum. No move limits, no fail state; undo and
restart are free; a solver-backed hint shows the next optimal move from the current state.

## 5. Controls
One finger. Drag a gap onto a highlighted cell, or tap gap → tap destination. Mouse identical.
Invalid drops shake the target and show a one-line reason (e.g. "That would break the slab in two.").

## 6. Content (v0.2.0: 20 handcrafted levels, all solver-verified)

| # | Name | World | Teaches | Par | Force-divergent |
|---|---|---|---|---|---|
| 1 | First Light | Lighthouse | Drag a gap into the light (ghost hand) | 1 | |
| 2 | Two Panes | Lighthouse | Light advances one pane at a time | 2 | |
| 3 | Borrowed Light | Lighthouse | Taking a gap leaves stone behind | 1 | |
| 4 | One Piece | Lighthouse | Integrity: a slab can't be split | 2 | |
| 5 | Turning Point | Lighthouse | Mirrors | 2 | |
| 6 | Inside Out | Lighthouse | Source order (no floating chunks) | 2 | |
| 7 | Scaffold | Lighthouse | Temporary pane, take it back | 3 | ✓ |
| 8 | Long Way Round | Lighthouse | Scaffold through two mirrors | 3 | ✓ |
| 9 | Borrowed Lens | Lighthouse | Scaffold, sideways work light | 3 | ✓ |
| 10 | Keeper's Lamp | Lighthouse | Scaffold + mirrors | 4 | ✓ |
| 11 | First Track | Railway | Groove gaps let carts pass | 1 | |
| 12 | Recycled Groove | Railway | A passed groove can be reused | 2 | |
| 13 | Close Quarters | Railway | Adjacent walls need two grooves | 2 | |
| 14 | Work Cart | Railway | An empty cart delivers a groove for another | 3 | ✓ |
| 15 | Switchyard | Railway | Work cart + recycling | 4 | ✓ |
| 16 | Shadow Cart | Greenhouse | Carts cast shadows | 1 | |
| 17 | Sun Scaffold | Greenhouse | Solar carts need light; scaffold to wake one | 3 | ✓ |
| 18 | Airlock | Greenhouse | Groove → glass swap behind a solar cart | 3 | |
| 19 | Glass and Groove | Greenhouse | Same cell needs both families, in order | 4 | |
| 20 | Greenhouse Heart | Greenhouse | Airlock + shadow + scaffold | 6 | ✓ |

"Force-divergent" = the conventional block-puzzle baseline solves it in fewer moves
(`tools/equivalence_check.gd`). Design rule from v0.2.0: every new batch should be ≥ 50% divergent.

Difficulty analysis: `reports/difficulty_analysis.md`. Level 16 is a deliberate 1-move concept intro inside the hardest world.

## 7. First 10 seconds / first minute
* **0–10 s:** First launch skips menus and opens Level 1. A ghost hand drags the glass ring into the beam's
  hot-spot; the flower is visibly dark. One move → beam passes → flower blooms → "Restored!".
* **First minute:** Levels 2–4 show the two things a block puzzle doesn't: the destination is chosen by the
  light (hot-spot moves as panes open) and the old slot turns to stone.
* The title screen animation loops the same idea in 3.4 s (designed as a store/short-form clip).

## 8. Restoration meta
Three dioramas (Lighthouse 10 parts, Railway 5, Greenhouse 5). Each solved level lights one part; the
completion card shows the part pulsing. Procedural vector art, no external assets.

## 9. Visual & audio direction
Dusk palette (blue-violet board), soft clay slabs with a drop edge, warm amber light, teal motion.
Families differ by **shape and colour** (ring vs rail-square) for colour-blind safety. All art is drawn
procedurally; all sounds are synthesized at runtime (`src/presentation/sfx.gd`).

## 10. Out of scope for P0
Functional composition (steam, heat beam, magnetism), daily puzzles, sharing, accounts, monetization,
cosmetics, notifications. See `docs/ROADMAP.md`.

## 11. Open design risks
See `docs/research/originality_audit.md` §3 (equivalence verdict PARTIAL) and `docs/KNOWN_ISSUES.md`.
