# Decision Log

| # | Date | Decision | Why | Alternatives |
|---|---|---|---|---|
| D1 | 2026-11-22 | Godot 4.5.1 stable, GDScript, GL Compatibility renderer | Stable, free, Web + mobile, headless testing | Unity (license/size), custom engine |
| D2 | 2026-11-22 | Discrete grid simulation, no physics engine | Determinism, solver-friendliness, tiny CPU cost | Continuous physics (non-deterministic, unsolvable) |
| D3 | 2026-11-22 | **Force-gated placement**: a gap may only land on the solid cell its own force presses on | Makes destination choice depend on the gap's function (the core originality requirement) and gives the player visible hot-spots | Free placement (= block puzzle), adjacency-only moves |
| D4 | 2026-11-22 | Light gap passes light only; motion gap passes carts only | Two families must interfere to create combined reasoning (airlock, shadow carts) | Any gap passes everything (families collapse) |
| D5 | 2026-11-22 | Integrity on both source and destination slab | "A slab must stay in one piece" is one sentence and adds ordering constraints | Destination-only check (allows floating chunks) |
| D6 | 2026-11-22 | BFS solver | Small state spaces; exact optima and solution counts | A* (no admissible heuristic), bidirectional (asymmetric moves) |
| D7 | 2026-11-22 | Generate-and-test generator, not reverse generation | The move relation is not reversible (frontier depends on current state) | Reverse scrambling |
| D8 | 2026-11-22 | All art and audio procedural | Zero licensing risk, zero budget, tiny build | Asset packs (approval needed) |
| D9 | 2026-11-22 | First launch drops straight into Level 1 | First-10-seconds requirement | Title → tutorial menu |
| D10 | 2026-11-22 | No fail state, free undo/restart, stars vs par | Cozy target audience; avoids frustration-driven monetization | Move limits |
| D11 | 2026-11-22 | Keep P0 rule despite PARTIAL equivalence verdict; record as top design risk | Changing the core rule now would discard all validated content before any human feedback; the variant experiment was inconclusive | Switch to active-source variant now |
| D12 | 2026-11-22 | Generated levels kept as a curation pool, excluded from the shipped build | Handcrafted quality for intro; generated boards look cluttered | Ship generated levels |
| D13 | 2026-11-22 | Raise force-divergent content to ≥ 40% (8/20) by redesigning levels 8, 9, 14, 15, 17, 20 around scaffolding; drop "Crossing", old "Switchyard" and "Look Through" | Directly addresses the PARTIAL equivalence verdict without changing the core rule | Active-source rule variant (parked: no generator support yet) |
| D14 | 2026-11-22 | iPhone first: test via PWA web build in Safari (no Mac needed); native iOS via Xcode project as optional path | Owner has an iPhone, no Android device; web needs no Apple account or spending | Native-only (needs Mac + signing) |
| D16 | 2026-11-23 | Destination highlights off by default (only levels 1, 11) | Owner playtest on iPhone: showing valid cells made puzzles trivial | Setting toggle (possible later) |
| D15 | 2026-11-22 | Idle game screen capped at 30 FPS, 60 FPS while animating or touched | Battery on phones; pulses look fine at 30 | Low-processor mode (would stop pulses) |
| D17 | 2026-11-23 | Deepen levels with a solver-guided local search + greedy clean-up instead of random generation | Keeps the hand-designed structure and visual cleanliness; random generation produced cluttered boards and almost no divergent levels | Hand redesign of every level (slower), random generation |
| D18 | 2026-11-23 | Coloured glass (red/blue tints, coloured flowers) as the next void family variant | Adds decisions about *which* gap goes where, stays inside "move the emptiness", needs no new input; shapes (triangle/square) for colour-blind players | Movable mirrors (would turn it into a laser puzzle), functional composition (later) |
| D19 | 2026-11-23 | Music synthesized offline into WAV loops (QOA-compressed on import) | Zero licensing risk, deterministic, ~1.3 MB in the build; runtime synthesis would cost seconds on the web | Licensed music (cost/approval), runtime AudioStreamGenerator |

