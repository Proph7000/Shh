// Copyright (c) 2026 Andrii Andrieiev
// Licensed under the Apache License, Version 2.0. See LICENSE for details.

//
//  SecureInputMonitor.swift
//  Shh…
//
//  Detects macOS "Secure Input Mode". When any app enables secure input
//  (a password field, a stuck loginwindow after a credential dialog, some
//  terminals), the system blocks ALL CGEventTaps globally — so the hotkey
//  silently stops working even though the tap is installed and permissions
//  are granted. This looks exactly like an app bug, but it isn't: the fix is
//  to release secure input (close the password field / lock+unlock the
//  screen).
//
//  There's no notification API for secure-input changes, so we poll with a
//  light timer and publish the state; the popover surfaces a banner when it's
//  active so the user knows why the hotkey isn't responding.
//

import Foundation
import Carbon.HIToolbox
import Combine
import OSLog

@MainActor
final class SecureInputMonitor: ObservableObject {
    static let shared = SecureInputMonitor()

    /// True while some process holds Secure Input Mode — the hotkey can't fire.
    @Published private(set) var isActive = false

    private let log = Logger(subsystem: "com.andrieiev.shh", category: "SecureInputMonitor")
    private var timer: Timer?

    private init() {}

    func start() {
        // Poll every 2s — a single cheap Carbon call. Secure input has no
        // change notification, so polling is the only option.
        refresh()
        let timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        timer.tolerance = 0.5
        self.timer = timer
    }

    private func refresh() {
        let active = IsSecureEventInputEnabled()
        if active != isActive {
            isActive = active
            log.info("Secure Input Mode \(active ? "ACTIVATED — hotkey blocked system-wide" : "cleared — hotkey works again")")
        }
    }
}
