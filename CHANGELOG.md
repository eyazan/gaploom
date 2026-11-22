# Changelog

## 0.2.0 — 2026-11-22
- Originality: levels 8, 9, 14, 15, 17, 20 redesigned around scaffolding; force-divergent levels 2/20 → 8/20.
  Removed "Crossing", old "Switchyard", "Look Through"; new "Borrowed Lens", "Work Cart", "Switchyard", "Sun Scaffold".
- Generator: optional divergence requirement; `tools/find_divergent.gd`, `tools/compare.gd`.
- iPhone: PWA web export (manifest, icons, Apple meta tags), iOS export preset, `docs/testing/IOS_TESTING.md`.
- Safe-area insets on native mobile; game screen idles at 30 FPS.
- Fix: slab drop-shadow notch on L-shaped slabs.

## 0.1.0 — 2026-11-22 (P0 prototype)
- Core puzzle engine: functional gaps (light, motion), force-gated transfer, conservation, slab integrity.
- Light: emitters, mirrors, flowers. Motion: carts, solar carts, docks, cart shadows.
- BFS solver with optimal-solution counts, dead-end analysis, hints; difficulty heuristic.
- Seeded generate-and-test level generator; 10 000-candidate validation run (293 accepted).
- 20 handcrafted levels in three worlds with procedural restoration dioramas.
- Touch/mouse drag-and-drop and tap-tap input; undo, restart, hint; stars vs par; versioned save.
- Procedural visuals and runtime-synthesized sound; English + Turkish strings.
- Headless test suite (462 checks), screenshot capture, Web + Linux export presets.
- Research, originality/equivalence audit, architecture and design docs.
