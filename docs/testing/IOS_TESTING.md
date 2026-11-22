# Testing GAPLOOM on an iPhone

Three ways. **Path C (cable, no Mac)** installs a real app; **Path A (web)** is the quickest.

---

## Path C — Real app over a USB cable, no Mac (Windows or Mac computer)

GitHub's macOS runners build an **unsigned** `GAPLOOM-unsigned.ipa` on every push
(workflow "Platform builds", artifact `gaploom-ios-unsigned`). A sideloading tool re-signs it with
**your own free Apple ID** and installs it over the cable.

1. Download the ipa: https://github.com/eyazan/gaploom/actions → latest "Platform builds" run →
   *Artifacts* → `gaploom-ios-unsigned` (a zip containing the .ipa; unzip it).
2. Install **Sideloadly** (free, Windows/macOS, https://sideloadly.io). On Windows also install iTunes and
   iCloud from Apple's website (not the Microsoft Store versions) so the iPhone driver is present.
3. Connect the iPhone with the cable, unlock it, tap *Trust this computer*.
4. In Sideloadly: drag the .ipa in, enter your Apple ID, press **Start**. (Sideloadly sends your Apple ID only
   to Apple to create a free signing certificate. If you prefer, create a separate Apple ID for this.)
5. On the iPhone: *Settings → General → VPN & Device Management* → trust your Apple ID;
   iOS 16+: *Settings → Privacy & Security → Developer Mode* → on, restart.
6. Open GAPLOOM from the home screen.

Limits of a free Apple ID: the app stops opening after **7 days** (re-run Sideloadly to refresh); max 3
sideloaded apps. Third-party tool — Anthropic/Claude has no affiliation with it.

---

## Path A — Web build in Safari (no Mac, no Apple account)

The web export is single-threaded, so it needs no special server headers and runs in iOS Safari
(iOS 15+ with WebGL 2). It is also a Progressive Web App: from Safari you can "Add to Home Screen"
and it then opens full-screen in portrait like an app.

### A1. Same Wi-Fi, from any computer (Windows/Mac/Linux) — private, nothing published
1. Get the web build: the `gaploom_web.zip` delivered with the milestone report, or build it yourself:
   ```bash
   godot --headless --export-release "Web" build/web/index.html
   ```
2. Unzip, open a terminal in that folder and run:
   ```bash
   python3 -m http.server 8000
   ```
3. Find the computer's local IP (macOS: System Settings → Wi-Fi → Details; Windows: `ipconfig`).
4. On the iPhone (same Wi-Fi) open Safari → `http://<computer-ip>:8000`.
   * Works for play testing. "Add to Home Screen" works too, but offline caching (service worker) is only
     enabled over HTTPS, so it still needs the computer running.

### A2. HTTPS link (better for repeat testing and for sending to testers) — **this publishes the build**
Options with no cost: an itch.io project set to **Draft / Restricted** (only people with the secret link
can open it; upload the zip as an HTML game, tick "SharedArrayBuffer support" **off**), or GitHub Pages.
This is outward-facing, so it is the owner's call; Claude does not upload anything without approval.

### What to check on the phone (5–10 minutes)
- [ ] Time from tapping the link to seeing Level 1 (on mobile data and on Wi-Fi).
- [ ] Level 1: is it obvious what to do within 10 seconds, without reading the text?
- [ ] Drag a gap with one finger; also try tap-gap-then-tap-destination. Any lag or missed touches?
- [ ] Are the round buttons (undo / restart / hint) comfortable to reach with the thumb?
- [ ] Is anything hidden behind the Dynamic Island / notch or the home-indicator bar?
- [ ] Sound: muted switch on/off; do sounds play after the first touch?
- [ ] Phone warmth / battery after 10 minutes.
- [ ] Levels 7 ("Scaffold") and 14 ("Work Cart"): did you understand *why* you had to open something and then take it back?
- [ ] Add to Home Screen → launch from the icon: full-screen, portrait, correct icon?

Report back in Turkish any way you like; screenshots/screen recordings help most.

---

## Path B — Native iOS app (needs a Mac with Xcode)

Requirements: a Mac with **Xcode** (free from the App Store), a free Apple ID, a USB cable.
A free Apple ID can install on your own iPhone; the app stops opening after **7 days** and must be
re-installed from Xcode. Publishing on TestFlight/App Store needs the paid Apple Developer Program
(USD 99/year) — not needed for this test and requires owner approval.

1. Install Godot 4.5.1 on the Mac, open the project, *Editor → Manage Export Templates → Download*.
2. *Project → Export → iOS*: set **App Store Team ID** (Xcode → Settings → Accounts → your Apple ID → team ID;
   the preset currently holds the placeholder `TEAMID0000`) and a unique **Bundle Identifier**
   (e.g. `com.<yourname>.gaploom`).
3. Export with "Export Project Only" ticked → opens as `gaploom.xcodeproj`.
4. In Xcode: select the project → *Signing & Capabilities* → tick *Automatically manage signing*, choose your
   Personal Team. Plug in the iPhone, select it as the run target, press ▶.
5. First run: on the iPhone, *Settings → General → VPN & Device Management* → trust your developer certificate;
   iOS 16+: also enable *Settings → Privacy & Security → Developer Mode*.

What native adds over Path A: real safe-area handling (the game reads the notch/home-bar insets on native
mobile), app-launch time, true full-screen, and accurate performance/battery.

An Xcode project exported on Linux exists at `build/ios/` (not in git); it is only a convenience — exporting
on the Mac in step 3 is simpler because Godot then embeds your Team ID.
