# Installing Shh…

Shh… is distributed **unsigned** (it isn't signed with a paid Apple Developer certificate). macOS Gatekeeper will block it the first time — that's expected and safe. The steps below get you past it. **You only do this once.**

---

## Step 1 — Download

**[⬇️ Download Shh.dmg](https://github.com/Proph7000/Shh/releases/latest/download/Shh.dmg)**

This link always points to the latest release. You can also browse all versions on the [Releases page](https://github.com/Proph7000/Shh/releases).

## Step 2 — Move to Applications

1. Double-click the downloaded `Shh.dmg` to open it.
2. Drag the **Shh** app onto the **Applications** shortcut in the same window.
3. Eject the DMG.

## Step 3 — Get past Gatekeeper (one time)

Because the app isn't signed by an Apple-registered developer, a normal double-click shows *"Shh… cannot be opened because it is from an unidentified developer"* or *"…is damaged and can't be opened."* Use **either** method.

### Method A — System Settings (no Terminal)
1. Open **Applications**, double-click **Shh** (dismiss the warning that appears).
2. Open **System Settings → Privacy & Security**.
3. Scroll down to the **Security** section — you'll see *"Shh was blocked from use because it is not from an identified developer"* with an **Open Anyway** button. Click it.
4. Confirm with Touch ID or your password. Shh… launches.

### Method B — Terminal (one command)
```sh
xattr -dr com.apple.quarantine /Applications/Shh.app
```
This removes the "downloaded from the internet" quarantine flag that triggers the block. Then just double-click the app.

> **Why is it unsigned?** Signing + notarization requires a paid Apple Developer account. Shh… is a free open-source project distributed via GitHub. You can read every line of the source in this repo and [build it yourself](README.md#building-from-source) if you prefer.

## Step 4 — Grant permissions

On first launch, a welcome window walks you through the permissions Shh… needs. Click **Open Settings** next to each, flip the toggle on, then return to Shh…

| Permission | Required? | Why |
| --- | --- | --- |
| **Accessibility** | ✅ Yes | Lets Shh… capture the global hotkey |
| **Input Monitoring** | ✅ Yes | Required by macOS so keyboard events reach the hotkey listener |
| **Microphone** | ⚪️ Optional | Reserved for a future "mic in use" indicator — **not** needed to mute |

The hotkey starts working the moment Accessibility is granted — no restart needed.

> Shh… lives in the **menu bar only** (no Dock icon). Look for the microphone icon near the clock. Right-click it for the panel, or left-click to toggle mute.

## Updating

Download the newer `Shh.dmg`, drag it into Applications, and replace the old copy. Your settings and permissions are preserved.

## Uninstalling

1. Quit Shh… (right-click the menu-bar icon → Quit).
2. Move `/Applications/Shh.app` to the Trash.
3. (Optional) Remove its preferences:
   ```sh
   defaults delete com.andrieiev.shh
   ```
4. (Optional) Remove it from **System Settings → Privacy & Security → Accessibility / Input Monitoring**.

## Troubleshooting

- **Hotkey doesn't work** → confirm **Accessibility** is ON in System Settings → Privacy & Security, then relaunch Shh….
- **"App is damaged"** → run the Method B command above; this is the quarantine flag, not actual damage.
- **Two mic icons in the menu bar when muted** → the extra one is macOS's own system mute indicator, not a Shh… bug.
- **My Bluetooth headset's play/pause won't toggle mute** → that's a macOS limitation (see [Known limitations](README.md#known-limitations)). Use the keyboard hotkey.
