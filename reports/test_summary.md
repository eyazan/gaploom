# Test Summary

Run: 2026-11-22 (re-run for v0.2.0 levels), Godot 4.5.1 stable, headless, `godot --headless -s tests/run_tests.gd`.
Raw output: `reports/test_results.json`. **Result: 687 checks passed, 0 failed (≈5 s), 29 levels (v0.5.0).** New suites in v0.5: tinted_glass, feedback_assist, music, howto.

| Suite | Checks | What it covers |
|---|---|---|
| parsing | 30 | All 20 levels parse; 8 malformed definitions rejected (bad tokens, ragged rows, no goal, disconnected slab, receivers w/o emitter, gapless slab); round-trip serialization |
| light | 7 | Beam stops at solid, light gap transmits, motion gap blocks, double mirror routing, mirror-loop termination |
| motion | 13 | Cart settling, motion frontier, groove passage + docking, frames per step, gap under a cart is not a source, solar cart needs light, cart shadows |
| transfer_validity | 23 | 5 991 random (incl. out-of-range/negative) invalid transfers never mutate state or move count; split and floating-chunk rejection |
| conservation_random | 20 | 6 980 random legal moves across all levels: per-family gap totals constant, slabs connected, no material outside slabs, carts never overlap or sit in solid |
| determinism | 60 | Identical sequences → identical states, animation frames and beams; settle is a fixed point; state serialization round-trip |
| undo_restart | 60 | Undo walks back exactly to the initial state; undo on empty history is a no-op; 50× restart stable |
| solver | 103 | All 20 levels solved exhaustively; par == optimum; solution replays to a win; hint is legal; a provably unsolvable level is reported unsolvable with 100% dead ends. Writes `solver_metrics.csv` |
| solver_limits | 3 | State cap → `inconclusive` (never `unsolvable`); invalid level → `invalid` |
| canonical | 61 | Mirrored levels share canonical key and identical solver metrics; no duplicate handcrafted layouts |
| generator | 47 | Same seed → same candidate; accepted levels are solved, ≥3 moves and replay; duplicates rejected |
| save_load | 11 | Fresh save, star rules, lossless round-trip, no downgrade of records, corrupt file fallback, v0→v1 migration |
| input_adapter | 6 | Touch press/drag, mouse release, second finger ignored, touch-emulated mouse ignored (no double input), right button ignored |
| board_view | 16 | Board fits 720×1280, 1080×2400, 1280×720 (landscape), 320×480 with cells ≥ 24 px; drag-and-drop transfer; tap-tap transfer; invalid drop leaves state untouched; rapid inputs during animations stay consistent with authoritative state |
| performance | 2 | Simulation < 2 ms/eval, solving all levels < 5 s (see performance_results.md) |

## Additional verification (not in the automated suite)
* **Generation run**: 10 000 candidates (seed 20261122) → 293 accepted (2.93%). `reports/generation_results.json`.
* **Equivalence analysis**: `reports/equivalence_analysis.csv` (see originality audit).
* **Real rendering**: screenshots of title, levels 1, 7, 18, 20 (start, selected, solved, completion card) and
  level select captured from the running game under Xvfb (`tools/capture.gd`) → `reports/screenshots/`.
* **Web build in a real browser**: headless Chromium (Playwright) loaded `build/web/index.html`, performed a
  real mouse drag of the gap in Level 1 and reached the completion card (`reports/screenshots/web_0*.png`).
  This caught and fixed one layout bug (tutorial text drawn over the board on web).
* **iPhone emulation (v0.2.0)**: Chromium with the Playwright "iPhone 13" profile (390×664, touch, DPR 3)
  loaded the PWA web build and solved Level 1 with **touch taps** (tap gap → tap destination)
  (`reports/screenshots/iphone_0*.png`). This is Chromium, not Safari/WebKit; a real iPhone test is pending.

## Not tested (honest gaps)
* Physical Android/iOS devices, real touchscreens, multi-touch hardware quirks, notches/safe areas.
* Screen-orientation changes at runtime on a device (only layout at different viewport sizes was tested).
* Audio output (container has no sound device; streams are generated and played into Godot's dummy driver).
* Long-session memory leaks beyond a few minutes; battery and thermal behaviour.
* Human usability: none. Solvability ≠ fun.
