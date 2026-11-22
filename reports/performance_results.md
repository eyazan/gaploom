# Performance Results

Measured 2026-11-22 in a cloud container: 4 vCPU Intel Xeon @ 2.10 GHz, **no GPU** (Mesa llvmpipe software
OpenGL under Xvfb), Godot 4.5.1. **No mobile device was available; nothing below is a device measurement.**
Targets (60 FPS on mid-range phones, fast startup, low battery use) remain **unverified**.

## Logic (headless, `tests/run_tests.gd` → `reports/test_results.json`)
| Metric | Measured |
|---|---|
| `FunctionalSimulation.evaluate` (level 20) | 13.6 µs per call |
| Destination query for one gap | 23.8 µs |
| Solve all 20 handcrafted levels (exhaustive BFS) | 21.5 ms, 175 states |
| Generate + solve 10 000 candidates | 5.8 s (32 481 solver states) |
| Static memory (test process) | 22.2 MB (peak 32.0 MB) |

## Rendering (software renderer, `tools/perf.gd` → `reports/performance_raw.json`)
Uncapped, VSync off, 720×1280, while playing the solution:
| Level | Avg FPS | Avg frame | Worst frame | Draw calls |
|---|---|---|---|---|
| 1 | 65.2 | 15.3 ms | 36.4 ms | 160 |
| 10 | 55.6 | 18.0 ms | 24.7 ms | 230 |
| 20 | 57.8 | 17.3 ms | 65.4 ms | 212 |

* CPU software rasterization of a 720×1280 frame is the bottleneck here; a phone GPU will behave very
  differently. These numbers only show the game is not pathological (no runaway draw calls or allocations).
* Draw calls (160–230) come from immediate-mode `_draw` of every cell each frame. Acceptable for P0;
  batching static layers into a cached CanvasItem is a known optimisation (KNOWN_ISSUES #6).
* Static memory in the running game: 33.0 MB (peak 35.7 MB); video memory 14.6 MB; process peak RSS ≈ 245 MB
  (includes the editor-capable binary, Mesa and Xvfb client libs).

## Startup
* Main scene ready 85 ms after the script started (desktop binary, warm disk).
* Web: the measurement script waited on a DOM condition that never fired and fell through a 60 s timeout, so
  **no valid web startup time was measured**. The page was interactive when screenshots were taken.

## Size
| Artifact | Size |
|---|---|
| Game data `index.pck` | 124 KB (105 KB gzip) |
| Web engine `index.wasm` | 38.0 MB (9.3 MB gzip) |
| Linux binary (pck embedded) | 70.3 MB |
Content is tiny; size is dominated by the stock Godot engine. A custom engine build with unused modules
disabled (3D, physics, etc.) would shrink mobile/web builds substantially (not attempted).

## Battery / thermal
Not measurable here. Known risk: `BoardView` redraws every frame for pulsing hot-spots; on mobile consider
`OS.low_processor_usage_mode` or capping idle FPS (KNOWN_ISSUES #5).
