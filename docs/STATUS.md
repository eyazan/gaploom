# Status — 2026-11-22 (v0.2.0)

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
| 20 levels playable & solver-verified | ✅ | `reports/solver_metrics.csv`, par = optimum |
| Signature mechanic | ✅ | 462 automated checks pass |
| Tutorial / completion / undo / restart / save | ✅ | Test suites + screenshots |
| Deterministic rules | ✅ | Determinism suite |
| Reproducible build | ✅ | Web, Linux; iOS Xcode project (needs Mac to build) |
| Device test | ❌ | Waiting for owner's iPhone test — `docs/testing/IOS_TESTING.md` |
| Human playtests | ❌ | Not started |
| Repository on GitHub | ❌ | Session cannot create repositories; owner must create empty private `gaploom` repo |
