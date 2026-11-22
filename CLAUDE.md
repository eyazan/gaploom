# CLAUDE.md — GAPLOOM

Working notes for AI-assisted development. Owner communicates in **Turkish**; code, docs, identifiers and
commit messages are **English**.

## Project
Cross-platform puzzle game (Godot 4.5.1, GDScript). Players move functional gaps (light = glass,
motion = groove) between slabs; a gap may only land where its own force presses (see docs/design/GDD.md).

## Commands
```bash
godot --headless --import                                  # (re)import after adding files
godot --headless -s tests/run_tests.gd                     # full test suite (exit code != 0 on failure)
godot --headless -s tools/solve_levels.gd                  # solver metrics for the 20 levels
godot --headless -s tools/generate_levels.gd -- 10000 20261122   # generation run → reports/generation_results.json
godot --headless -s tools/equivalence_check.gd             # block-puzzle baseline comparison (all levels)
godot --headless -s tools/compare.gd -- a.json b.json      # real rule vs baseline for draft levels
godot --headless -s tools/find_divergent.gd -- 20000 1 user://div/   # search force-divergent candidates
python3 tools/make_icons.py                                # app / PWA icons
python3 tools/author_levels.py [pars.json]                 # rebuild data/levels from tools/level_specs.txt
xvfb-run -a godot -s tools/capture.gd --resolution 720x1280 -- res://reports/screenshots/ 1 7
godot --headless --export-release "Web" build/web/index.html
```

## Rules for changes
* Simulation code (`src/core`, `geometry`, `voids`, `simulation`, `interactions`, `solver`, `generator`) must
  not reference nodes or presentation.
* `PuzzleGame.state` is authoritative; `BoardView` only displays.
* Any rule change → run tests, re-solve levels, update `par` (author_levels.py with pars) and the GDD.
* New levels: aim for "force-divergent" (baseline solves in fewer moves); check with tools/compare.gd.
* Never ship a level without solver verification. Never report a capped search as "unsolvable".
* Never fabricate test or performance results; record environment limits.
* Ask the owner before: spending money, publishing anywhere, destructive git operations, scope changes.

## Docs to keep current
docs/STATUS.md, docs/TASKS.md, docs/DECISIONS.md, docs/KNOWN_ISSUES.md, docs/ROADMAP.md, CHANGELOG.md.
