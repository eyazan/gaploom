# Master Directive — completion audit (2026-11-23, v0.6.0)

Legend: ✅ done · 🟡 partly / with limits · ❌ not done · 👤 needs the owner or real people

## 3. Research
| Item | State | Notes |
|---|---|---|
| Competitor analysis (named titles + extra) | 🟡 | `docs/research/competitor_analysis.md`. Web-search summaries only; no hands-on play, no Reddit threads read, a few titles (Shadowmatic, The Room, Where's My Water?) from designer knowledge, flagged as such. |
| Market analysis | 🟡 | `market_analysis.md`, sourced public figures; no paid market data. |
| Originality audit + equivalence analysis | ✅ | `originality_audit.md`, measured with `tools/equivalence_check.gd` (15/29 levels force-divergent). |
| Trademark preliminary check | 🟡 | `trademark_preliminary_check.md`; official USPTO/EUIPO/TÜRKPATENT databases not queried. 👤 |
| Patent search | ❌ | Not accessible from this environment; documented. |

## 4–6. Vision and mechanics
| Item | State |
|---|---|
| Functional void transfer (light, motion) | ✅ |
| Void conservation | ✅ (asserted every move + randomized tests) |
| Originality constraint / block-puzzle equivalence test | ✅ measured; verdict "sufficient for testing, not proven" |
| Functional composition (advanced, not P0) | 🟡 coloured glass added (v0.5); steam/heat-style composition not done (P2) |
| Restoring miniature worlds | ✅ five procedural dioramas |
| Board, objects, voids, fixed components, goals, solvable start | ✅ |
| Optional move limits | 🟡 par/stars instead of hard limits (deliberate, D10) |
| Touch + mouse, no precision gestures | ✅ (iOS touch-id bug found by owner and fixed) |

## 7. P0 scope
| Item | State |
|---|---|
| 20 handcrafted levels | ✅ 29 levels, 5 worlds |
| Two void families | ✅ (+ coloured glass) |
| Transfer, conservation, goals, undo, restart | ✅ |
| Interactive tutorial | ✅ ghost hand, tips, 7-page How to play with live demos |
| Level selection, local save | ✅ versioned save with migration |
| Basic SFX | ✅ synthesized; + music (v0.5) |
| Completion animations | ✅ |
| Deterministic solver | ✅ BFS, optimal counts, dead ends, hints |
| Initial procedural generator | ✅ + solver-guided deepener + daily-puzzle factory |
| Web build | ✅ live on GitHub Pages, PWA |
| First 10 s / first minute communication | ✅ by design; 🟡 only one human (owner) has tried it |

## 8. Visual direction / asset licenses
✅ procedural art; `docs/asset_licenses.md`. 🟡 default engine font (no brand font yet).

## 9–10. Architecture / engine objects
| Item | State |
|---|---|
| Godot 4 stable, GDScript, separated simulation/rendering, data-driven levels, versioned save, localization (en/tr), headless tests, responsive layout | ✅ |
| Named domain objects | ✅ BoardState, GeometryObject, VoidProperty, TransferAction, TransferValidator, FunctionalSimulation, GoalEvaluator, LevelDefinition, PuzzleSolver, LevelGenerator, DifficultyEstimator. 🟡 **VoidInstance** is not a separate class: a gap is a material value in `BoardState.mat` (simpler, and gaps of one family are interchangeable by design). |
| Canonical serialization, hashing, duplicate detection | ✅ |

## 11–12. Solver and generator
| Item | State |
|---|---|
| Solvable / min length / optimal count / complexity / dead ends / trivial / redundant moves / mechanic usage / difficulty | ✅ |
| Timeouts reported as inconclusive | ✅ tested |
| ≥10 000 candidates evaluated, stats reported | ✅ `reports/generation_results.json` (10 000 → 293 accepted) |
| Reject unsolvable / trivial / duplicate / equivalent | ✅ |
| Reject "unintended exploits", "confusing geometry" | 🟡 only via clutter budget + manual visual review |
| Human-curated tutorial levels | ✅ |

## 13–14. Difficulty, retention, commercial
| Item | State |
|---|---|
| Difficulty curve per world | ✅ `reports/difficulty_analysis.md` (late levels 4–8 moves; 6–12 target not fully reached) |
| Daily puzzles, streaks, sharing | ✅ v0.6 (pre-generated, solver-verified) |
| Personal records | ✅ best moves, stars, perfect badge |
| Premium unlock structure | 🟡 free/full gate in code (`Entitlements`); **no store purchase yet** (needs Apple Developer account, USD 99/yr) 👤 |
| No forced ads, no pay-to-win, no account | ✅ |
| Marketing: short clips, store texts | 🟡 trailer generator + store listing draft; nothing published 👤 |

## 15–17. QA, performance, quality gates
| Item | State |
|---|---|
| Automated tests (conservation, validity, determinism, geometry, functions, solver, generator, duplicates, undo, save/load, input, screen sizes, interrupted animations, restart, music, hints, daily) | ✅ ~720 checks |
| Required reports | ✅ test_summary, generation_results, solver_metrics, difficulty_analysis, performance_results |
| Performance measured | 🟡 only in a CPU-only container; **not on a phone** 👤 |
| P0 gates (launch, levels, mechanic, tutorial, completion, undo/restart, save/load, determinism, solvability, documented tests, no known blocker, reproducible build) | ✅ |
| Human validation: 30 testers, completion rates, purchase interest | ❌ 👤 — the most important missing piece |
| Physical Android + iOS testing before release | 🟡 owner played the web build on iPhone; no native device run, no Android |

## 18. Process docs
✅ CLAUDE.md, GDD, ARCHITECTURE, ROADMAP, TASKS, DECISIONS, KNOWN_ISSUES, STATUS, CHANGELOG kept current.

## Summary
Everything that can be built and verified without real players, money or store accounts is done.
What is left is mostly **outside the code**: human playtests, a phone performance check, trademark
clearance, the Apple Developer account + StoreKit purchase, and publishing/marketing.
