# Architecture

Engine: **Godot 4.5.1 stable**, GDScript, GL Compatibility renderer (Web + low-end mobile).
No third-party addons. Everything (UI, art, audio) is generated in code; the only scene is `scenes/main.tscn`.

## Layers

```
data/levels/*.json ──► LevelDefinition (immutable)            src/core
                          │
                          ▼
            BoardState (authoritative, discrete)                src/core
                          │
      ┌───────────────────┼──────────────────────────┐
      ▼                   ▼                          ▼
FunctionalSimulation  TransferValidator/Action   GoalEvaluator     src/simulation, src/interactions
 (light trace,         (the rule, conservation,   (receivers lit,
  cart settle)          integrity)                 docks filled)
      └───────────────────┬──────────────────────────┘
                          ▼
                  PuzzleGame (facade: history, undo, restart)   src/core
                          │
          ┌───────────────┼───────────────────┐
          ▼               ▼                   ▼
   PuzzleSolver     LevelGenerator      BoardView (display state, animation, input)
   Difficulty-      (seeded, validated  src/presentation  ◄── InputAdapter (touch/mouse)
   Estimator         by solver)                                  src/ui
   src/solver       src/generator               ▼
                                         main.gd (screens, HUD, overlay) + SaveGame (src/persistence)
```

### Rules of the codebase
* **Simulation never depends on presentation.** Everything under `src/core`, `src/geometry`, `src/voids`,
  `src/simulation`, `src/interactions`, `src/solver`, `src/generator` runs headless with no nodes.
* **Authoritative vs display state.** `PuzzleGame.state` is the only truth. `BoardView` keeps interpolated
  copies (`shown_mat`, `shown_shuttles`) for animation and resyncs on completion, undo, restart or interruption
  (`finish_animation()`).
* **Invalid moves never mutate state**: `try_transfer` validates first and returns a reason.
* **Determinism**: no randomness in rules; carts are processed in index order; each settle pass uses the
  light field computed at the start of the pass; the generator uses explicit seeds.

## Key types

| Type | File | Notes |
|---|---|---|
| `LevelDefinition` | src/core/level_definition.gd | Token grid parser, validation, `to_dict`, `mirrored`, `canonical_key` (mirror-invariant). |
| `BoardState` | src/core/board_state.gd | `mat` (per-cell material), cart cells, docked flags. `key()` = canonical serialization (hex material + cart cells). Gaps of a family are interchangeable, so the material grid already factors permutations. |
| `GeometryObject` | src/geometry/geometry_object.gd | 4-connectivity of slab solids. |
| `VoidProperty` | src/voids/void_property.gd | Families and permeability. |
| `TransferAction` / `TransferValidator` | src/interactions | The rule; error codes; legal-move enumeration; two analysis-only switches (`relaxed_frontier`, `active_sources_only`). |
| `FunctionalSimulation` | src/simulation | `trace_light`, `settle`, `evaluate` (beams, lit, frontiers). Mirror loops are guarded. |
| `GoalEvaluator` | src/simulation | progress / solved. |
| `PuzzleGame` | src/core/puzzle_game.gd | History stack, conservation assertion. |
| `PuzzleSolver` | src/solver | BFS with canonical keys, optimal counts, dead-ends, hint-from-state. |
| `DifficultyEstimator` | src/solver | Heuristic score/tier (uncalibrated). |
| `LevelGenerator` | src/generator | Path-aware generate-and-test; rejection reasons. |
| `SaveGame` | src/persistence | Versioned JSON (v1), migration from v0, atomic write via temp+rename. |
| `BoardView` | src/presentation | All board drawing via `_draw` + StyleBoxFlat; no textures. |
| `Sfx` | src/presentation | Runtime-synthesized WAV streams. |

## Solver choice
BFS over settled states. Measured: all 20 handcrafted levels → 175 states total, ~20 ms. A* was not needed
(no obvious admissible heuristic under force-gated placement) and bidirectional search is not applicable because
the move relation is not symmetric. Search caps produce `inconclusive`, never `unsolvable`.

## Level format (v1)
```json
{"format":1,"id":"level_07","name":"Scaffold","world":"lighthouse","tutorial":"tut_scaffold","par":3,
 "rows":[".. .. .. Ev .. ..", "..."]}
```
Tokens: `..` air, `##` stone, `/.` `\.` mirrors, `E>` emitter, `R.` flower, `D.` dock, `S>` cart, `s>` solar
cart, `ao`/`aL`/`aM` slab *a* solid / light gap / motion gap.

## Platforms
* Web export (single-threaded, no SharedArrayBuffer requirement) — tested in headless Chromium.
* Linux desktop export — built.
* Android/iOS: not exported in this environment (no Android SDK / Xcode). Project settings are mobile-ready
  (portrait, `canvas_items` stretch with `expand` aspect, GL Compatibility, touch input, ETC2/ASTC enabled).
* Apple Silicon development: Godot 4.5.1 has native arm64 macOS editor builds; nothing in the project is
  architecture-specific. Not tested on a Mac here.

## Localization
`data/i18n/strings.csv` (en, tr) imported as Godot translations; UI uses `tr()` keys. Level names are
proper names (English). Locale follows the OS.
