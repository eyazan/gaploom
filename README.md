# GAPLOOM

*Nothing changes everything.* — a one-finger puzzle game about moving **gaps**, not blocks.
(Name provisional.)

Take a glass gap from one slab (its old place turns solid) and drop it where the light is pressing —
the beam passes, a flower blooms. Groove gaps let little carts roll through. Restore a lighthouse,
a railway and a greenhouse across 20 handcrafted, solver-verified levels.

## Run
Requires Godot **4.5.1** (https://godotengine.org/download).
```bash
godot --path .            # play (desktop)
godot --path . -e         # open in editor
```

## Build
```bash
godot --headless --import
godot --headless --export-release "Web" build/web/index.html      # needs 4.5.1 export templates
godot --headless --export-release "Linux" build/linux/gaploom.x86_64
cd build/web && python3 -m http.server 8000                        # open http://localhost:8000
```
The web export is single-threaded (no special server headers needed).

## Test
```bash
godot --headless -s tests/run_tests.gd
```

## Layout
`src/` engine & game code · `data/levels/` level JSON · `tests/` headless tests · `tools/` solver,
generator, capture, analysis · `docs/` design, research, architecture · `reports/` measured results.

See `docs/STATUS.md` for the current milestone and `docs/KNOWN_ISSUES.md` for limitations.
