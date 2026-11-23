# Changelog

## 0.5.0 (in progress) — 2026-11-23
- Step 1: rejected drops are explained on the board — red cross on the target, the chunk that would break
  off shown red with a crack, and the force hot-spots of the held gap's family flash even when the assist is off.
- Helper-glow setting on the title screen: Auto (only levels 1–6) / On / Off, saved in progress.
- Step 2: levels 8–10, 12–15, 19, 20, 23, 24 deepened with a new solver-guided tool (`tools/deepen.gd`:
  hill-climbing on slab/gap/wall edits + greedy clean-up). Mid/late levels now need 4–8 moves (was 2–6).
- Step 3: **coloured glass** (red/blue tinted gaps, coloured flowers, colour-split beams; shape markers for
  colour-blind players) and a new world **The Glassworks** (levels 25–29) with its own diorama.
  How-to page 7 explains colours. 15/29 levels are force-divergent.
- Step 4: **music** — five procedurally synthesized ambient loops (one per world, `tools/make_music.py`),
  crossfade between worlds, music on/off on the title screen.

## 0.4.0 — 2026-11-23
- **How to play** screen (title screen button and "?" in the game HUD): six pages, each with a small
  self-playing board and a one-paragraph explanation (English + Turkish). States plainly that light and
  mirrors cannot be moved — only gaps.

## 0.3.2 — 2026-11-23 (first iPhone feedback)
- Holding a gap no longer highlights where it may go (owner feedback: "too easy"). Kept only on the two
  first-encounter tutorial levels (1, 11). Force hot-spots at beam ends / cart fronts remain.
- Fix: after a rejection message the level's tip text disappeared permanently; it now returns.

## 0.3.1 — 2026-11-23
- **Fix (critical, iPhone):** the web build ignored every touch on iOS Safari. iOS gives touches large non-zero
  identifiers; the board only accepted touch index 0 and Godot only emulates mouse clicks (buttons) for index 0.
  The first finger down is now the primary touch whatever its id, and button clicks are synthesized for it.
  Reproduced and verified in Chromium with iOS-style touch ids (`tools/web_ios_touch_test.js`).

## 0.3.0 — 2026-11-22
- New world **The Clocktower** (levels 21–24) with procedural clock-tower diorama; all four levels force-divergent
  with new structures (blocking work cart, cross-family "lantern cart" scaffold, double scaffold). 12/24 divergent.
- GitHub repository + GitHub Actions workflow: tests, web export, GitHub Pages deploy.
- CI "Platform builds": unsigned iOS .ipa (macOS runner, for sideloading) and Windows/macOS/Linux desktop builds.
- Desktop keyboard shortcuts (Z undo, R restart, H hint, Esc back, Enter next). `docs/STEAM_PLAN.md`.

## 0.2.0 — 2026-11-22
- Originality: levels 8, 9, 14, 15, 17, 20 redesigned around scaffolding; force-divergent levels 2/20 → 8/20.
  Removed "Crossing", old "Switchyard", "Look Through"; new "Borrowed Lens", "Work Cart", "Switchyard", "Sun Scaffold".
- Generator: optional divergence requirement; `tools/find_divergent.gd`, `tools/compare.gd`.
- iPhone: PWA web export (manifest, icons, Apple meta tags), iOS export preset, `docs/testing/IOS_TESTING.md`.
- Safe-area insets on native mobile; game screen idles at 30 FPS.
- Fix: slab drop-shadow notch on L-shaped slabs.

## 0.1.0 — 2026-11-22 (P0 prototype)
- Core puzzle engine: functional gaps (light, motion), force-gated transfer, conservation, slab integrity.
- Light: emitters, mirrors, flowers. Motion: carts, solar carts, docks, cart shadows.
- BFS solver with optimal-solution counts, dead-end analysis, hints; difficulty heuristic.
- Seeded generate-and-test level generator; 10 000-candidate validation run (293 accepted).
- 20 handcrafted levels in three worlds with procedural restoration dioramas.
- Touch/mouse drag-and-drop and tap-tap input; undo, restart, hint; stars vs par; versioned save.
- Procedural visuals and runtime-synthesized sound; English + Turkish strings.
- Headless test suite (462 checks), screenshot capture, Web + Linux export presets.
- Research, originality/equivalence audit, architecture and design docs.
