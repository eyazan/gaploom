# Steam Plan (secondary platform)

Status: **builds ready, nothing submitted.** Every push produces Windows / macOS / Linux builds
(workflow "Platform builds", artifacts `gaploom-windows`, `gaploom-macos`, `gaploom-linux`).

## What already works on desktop
* Mouse input (same one-finger rules), window resizable, layout tested at 1280×720 landscape and portrait.
* Saves to the OS user data folder; fully offline.

## Steps that need the owner (cost / publishing → approval required)
1. **Steamworks partner account** (free to create, tax/bank forms).
2. **Steam Direct fee: USD 100 per game** (recoupable after USD 1 000 gross revenue, per Valve's policy at the
   time of writing — verify on partner.steamgames.com). Exceeds the "USD 0–100" budget ceiling only if combined with
   other costs; needs explicit approval.
3. Store page assets (capsules, screenshots, trailer) — can be produced from `tools/capture.gd` + Godot movie maker.
4. Upload builds with SteamPipe (`steamcmd`), set release date. Valve requires a store page to be live
   ≥ 2 weeks before release ("Coming Soon"), which is also when wishlists accumulate.

## Engineering before a Steam release (not done yet)
* Landscape-first desktop layout (HUD beside the board instead of above/below), keyboard shortcuts (Z undo, R restart).
* Windows icon/metadata (needs `rcedit`), macOS signing + notarization (needs paid Apple Developer account).
* Optional Steamworks features (achievements, cloud saves) via the GodotSteam extension — only after validation.
* More content: a Steam premium release needs far more than 24 short levels.

## Recommendation
Keep Steam at "builds ready" until the iPhone playtests show the mechanic is understood and enjoyed.
A **free web/itch.io demo + Steam "Coming Soon" page** is the cheapest way to test demand later.
