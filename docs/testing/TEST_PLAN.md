# Test Plan

## Automated (every change)
`godot --headless -s tests/run_tests.gd` — see `reports/test_summary.md` for suite contents.

## Manual per build
1. Web build in desktop Chrome/Firefox/Safari: play levels 1–3 with mouse.
2. Mobile browser (portrait): play levels 1–3 by touch; check text legibility and thumb reach.
3. Android device: install debug APK; play levels 1, 11, 18; background/resume app; rotate (should stay portrait).
4. Kill app mid-level, relaunch: progress for finished levels persists.

## Playtest protocol (P0.5, human)
* Silent first session (no explanation), screen + face recording if consented.
* Measure: time to first transfer, completion of levels 1–5, number of hint uses, quits.
* Ask after: "Describe what you were doing" (does the tester say *moving the gap/hole*?),
  "What game did it remind you of?", "Would you pay ~$5 for 100 such levels?"
* Targets (experimental, from directive): ≥70% finish levels 1–5; ≥50% continue voluntarily.
