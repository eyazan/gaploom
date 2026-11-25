# Known Issues & Limitations (v0.2.0)

No known crash or blocker in the tested environments (headless, Xvfb desktop, headless Chromium desktop and
iPhone-13 emulation).

| # | Severity | Issue | Notes / next step |
|---|---|---|---|
| 1 | Medium (design) | 15/29 levels are force-divergent; several share the scaffold structure. Whether players *notice* the difference is untested. | `docs/research/originality_audit.md`. |
| 2 | Medium (content) | Deeper since v0.5.0 (late levels 4–8 moves, 695 states total) but still below the 6–12-move target for the hardest levels; ~1–1.5 h of play estimated, untested. | New structures for depth. |
| 3 | **High (validation)** | First real-iPhone test (v0.3.0) found that no touch worked (fixed in 0.3.1, verified only in Chromium with iOS-style touch ids). Real Safari still needs a re-test. | Owner iPhone test: `docs/testing/IOS_TESTING.md`. |
| 4 | Medium | iOS preset exports an Xcode project on Linux but cannot be built/signed here; Team ID is a placeholder. No Android preset (no Android test device). | Build on a Mac with Xcode (Path B). |
| 5 | Low | Game screen is capped at 30 FPS while idle and 60 FPS while anything moves; redraw is still continuous. | Measure battery on device. |
| 6 | Low | 160–230 draw calls per frame from immediate-mode drawing. | Cache static layers. |
| 7 | Medium | Web: 38 MB wasm (9.3 MB gzip). Engine-ready time measured only on a local server in emulation (~1.1 s). | Measure on iPhone over mobile data; consider a slim custom template. |
| 8 | Low | Safe-area insets applied on native mobile only (untested on a real notch). On web the browser keeps content inside the safe area (no `viewport-fit=cover`). | Verify on iPhone. |
| 9 | Low | Generator: 31% of candidates fail construction; force-divergent levels are rare in generated output; generated boards look cluttered. | Template-based generation for scaffold structures. |
| 10 | Low | Level 20 has 558 optimal solutions (many interchangeable orders). | Tighten if playtests find it loose. |
| 11 | Low | Hints are free and unlimited. | Product decision. |
| 13 | Medium | Music and SFX are synthesized and verified only by objective checks (no clipping, no silent gaps, seamless loop step < typical step) and by playback in Godot's dummy driver — **nobody has listened to them yet**. | Owner listens on iPhone; adjust mix in tools/make_music.py. |
| 14 | Info | Difficulty score is an uncalibrated heuristic. | Calibrate with playtest data. |
| 15 | Info | `TransferValidator` has two analysis-only static switches (`relaxed_frontier`, `active_sources_only`), default off, reset by tools. | — |
