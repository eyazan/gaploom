# Performance Results

Measured 2026-11-22 in a cloud container: 4 vCPU Intel Xeon @ 2.10 GHz, **no GPU** (Mesa llvmpipe software
OpenGL under Xvfb), Godot 4.5.1. **No mobile device was available; nothing below is a device measurement.**
Targets (60 FPS on mid-range phones, fast startup, low battery use) remain **unverified**.

## Logic (headless, `tests/run_tests.gd` → `reports/test_results.json`)
| Metric | Measured |
|---|---|
| `FunctionalSimulation.evaluate` (level 20) | 25.8 µs per call (v0.2.0 level 20; 13.6 µs on the smaller v0.1.0 board) |
| Destination query for one gap | 25.5 µs |
| Solve all 20 handcrafted levels (exhaustive BFS) | 53.6 ms, 249 states (v0.2.0) |
| Generate + solve 10 000 candidates | 5.8 s (32 481 solver states) |
| Static memory (test process) | 22.2 MB (peak 32.0 MB) |

## Rendering (software renderer, `tools/perf.gd` → `reports/performance_raw.json`)
Uncapped, VSync off, 720×1280, while playing the solution (measured on v0.1.0, before the v0.2.0 idle 30 FPS cap):
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
* v0.2.0, web, iPhone 13 emulation in headless Chromium, local HTTP server: the engine reported its renderer
  ~1.1 s after navigation. Local network only — not representative of mobile data.
* Main scene ready 85 ms after the script started (desktop binary, warm disk).
* v0.1.0 desktop-viewport web run: the script's wait condition never fired (60 s timeout), so that run gave no
  valid startup time; the v0.2.0 figure above replaces it.

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
