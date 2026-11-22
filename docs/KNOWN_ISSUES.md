# Known Issues & Limitations (P0)

No known crash or blocker in the tested environments (headless, Xvfb desktop, headless Chromium web).

| # | Severity | Issue | Notes / next step |
|---|---|---|---|
| 1 | **High (design)** | Equivalence verdict PARTIAL: in 18/20 levels the optimal plan equals the conventional block-puzzle plan; only scaffold levels (7, 10) need force-specific reasoning. | `docs/research/originality_audit.md` §4. Curate ≥8/20 divergent levels for P1 or adopt a rule variant after testing. |
| 2 | High (content) | Levels are short (optimal 1–4 moves, 175 states total). Fine for onboarding, too shallow for a premium product. | Deeper levels needed; generator rarely produces ≥5 moves (24/293). |
| 3 | High (validation) | Never run on a physical phone; touch feel, safe areas, performance, battery unverified. | Owner device test required (Android first; iOS needs a Mac + Xcode). |
| 4 | Medium | No mobile export presets / signing (no Android SDK, JDK or Xcode in this environment). | Add Android preset with debug keystore locally. |
| 5 | Medium | `BoardView` and dioramas redraw every frame (pulse animations) → avoidable battery use. | Pause pulses when idle or enable low-processor mode on mobile. |
| 6 | Low | 160–230 draw calls per frame from immediate-mode drawing. | Cache static layers. |
| 7 | Medium | Web: 38 MB wasm (9.3 MB gzip); startup time not measured. | Custom export template without 3D/physics; measure on real network. |
| 8 | Low | Safe-area (notch / home indicator) insets not applied; HUD uses fixed margins (24 px top, 190 px bottom). | Use `DisplayServer.get_display_safe_area()`. |
| 9 | Low | Generator: 31% of candidates fail construction; mixed mode accepts only 0.45%; generated boards look cluttered. | Template-based generation; aesthetic filters (slab count, symmetry). |
| 10 | Low | Level 9 is easier than its slot (36 optimal solutions). | Tighten or move earlier. |
| 11 | Low | Hints are free and unlimited. | Product decision (see market_analysis §3). |
| 12 | Low | Uses Godot's built-in fallback font; Turkish glyphs render, but no brand font. | Choose an OFL font and record it in asset_licenses.md. |
| 13 | Low | Audio only verified to generate/play into Godot's dummy driver (no sound device in container). | Listen on device. |
| 14 | Info | Difficulty score is an uncalibrated heuristic. | Calibrate with playtest completion times. |
| 15 | Info | `TransferValidator` has two static analysis switches (`relaxed_frontier`, `active_sources_only`); they default to off and are only set by tools. | Keep tools from leaking state (they reset the flags). |
