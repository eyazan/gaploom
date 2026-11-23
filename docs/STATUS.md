# Status — 2026-11-23 (v0.5.0)

**Milestone: P0 complete; P1 started (originality depth + iPhone readiness). Awaiting first device test.**

## Since v0.1.0
* Originality: force-divergent levels 2/20 → **8/20** (six levels redesigned around scaffolding; measured with
  `tools/equivalence_check.gd`).
* iPhone readiness: PWA web build (Add to Home Screen, portrait, icons), iOS export preset (Xcode project),
  safe-area insets on native mobile, idle 30 FPS cap, iPhone 13 touch emulation test.
* Generator can now require divergence (`require_divergence`), search tool `tools/find_divergent.gd`.

## Quality gates
| Gate | State | Evidence |
|---|---|---|
| Game launches | ✅ | Desktop (Xvfb), Web (Chromium desktop + iPhone 13 emulation) |
| 29 levels (5 worlds) playable & solver-verified | ✅ | `reports/solver_metrics.csv`, par = optimum |
| Signature mechanic | ✅ | 687 automated checks pass |
| Tutorial / completion / undo / restart / save | ✅ | Test suites + screenshots |
| Deterministic rules | ✅ | Determinism suite |
| Reproducible build | ✅ | CI builds Web, Windows, macOS, Linux and an unsigned iOS .ipa on every push |
| Device test | ⏳ | Owner played v0.3.x on iPhone (touch bug found and fixed); v0.5.0 untested on device |
| Human playtests | ❌ | Not started |
| Repository on GitHub | ✅ | https://github.com/eyazan/gaploom (public) |
| Web build on GitHub Pages | ✅ | https://eyazan.github.io/gaploom/ (auto-deployed on every push) |
