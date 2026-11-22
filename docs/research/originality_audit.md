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

**Results (measured, `reports/equivalence_analysis.csv`):**

| Metric | Result |
|---|---|
| Levels where the baseline has **more first-move options** | 19 / 20 (2×–10× more) |
| State-space size, GAPLOOM vs baseline | 2–35 states vs 2–1635 states; ratio up to ~80× (level 19: 14 vs 1114, level 20: 20 vs 1635) |
| Levels where the baseline finds a **strictly shorter** solution | **2 / 20** (levels 7 and 10, the "scaffold" levels) |
| Levels whose GAPLOOM optimal solution is also legal in the baseline | 20 / 20 (by construction: GAPLOOM moves ⊂ baseline moves) |

**Interpretation (honest):**
* The force rule **changes what the player can do** in every level (fewer, physically motivated options; the
  hot-spots show where a gap may go).
* But in **18 / 20 levels the optimal plan is the same plan a conventional block puzzle would accept**. In those
  levels the force rule mostly prunes irrelevant options instead of creating new reasoning. The decisions that
  matter there come from the *functions* (light vs motion permeability, cart shadows, solar carts, groove↔glass
  swaps) — which a block puzzle with typed tiles could also express.
* In **2 / 20 levels (7 "Scaffold", 10 "Keeper's Lamp")** the force rule creates reasoning that does not exist in
  the baseline: you must open a pane temporarily so the light can carry a gap deeper, then take that pane's
  gap back. This "scaffolding" is the strongest evidence of a genuinely void-specific mechanic.
* Over the procedurally generated pool the divergence is rarer: **1 of 293** accepted levels (0.3%) and 1 of 182
  in a second 6 000-candidate run (`reports/rule_variant_experiment.json`).

**Verdict for P0: PARTIAL.** The mechanic is *not* fully equivalent to a block puzzle, but the distinctive part
(force-gated placement → scaffolding) is under-used by the current content. Per the directive this is a design
risk that must be addressed before content production, not hidden.

## 4. Redesign directions (prioritised, not yet adopted)

1. **Curate for divergence (cheap, keeps the rule).** Add "baseline is shorter" as a generator acceptance
   criterion and a design checklist item, and raise the share of scaffold-type levels from 2/20 to ≥ 8/20 in
   P1. The generator would need path-aware placement of *temporary* panes to hit this more than 0.3% of the time.
2. **Active-source variant (rule change).** A gap may only be *taken* from a cell its own force currently
   touches (light passing through it / the wake of an active cart). Implemented as an analysis-only switch
   (`TransferValidator.active_sources_only`). **Result so far inconclusive:** the current generator produced 0
   accepted levels under this rule from 6 000 candidates, because it never places stored gaps inside a force
   path. A dedicated generator is needed before judging it.
3. **Gap memory / composition (P2 direction).** Functional composition (e.g. glass + groove adjacent → a "window
   cart" rail) as described in the directive; only after players master the two families.

## 5. Residual originality risks

* Screenshot similarity to laser puzzles (beams + mirrors). Mitigated by the gap tokens and dioramas, not removed.
* Thematic overlap with "negative space" games.
* The property-transfer game on Steam (app 2920670) could launch with similar marketing language.
* Human testers may not perceive the scaffold insight as different from block puzzles even where the solver
  says it is — **requires playtesting**.
