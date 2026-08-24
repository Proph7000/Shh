# Shh… — Mute Your Mic on macOS with a Global Hotkey

**Shh…** is a lightweight, native **macOS menu-bar app that mutes and unmutes your microphone with a single global hotkey** — from anywhere, in any app. Apple Silicon native, no Rosetta. Runs on **macOS 14 Sonoma and later**, with a Liquid-Glass UI on **macOS 26 Tahoe**.

It's a modern, open-source alternative to **MuteKey**, which is x86_64-only and stops working once Rosetta is removed.

> **One key. Instant mute. Every app.** Zoom, Google Meet, Microsoft Teams, Discord, Slack huddles, FaceTime, OBS — Shh… mutes the microphone at the system level, so it works no matter which app is listening.

### ⬇️ [Download the latest version (Shh.dmg)](https://github.com/Proph7000/Shh/releases/latest/download/Shh.dmg)

See **[how-to-install.md](how-to-install.md)** for step-by-step setup (the app is unsigned, so there's a one-time Gatekeeper step).

## Screenshots

<p align="center">
  <img src="docs/screenshots/shh-popover.png" alt="Shh… menu-bar popover showing microphone status and per-device mute selection on macOS" width="300">
  &nbsp;
  <img src="docs/screenshots/shh-hud.png" alt="Shh… floating HUD overlay confirming the microphone is muted on macOS" width="220">
</p>

<p align="center">
  <img src="docs/screenshots/shh-preferences-1.png" alt="Shh… Preferences: launch at login, global hotkey, push-to-talk mode and HUD overlay options on macOS" width="420">
  &nbsp;
  <img src="docs/screenshots/shh-preferences-2.png" alt="Shh… Preferences: persistent mic indicator, popover appearance, interface language and permission status on macOS" width="420">
</p>

---

## Why Shh…

- **System-wide mute** — one hotkey silences your mic for *every* app at once, not just the active one. No more hunting for the mute button in each meeting app.
- **Push-to-talk** — hold a key to talk (walkie-talkie) or hold to mute (cough/sneeze silently), on top of plain toggle.
- **Always know your state** — a menu-bar icon, an optional floating HUD, an optional persistent corner badge, and an optional sound tell you instantly whether you're muted.
- **Privacy-first & offline** — no network access, no telemetry, no account. It only talks to CoreAudio.
- **Free & open source** under the Apache-2.0 license.

## Features

- 🎙 **Global hotkey** (default `F4`) — `Toggle`, `Hold to mute`, or `Hold to talk` (push-to-talk)
- 🎛 **Per-device selection** — mute all input devices, or pick specific microphones with checkboxes
- 🟥 **Menu-bar icon** — white mic when live, red slashed mic when muted; left-click toggles, right-click opens the panel
- 🖼 **Floating HUD** on every mute change — 9 placement cells, 3 sizes, adjustable duration, live preview
- 📍 **Persistent corner indicator** — a small red badge stays on screen while muted, visible over fullscreen apps
- 🔊 **Sound feedback** — optional Pop/Tink tone on mute change
- ⚠️ **Hotkey conflict warning** — flags bindings that clash with common macOS shortcuts
- 🔌 **Hot-plug aware** — USB mics / AirPods appear live; a device connected while muted inherits the muted state
- 🚀 **Launch at login**
- 🌐 **Bilingual UI** — English and Ukrainian, switchable at runtime
- ✅ **Live permission status** for Accessibility / Input Monitoring / Microphone, with one-click links to System Settings

## Requirements

- macOS 14 Sonoma or later (Apple Silicon, arm64)
- The full Liquid-Glass look requires macOS 26 Tahoe; on 14/15 surfaces fall back to a standard blur.

## Installation

1. **[Download Shh.dmg](https://github.com/Proph7000/Shh/releases/latest/download/Shh.dmg)**
2. Open the DMG and drag **Shh** into **Applications**.
3. Because the app is unsigned, get past Gatekeeper once — either **System Settings → Privacy & Security → Open Anyway**, or run:
   ```sh
   xattr -dr com.apple.quarantine /Applications/Shh.app
   ```
4. Launch it; the welcome window walks you through the two required permissions.

Full details, screenshots and troubleshooting: **[how-to-install.md](how-to-install.md)**.

## Usage

- **Left-click** the menu-bar mic icon → instant mute toggle
- **Right-click** (or Ctrl-click) → open the panel (state, device selection, settings)
- Press your **hotkey** (default `F4`) from anywhere to toggle
- Right-click → **gear** → Preferences for hotkey, mode, HUD, indicator, language, and permissions

## Building from source

```sh
brew install xcodegen          # if you don't have it
./scripts/make-dev-cert.sh     # one-time: stable self-signed dev cert
./scripts/dev-run.sh           # build → install to /Applications → re-sign → launch
```

Open in Xcode instead: `xcodegen generate && open Shh.xcodeproj`.
Package a DMG: `./scripts/build-dmg.sh` → `build/Shh.dmg`.

## Known limitations

- **Bluetooth headset play/pause button can't toggle mute.** Headsets (Sony WH-CH520, AirPods, …) route play/pause via AVRCP → MediaRemote straight to the active music app; the press never surfaces as a system key, so a menu-bar utility can't intercept it. Use the keyboard hotkey — it works fine while wearing headphones.
- **Virtual / loopback "mics" are hidden.** Devices like "Microsoft Teams Audio" are loopbacks; muting them has no effect on real calls (apps capture from the physical mic), so they're filtered out of the device list.

## Tech

Swift 6 · SwiftUI + AppKit · CoreAudio HAL · CGEventTap · SMAppService · zero third-party dependencies.

## License

[Apache-2.0](LICENSE) © 2026 Andrii Andrieiev. See [NOTICE](NOTICE).

---

<sub>Keywords: macOS microphone mute app, mute mic hotkey Mac, push to talk macOS, menu bar mute, global mute hotkey, MuteKey alternative, Apple Silicon mic mute, mute microphone Zoom Teams Meet Discord, macOS Tahoe.</sub>
