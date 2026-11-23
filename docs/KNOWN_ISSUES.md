# Known Issues & Limitations (v0.2.0)

No known crash or blocker in the tested environments (headless, Xvfb desktop, headless Chromium desktop and
iPhone-13 emulation).

| # | Severity | Issue | Notes / next step |
|---|---|---|---|
| 1 | Medium (design) | 12/24 levels are force-divergent (was 2/20 in v0.1). Levels 7, 8, 9, 17 still share one solver graph. Whether players *notice* the difference is untested. | `docs/research/originality_audit.md`. Next batch ≥50% divergent with new structures; playtest question. |
| 2 | High (content) | Levels are short (optimal 1–6 moves, 302 states total). Fine for onboarding, too shallow for a premium product. | Deeper levels needed. |
| 3 | **High (validation)** | First real-iPhone test (v0.3.0) found that no touch worked (fixed in 0.3.1, verified only in Chromium with iOS-style touch ids). Real Safari still needs a re-test. | Owner iPhone test: `docs/testing/IOS_TESTING.md`. |
| 4 | Medium | iOS preset exports an Xcode project on Linux but cannot be built/signed here; Team ID is a placeholder. No Android preset (no Android test device). | Build on a Mac with Xcode (Path B). |
| 5 | Low | Game screen is capped at 30 FPS while idle and 60 FPS while anything moves; redraw is still continuous. | Measure battery on device. |
| 6 | Low | 160–230 draw calls per frame from immediate-mode drawing. | Cache static layers. |
| 7 | Medium | Web: 38 MB wasm (9.3 MB gzip). Engine-ready time measured only on a local server in emulation (~1.1 s). | Measure on iPhone over mobile data; consider a slim custom template. |
| 8 | Low | Safe-area insets applied on native mobile only (untested on a real notch). On web the browser keeps content inside the safe area (no `viewport-fit=cover`). | Verify on iPhone. |
| 9 | Low | Generator: 31% of candidates fail construction; force-divergent levels are rare in generated output; generated boards look cluttered. | Template-based generation for scaffold structures. |
| 10 | Low | Level 20 has 558 optimal solutions (many interchangeable orders). | Tighten if playtests find it loose. |
| 11 | Low | Hints are free and unlimited. | Product decision. |
| 12 | Low | Uses Godot's built-in fallback font; no brand font. | Choose an OFL font. |
| 13 | Low | Audio only verified in Godot's dummy driver. | Listen on device (also with the mute switch). |
| 14 | Info | Difficulty score is an uncalibrated heuristic. | Calibrate with playtest data. |
| 15 | Info | `TransferValidator` has two analysis-only static switches (`relaxed_frontier`, `active_sources_only`), default off, reset by tools. | — |
