# Originality & Equivalence Audit

Date: 2026-11-22. Companion data: `reports/equivalence_analysis.csv`, `reports/rule_variant_experiment.json`.

## 1. The P0 rule (as implemented)

1. A **gap** is an empty cell inside a slab that carries one function:
   * **Light gap** (glass, ring icon): passes light, blocks carts.
   * **Motion gap** (groove, rail-square icon): passes carts, blocks light.
2. **Transfer**: any gap may be taken from any slab (its cell becomes solid) and placed on a **solid slab cell
   that its own force is currently pressing on** — the first solid cell hit by a beam (light) or the solid cell
   directly in front of an active cart (motion).
3. **Conservation**: gaps are never created or destroyed; per-family totals are constant (checked by an
   assertion on every move and by randomized tests).
4. **Integrity**: after a transfer, every slab's solid material must still be one 4-connected piece.
5. Carts are solid bodies (cast shadows); **solar carts** move only while lit.

## 2. Closest prior art

| Work | Shared idea | Difference |
|---|---|---|
| Baba Is You | Changing what objects *do* by moving things | Moves rule words; GAPLOOM moves function-bearing emptiness between slabs, gated by a live force field. |
| Steam app 2920670 (property-stealing bullet) | Transfer of properties between objects | Transfers named properties (Push, Win…) with a projectile; no conservation-of-emptiness or force gating. |
| Box or Void / Boxes Are Void! | Positive/negative space | Mode flip of the whole level; GAPLOOM moves individual functional voids. |
| Laser/mirror puzzles | Beam routing to targets | GAPLOOM never moves mirrors; it moves the openings in the material the beam crosses. |
| Where's My Water? | Clearing material to route a flow | Material removal there is free (digging); here it is conserved and gated. |

No identical mechanic was found in the searched sources. This is **not** proof of novelty (see limitations in
`competitor_analysis.md`); patent databases were not searched.

## 3. Equivalence test: is it "just a block puzzle"?

**Formal equivalence.** Moving a gap from cell A to cell B is mathematically identical to moving a solid block
from B to A. With typed gaps, GAPLOOM is a *typed token-swap puzzle*. That alone does not make it derivative —
Sokoban is "moving tokens" too — the question the directive asks is whether **the decisions** are the same.

**Method.** `tools/equivalence_check.gd` solves every handcrafted level twice:
* **GAPLOOM**: the real rule.
* **Baseline**: identical level, but the force-gating rule is removed — a gap may go to *any* solid slab cell.
  This is exactly "pick up a stone from anywhere and drop it into a hole", i.e. the conventional block-puzzle
  equivalent with the same functional tiles.

**Results — v0.1.0 level set (first P0 build):** the baseline found a strictly shorter solution in only
**2 / 20** levels (7, 10); in 19/20 levels it had more first-move options; over 293 generated levels only
1 (0.3%) diverged. Verdict then: **PARTIAL** — the force rule mostly pruned irrelevant options instead of
creating new reasoning.

**Results — v0.2.0 level set (current, `reports/equivalence_analysis.csv`):**

| Metric | Result |
|---|---|
| Levels where the baseline has a **strictly shorter** solution ("force-divergent") | **8 / 20** — levels 7, 8, 9, 10, 14, 15, 17, 20 |
| Levels where the baseline has more first-move options | 20 / 20 |
| State-space size, GAPLOOM vs baseline | 2–130 vs 4–19 922 states |

What changed: six levels were redesigned around **scaffolding** — a gap must be placed temporarily so a
force can reach a cell, then taken back:
* Light (7, 8, 9, 10): a "work light" passes through a temporary pane to open a cell that the main beam cannot
  open first, because opening it in the natural order would split the slab.
* Motion (14 "Work Cart", 15 "Switchyard"): an *empty* cart is driven through a temporary groove so that it
  stands in front of the cell the real cart needs, then that groove is reused.
* Mixed (17 "Sun Scaffold", 20 "Greenhouse Heart"): the same idea feeding a solar cart and a flower.

These moves have no counterpart in a block puzzle: in the baseline the player simply drops a block where it
is needed; in GAPLOOM the *function* of the gap decides who can deliver it there.

**v0.3.0 (Clocktower, levels 21–24):** all four new levels are force-divergent and use structures that are
*not* clones of the earlier scaffold: a work cart that blocks the main track until moved on (21), a
**cross-family scaffold** where glass wakes a solar work cart that opens a groove (22, 24), and two scaffolds
in series (23). Total: **12 / 24 (50%)**, meeting the ≥50% target for the batch.

**Verdict for v0.2.0: SUFFICIENT FOR TESTING, NOT PROVEN.** The solver shows that 40% of the levels need
force-specific reasoning. Whether players *perceive* that difference is a human question (playtest item).

Remaining weaknesses found by the same measurement:
* Levels 7, 8, 9 and 17 have **identical solver graphs** (7 states, 4 optimal solutions): they are the same
  scaffold structure in different orientations/families. Good for teaching, weak for variety.
* Random generation almost never produces divergent levels: `tools/find_divergent.gd` (seed 31337, baseline
  capped at 5 000 states) processed 10 000 candidates in 95 s and accepted **1** (mixed mode, 0.01%); the run then
  stalled on a later candidate and was stopped. Hand design (or a template generator for scaffold structures)
  is the realistic path for this content.

## 4. Redesign directions (status)

1. **Curate for divergence — ADOPTED in v0.2.0.** Divergence is now an optional generator criterion
   (`LevelGenerator.evaluate(..., require_divergence=true)`) and a design checklist item. Target for the next
   content batch: ≥ 50% divergent, with more structural variety than the four clones above.
2. **Active-source variant (rule change) — PARKED.** Analysis-only switch
   `TransferValidator.active_sources_only`. The current generator produced 0 accepted levels under it from
   6 000 candidates; it needs its own generator before it can be judged. Revisit only if playtests show that
   players read GAPLOOM as "just a block puzzle".
3. **Functional composition — P2**, after players master the two families.

## 5. Residual originality risks

* Screenshot similarity to laser puzzles (beams + mirrors). Mitigated by the gap tokens and dioramas, not removed.
* Thematic overlap with "negative space" games.
* The property-transfer game on Steam (app 2920670) could launch with similar marketing language.
* Human testers may not perceive the scaffold insight as different from block puzzles even where the solver
  says it is — **requires playtesting**.
