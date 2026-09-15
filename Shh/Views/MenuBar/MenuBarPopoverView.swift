// Copyright (c) 2026 Andrii Andrieiev
// Licensed under the Apache License, Version 2.0. See LICENSE for details.

//
//  MenuBarPopoverView.swift
//  Shh…
//
//  SwiftUI content hosted inside the NSPopover anchored to the menu bar status
//  item. Opened via right-click (or Ctrl+left-click) on the menu bar icon.
//

import SwiftUI

struct MenuBarPopoverView: View {
    @ObservedObject var audio: AudioDeviceManager
    @ObservedObject private var preferences = PreferencesStore.shared
    @ObservedObject private var loc = LocalizationManager.shared
    @ObservedObject private var secureInput = SecureInputMonitor.shared

    var body: some View {
        VStack(spacing: 16) {
            if secureInput.isActive {
                secureInputBanner
            }

            stateCircle

            Text(audio.isActiveSelectionMuted ? loc.t(.micOff) : loc.t(.micOn))
                .font(.headline)
                .foregroundStyle(.primary)

            Button {
                audio.toggleMuteActive()
            } label: {
                Text(toggleButtonLabel)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.return)
            .disabled(audio.activeDevices.isEmpty)

            if !audio.inputDevices.isEmpty {
                Divider()
                deviceList
            }

            Spacer(minLength: 0)

            Divider()

            HStack {
                Button {
                    openPreferencesWindow()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(",", modifiers: .command)
                .help(loc.t(.preferencesTooltip))

                Spacer()

                Button(loc.t(.quit)) {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("q")
                .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(width: 320, height: 440)
        // NSPanel is transparent (no backdrop like NSPopover provides), so
        // the SwiftUI view supplies its own Liquid-Glass blur background.
        // The slider in Preferences picks one of SwiftUI's discrete Material
        // levels — that's the API that actually changes blur intensity (an
        // alpha overlay alone barely moves the needle on bright wallpapers).
        .background(selectedMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
        )
    }

    /// Map the 0...1 slider value to one of SwiftUI's five discrete Material
    /// variants. Lower values = more see-through; higher = more opaque.
    private var selectedMaterial: Material {
        let level = preferences.popoverTintLevel
        switch level {
        case ..<0.2: return .ultraThinMaterial
        case ..<0.4: return .thinMaterial
        case ..<0.6: return .regularMaterial
        case ..<0.8: return .thickMaterial
        default:     return .ultraThickMaterial
        }
    }

    /// Shown only while macOS Secure Input Mode is active — it blocks the
    /// global hotkey system-wide, which otherwise looks like an app bug.
    private var secureInputBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 14))
            VStack(alignment: .leading, spacing: 2) {
                Text(loc.t(.secureInputTitle))
                    .font(.caption.weight(.semibold))
                Text(loc.t(.secureInputHint))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(.orange.opacity(0.35), lineWidth: 0.5)
        )
    }

    private var stateCircle: some View {
        Button {
            audio.toggleMuteActive()
        } label: {
            ZStack {
                Circle()
                    .fill(.regularMaterial)
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 2)

                Image(systemName: audio.isActiveSelectionMuted ? "mic.slash.fill" : "mic.fill")
                    .font(.system(size: 56, weight: .regular))
                    .foregroundStyle(audio.isActiveSelectionMuted ? AnyShapeStyle(.red.opacity(0.85)) : AnyShapeStyle(.primary))
                    .symbolRenderingMode(.hierarchical)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .buttonStyle(.plain)
        .help(audio.isActiveSelectionMuted ? loc.t(.toggleCircleHelpUnmute) : loc.t(.toggleCircleHelpMute))
    }

    /// "Mute All" / "Unmute All" when all devices are in scope,
    /// "Mute Selected" / "Unmute Selected" when a subset is selected.
    private var toggleButtonLabel: String {
        let isMuted = audio.isActiveSelectionMuted
        switch (preferences.useAllDevices, isMuted) {
        case (true, true):   return loc.t(.unmuteAll)
        case (true, false):  return loc.t(.muteAll)
        case (false, true):  return loc.t(.unmuteSelected)
        case (false, false): return loc.t(.muteSelected)
        }
    }

    /// Open the Preferences window. Goes through `PreferencesWindowController`
    /// (a plain AppKit-managed NSWindow) rather than SwiftUI's Settings scene
    /// because the gear button lives inside an NSPanel — outside the Scene
    /// responder chain that `showSettingsWindow:` walks.
    private func openPreferencesWindow() {
        PreferencesWindowController.shared.show()
    }

    private func deviceIconName(for device: AudioDevice) -> String {
        guard device.isControllable else { return "mic.fill" }
        return audio.muteStates[device.uid] == true ? "mic.slash.fill" : "mic.fill"
    }

    private func deviceIconColor(for device: AudioDevice) -> AnyShapeStyle {
        guard device.isControllable else { return AnyShapeStyle(.tertiary) }
        return audio.muteStates[device.uid] == true
            ? AnyShapeStyle(.red.opacity(0.75))
            : AnyShapeStyle(.secondary)
    }

    /// SwiftUI's native `Toggle(.switch)` on macOS 26 Liquid Glass ignores
    /// `.tint` / `SwitchToggleStyle(tint:)` — the switch always renders in
    /// the system grey. We need a visibly-blue "ON" state for the All
    /// switch, so we draw it ourselves with a Capsule + sliding knob.
    private var customAllToggle: some View {
        Button {
            preferences.useAllDevices.toggle()
        } label: {
            ZStack(alignment: preferences.useAllDevices ? .trailing : .leading) {
                Capsule()
                    .fill(preferences.useAllDevices ? Color.accentColor : Color.gray.opacity(0.35))
                    .frame(width: 30, height: 16)
                Circle()
                    .fill(.white)
                    .frame(width: 12, height: 12)
                    .shadow(color: .black.opacity(0.25), radius: 1, y: 0.5)
                    .padding(.horizontal, 2)
            }
            .animation(.easeInOut(duration: 0.15), value: preferences.useAllDevices)
        }
        .buttonStyle(.plain)
        .help(preferences.useAllDevices ? loc.t(.allToggleHelpOn) : loc.t(.allToggleHelpOff))
    }

    private var deviceList: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(loc.t(.inputDevices))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
                Text(loc.t(.allToggle))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                customAllToggle
            }

            ForEach(audio.inputDevices) { device in
                deviceRow(device)
            }
        }
    }

    @ViewBuilder
    private func deviceRow(_ device: AudioDevice) -> some View {
        HStack(spacing: 8) {
            if device.isControllable {
                Button {
                    toggleSelection(device)
                } label: {
                    Image(systemName: isSelected(device) ? "checkmark.square.fill" : "square")
                        .foregroundStyle(isSelected(device) ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.secondary))
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .disabled(preferences.useAllDevices)
                .help(preferences.useAllDevices ? "Turn off 'All' to pick specific devices" : (isSelected(device) ? "Remove from selection" : "Add to selection"))
            } else {
                Image(systemName: "square.slash")
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 13))
            }

            Image(systemName: deviceIconName(for: device))
                .foregroundStyle(deviceIconColor(for: device))
                .font(.system(size: 13))
                .frame(width: 16)

            Text(device.name)
                .font(.subheadline)
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(device.isControllable ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))

            if device.isDefaultInput {
                Text(loc.t(.badgeDefault))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }

            if !device.isControllable {
                Text(loc.t(.badgeNoControl))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary.opacity(0.5), in: Capsule())
            }

            Spacer()
        }
    }

    /// True if the device is currently subject to mute actions —
    /// either we're in "All" mode (everything controllable is in scope),
    /// or it's been picked individually.
    private func isSelected(_ device: AudioDevice) -> Bool {
        guard device.isControllable else { return false }
        if preferences.useAllDevices { return true }
        return preferences.selectedDeviceUIDs.contains(device.uid)
    }

    private func toggleSelection(_ device: AudioDevice) {
        guard device.isControllable, !preferences.useAllDevices else { return }
        if preferences.selectedDeviceUIDs.contains(device.uid) {
            preferences.selectedDeviceUIDs.remove(device.uid)
        } else {
            preferences.selectedDeviceUIDs.insert(device.uid)
        }
    }
}