// Copyright (c) 2026 Andrii Andrieiev
// Licensed under the Apache License, Version 2.0. See LICENSE for details.

//
//  AppDelegate.swift
//  Shh…
//
//  Owns the AppKit objects that back the menu bar UI and wires the global
//  hotkey into AudioDeviceManager according to the current ToggleMode.
//

import AppKit
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var cancellables = Set<AnyCancellable>()

    /// Last aggregate mute state we acted on, so HUD/sound fire only on a real
    /// flip and not on every `muteStates` republish from device hot-plug churn.
    private var lastAggregateMuted: Bool?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarController = MenuBarController()

        wireHotkeyCallbacks()
        observePreferencesChanges()
        observeMuteForHUD()
        observeAccessibilityGrant()

        // Triggers the native Accessibility consent alert on first launch if
        // the permission hasn't been granted yet.
        HotkeyManager.shared.start(binding: PreferencesStore.shared.hotkey)

        // Sync the live launch-at-login status into LaunchAtLoginManager
        // (the user might have toggled it in System Settings while we were
        // not running).
        LaunchAtLoginManager.shared.refresh()

        // Permission statuses re-read on every app-became-active.
        PermissionsManager.shared.start()

        // Show the welcome window on first launch (gated by firstLaunchCompleted).
        OnboardingWindowController.shared.showIfNeeded()

        // Persistent floating mic indicator — visible while muted if the
        // user enables the toggle in Preferences.
        PersistentMicIndicatorController.shared.start()

        // Watch for macOS Secure Input Mode, which silently blocks the global
        // hotkey system-wide; the popover surfaces a banner when it's active.
        SecureInputMonitor.shared.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.stop()
    }

    // MARK: - Hotkey ↔ Audio wiring

    /// `onKeyDown` / `onKeyUp` are stable; what changes per mode is the
    /// action they perform on the AudioDeviceManager. Reading the mode at
    /// call time (instead of capturing it) means changing the mode in
    /// Preferences takes effect immediately without re-installing the tap.
    private func wireHotkeyCallbacks() {
        HotkeyManager.shared.onKeyDown = {
            let audio = AudioDeviceManager.shared
            switch PreferencesStore.shared.toggleMode {
            case .toggle:
                audio.toggleMuteActive()
            case .pushToTalkHoldToMute:
                // Default state is unmuted; while held → muted
                audio.setMutedActive(true)
            case .pushToTalkHoldToTalk:
                // Default state is muted; while held → unmuted
                audio.setMutedActive(false)
            }
        }
        HotkeyManager.shared.onKeyUp = {
            let audio = AudioDeviceManager.shared
            switch PreferencesStore.shared.toggleMode {
            case .toggle:
                break
            case .pushToTalkHoldToMute:
                audio.setMutedActive(false)
            case .pushToTalkHoldToTalk:
                audio.setMutedActive(true)
            }
        }
    }

    /// Forward live changes to the hotkey binding into HotkeyManager so the
    /// user doesn't have to relaunch after rebinding it in Preferences.
    private func observePreferencesChanges() {
        PreferencesStore.shared.$hotkey
            .dropFirst() // skip initial value emitted on subscribe
            .sink { binding in
                HotkeyManager.shared.updateBinding(binding)
            }
            .store(in: &cancellables)
    }

    /// When Accessibility flips to granted (e.g. the user just enabled it in
    /// the onboarding flow or System Settings), (re)install the event tap.
    /// `HotkeyManager.start(binding:)` is idempotent — it no-ops if the tap is
    /// already installed — so this safely covers the "granted after launch"
    /// case without requiring an app restart.
    private func observeAccessibilityGrant() {
        PermissionsManager.shared.$accessibility
            .receive(on: DispatchQueue.main)
            .sink { status in
                if status == .granted {
                    HotkeyManager.shared.start(binding: PreferencesStore.shared.hotkey)
                }
            }
            .store(in: &cancellables)
    }

    /// React to mute state changes: HUD (timed or sticky), plus the optional
    /// sound feedback. Drops the initial emission so nothing fires at launch.
    ///
    /// `muteStates` is republished on every `refresh()` — including device
    /// hot-plug churn (a Continuity iPhone or Bluetooth headset coming and
    /// going) that doesn't actually change whether we're muted. We therefore
    /// only flash the HUD and play the sound when the *aggregate* mute state
    /// genuinely flips; otherwise the user hears phantom Pop/Tink tones at
    /// random while devices re-enumerate. The sticky-HUD reconcile still runs
    /// every time so it tracks device changes.
    private func observeMuteForHUD() {
        AudioDeviceManager.shared.$muteStates
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                let muted = AudioDeviceManager.shared.isActiveSelectionMuted
                let changed = self.lastAggregateMuted != muted
                self.lastAggregateMuted = muted

                // Reconcile HUD on every publish (sticky needs it), but only
                // allow the timed flash on a real state change.
                Self.refreshHUD(timedOnMuteChange: changed)

                if changed && PreferencesStore.shared.playSoundFeedback {
                    let soundName: NSSound.Name = muted ? "Pop" : "Tink"
                    NSSound(named: soundName)?.play()
                }
            }
            .store(in: &cancellables)

        // When the user picks a new mode, snap the mic to that mode's resting
        // state (Hold to talk → muted, Hold to mute → live) so push-to-talk
        // starts correctly, then reconcile the sticky HUD.
        PreferencesStore.shared.$toggleMode
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { mode in
                if let restingMuted = mode.defaultMutedState {
                    AudioDeviceManager.shared.setMutedActive(restingMuted)
                }
                Self.refreshHUD(timedOnMuteChange: false)
            }
            .store(in: &cancellables)

        PreferencesStore.shared.$keepHUDWhileLiveInPTT
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { _ in Self.refreshHUD(timedOnMuteChange: false) }
            .store(in: &cancellables)
    }

    /// Central HUD decision. In a push-to-talk mode with "keep HUD while live"
    /// on, a sticky "Mic ON" HUD is shown the whole time the mic is live and
    /// hidden while muted. Otherwise the regular timed HUD flashes on each
    /// mute change (when enabled).
    ///
    /// - Parameter timedOnMuteChange: true when called from an actual mute
    ///   change (allows the timed flash); false when called from a settings
    ///   change (sticky reconcile only, no flash).
    private static func refreshHUD(timedOnMuteChange: Bool) {
        let audio = AudioDeviceManager.shared
        let prefs = PreferencesStore.shared
        let muted = audio.isActiveSelectionMuted
        let scope = makeScopeLabel(audio: audio)

        let stickyMode = prefs.keepHUDWhileLiveInPTT && prefs.toggleMode.isPushToTalk

        if stickyMode {
            if muted {
                // Mic is silent — release the sticky HUD.
                HUDController.shared.hideSticky()
            } else {
                // Mic is live — keep the HUD pinned open.
                HUDController.shared.showSticky(isMuted: false, scopeLabel: scope)
            }
            return
        }

        // Not in sticky mode: make sure any leftover sticky HUD is released,
        // then do the normal timed flash on real mute changes.
        HUDController.shared.hideSticky()
        if timedOnMuteChange && prefs.showHUD {
            HUDController.shared.show(isMuted: muted, scopeLabel: scope)
        }
    }

    /// Human-readable label describing what the current mute action applies
    /// to: "All Devices", a single device's name, or "N Devices".
    private static func makeScopeLabel(audio: AudioDeviceManager) -> String {
        let loc = LocalizationManager.shared
        if PreferencesStore.shared.useAllDevices {
            return loc.t(.scopeAllDevices)
        }
        let active = audio.activeDevices
        switch active.count {
        case 0:  return loc.t(.scopeNoSelection)
        case 1:  return active[0].name
        default: return "\(active.count) \(loc.t(.scopeDevicesSuffix))"
        }
    }
}