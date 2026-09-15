// Copyright (c) 2026 Andrii Andrieiev
// Licensed under the Apache License, Version 2.0. See LICENSE for details.

//
//  LocalizationManager.swift
//  Shh…
//
//  Runtime UI localization, independent of the macOS system language. Views
//  observe this singleton (`@ObservedObject`) and call `t(.key)`; flipping
//  `language` re-renders them with the new strings. AppKit call sites read
//  `t(.key)` imperatively and refresh themselves.
//
//  English is the default. Adding a language = add a case to AppLanguage and
//  a column in the `table` below.
//

import Foundation
import Combine

enum LocKey: String, CaseIterable {
    // Menu bar popover
    case micOn, micOff
    case muteAll, unmuteAll, muteSelected, unmuteSelected
    case inputDevices, allToggle, badgeDefault, badgeNoControl
    case quit
    case preferencesTooltip
    case toggleCircleHelpMute, toggleCircleHelpUnmute
    case allToggleHelpOn, allToggleHelpOff
    case secureInputTitle, secureInputHint

    // HUD
    case hudMicOn, hudMicOff
    case scopeAllDevices, scopeNoSelection, scopeDevicesSuffix, scopePreview

    // Preferences — sections
    case secGeneral, secHotkey, secHUD, secIndicator, secPopover, secPermissions

    // General
    case launchAtLogin, playSound, generalFooter

    // Hotkey & mode
    case hotkey, mode
    case modeToggle, modeHoldToMute, modeHoldToTalk
    case hintToggle, hintHoldToMute, hintHoldToTalk
    case keepHUDLive, keepHUDLiveDesc
    case pressHotkey, conflictPrefix

    // HUD section
    case showHUD, horizontal, vertical, size, displayDuration, hudFooter, secondsUnit
    case alignLeft, alignCenter, alignRight, alignTop, alignBottom
    case sizeSmall, sizeMedium, sizeLarge

    // Indicator
    case showIndicator, corner, indicatorFooter
    case cornerTopLeft, cornerTopRight, cornerBottomLeft, cornerBottomRight

    // Popover appearance
    case background, popoverFooter
    case matUltraThin, matThin, matRegular, matThick, matUltraThick

    // Permissions
    case permFooter, optional, openSettings
    case permAccessibility, permInputMonitoring, permMicrophone
    case permAccessibilityWhy, permInputMonitoringWhy, permMicrophoneWhy

    // Language
    case secLanguage, language

    // Onboarding
    case welcomeTitle, welcomeBody, getStarted
    case onbPermBlurb, onbAllGranted, onbGrantToContinue
}

@MainActor
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    private static let key = "appLanguage"

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Self.key)
        }
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: Self.key),
           let lang = AppLanguage(rawValue: raw) {
            self.language = lang
        } else {
            self.language = .en
        }
    }

    /// Localized string for the current language.
    func t(_ key: LocKey) -> String {
        let pair = Self.table[key] ?? (key.rawValue, key.rawValue)
        switch language {
        case .en: return pair.0
        case .uk: return pair.1
        }
    }

    // (english, ukrainian)
    private static let table: [LocKey: (String, String)] = [
        .micOn:  ("Microphone ON", "Мікрофон увімкнено"),
        .micOff: ("Microphone OFF", "Мікрофон вимкнено"),
        .muteAll:        ("Mute All", "Вимкнути всі"),
        .unmuteAll:      ("Unmute All", "Увімкнути всі"),
        .muteSelected:   ("Mute Selected", "Вимкнути обрані"),
        .unmuteSelected: ("Unmute Selected", "Увімкнути обрані"),
        .inputDevices:   ("Input Devices", "Пристрої вводу"),
        .allToggle:      ("All", "Всі"),
        .badgeDefault:   ("default", "за умовч."),
        .badgeNoControl: ("no control", "без контролю"),
        .quit:           ("Quit", "Вийти"),
        .preferencesTooltip: ("Preferences", "Налаштування"),
        .toggleCircleHelpMute:   ("Mute (or click the icon in menu bar)", "Вимкнути (або клацніть іконку в меню-барі)"),
        .toggleCircleHelpUnmute: ("Unmute (or click the icon in menu bar)", "Увімкнути (або клацніть іконку в меню-барі)"),
        .allToggleHelpOn:  ("Switch to per-device selection", "Перейти до вибору окремих пристроїв"),
        .allToggleHelpOff: ("Apply to all controllable devices", "Застосувати до всіх керованих пристроїв"),
        .secureInputTitle: ("Hotkey blocked by Secure Input", "Гарячу клавішу блокує Secure Input"),
        .secureInputHint:  ("Another app (a password field, or a stuck login prompt) has turned on macOS Secure Input, which blocks the hotkey system-wide. Close password fields, or lock and unlock the screen (⌃⌘Q), to restore it. Clicking the icon still works.",
                            "Інша програма (поле пароля або застряглий запит входу) увімкнула macOS Secure Input, що блокує гарячу клавішу в усій системі. Закрийте поля пароля або заблокуйте й розблокуйте екран (⌃⌘Q), щоб відновити. Клік по іконці працює як завжди."),

        .hudMicOn:  ("Mic ON", "Мік увімкнено"),
        .hudMicOff: ("Mic OFF", "Мік вимкнено"),
        .scopeAllDevices:    ("All Devices", "Всі пристрої"),
        .scopeNoSelection:   ("No Selection", "Нічого не обрано"),
        .scopeDevicesSuffix: ("Devices", "пристроїв"),
        .scopePreview:       ("Preview", "Перегляд"),

        .secGeneral:     ("General", "Загальні"),
        .secHotkey:      ("Hotkey & mode", "Гаряча клавіша та режим"),
        .secHUD:         ("HUD overlay", "HUD-оверлей"),
        .secIndicator:   ("Persistent indicator", "Постійний індикатор"),
        .secPopover:     ("Popover appearance", "Вигляд вікна"),
        .secPermissions: ("Permissions", "Дозволи"),

        .launchAtLogin: ("Launch at login", "Запускати під час входу"),
        .playSound:     ("Play sound on mute change", "Звук при зміні стану"),
        .generalFooter: ("The sound feedback plays a short system tone (Pop for mute, Tink for unmute) so you can tell by ear when the HUD is hidden.",
                         "Звуковий сигнал відтворює короткий системний тон (Pop — вимкнення, Tink — увімкнення), щоб орієнтуватися на слух, коли HUD прихований."),

        .hotkey: ("Hotkey", "Гаряча клавіша"),
        .mode:   ("Mode", "Режим"),
        .modeToggle:     ("Toggle", "Перемикання"),
        .modeHoldToMute: ("Hold to mute (default on)", "Утримувати щоб вимкнути (типово увімк.)"),
        .modeHoldToTalk: ("Hold to talk (default muted)", "Утримувати щоб говорити (типово вимк.)"),
        .hintToggle:     ("Press the hotkey once to switch between muted and unmuted.",
                          "Натисніть клавішу один раз, щоб перемкнути між увімкнено та вимкнено."),
        .hintHoldToMute: ("Mic is on by default. Hold the hotkey to mute (e.g. for a quick cough or sneeze); release to unmute.",
                          "Мікрофон типово увімкнений. Утримуйте клавішу, щоб вимкнути (напр., кашлянути); відпустіть, щоб увімкнути."),
        .hintHoldToTalk: ("Mic is muted by default. Hold the hotkey to talk (walkie-talkie); release to mute.",
                          "Мікрофон типово вимкнений. Утримуйте клавішу, щоб говорити (рація); відпустіть, щоб вимкнути."),
        .keepHUDLive:     ("Keep HUD visible while mic is live", "Тримати HUD, поки мікрофон активний"),
        .keepHUDLiveDesc: ("In push-to-talk, pins the “Mic ON” HUD on screen the whole time you're being heard, so you always know your mic is live. Only applies in the two push-to-talk modes.",
                           "У режимі push-to-talk закріплює HUD «Мік увімкнено» на екрані, поки вас чути, щоб ви завжди знали, що мікрофон активний. Діє лише у двох режимах push-to-talk."),
        .pressHotkey:    ("Press a hotkey…", "Натисніть клавішу…"),
        .conflictPrefix: ("May conflict with", "Може конфліктувати з"),

        .showHUD:         ("Show HUD on mute change", "Показувати HUD при зміні стану"),
        .horizontal:      ("Horizontal", "По горизонталі"),
        .vertical:        ("Vertical", "По вертикалі"),
        .size:            ("Size", "Розмір"),
        .displayDuration: ("Display duration", "Тривалість показу"),
        .hudFooter:       ("The floating overlay briefly appears on the main display when the mute state changes.",
                           "Плаваючий оверлей коротко з'являється на головному дисплеї при зміні стану мікрофона."),
        .secondsUnit:     ("s", "с"),
        .alignLeft:   ("Left", "Ліворуч"),
        .alignCenter: ("Center", "По центру"),
        .alignRight:  ("Right", "Праворуч"),
        .alignTop:    ("Top", "Зверху"),
        .alignBottom: ("Bottom", "Знизу"),
        .sizeSmall:   ("Small", "Малий"),
        .sizeMedium:  ("Medium", "Середній"),
        .sizeLarge:   ("Large", "Великий"),

        .showIndicator:   ("Show persistent mic indicator", "Показувати постійний індикатор"),
        .corner:          ("Corner", "Кут"),
        .indicatorFooter: ("A small red mic badge stays in the chosen corner of the main display whenever any selected mic is muted — visible over fullscreen apps and across Spaces.",
                           "Невеликий червоний значок мікрофона залишається в обраному куті головного дисплея, поки будь-який обраний мікрофон вимкнений — видно поверх повноекранних застосунків і просторів."),
        .cornerTopLeft:     ("Top Left", "Верхній лівий"),
        .cornerTopRight:    ("Top Right", "Верхній правий"),
        .cornerBottomLeft:  ("Bottom Left", "Нижній лівий"),
        .cornerBottomRight: ("Bottom Right", "Нижній правий"),

        .background:    ("Background", "Фон"),
        .popoverFooter: ("Slide left for a strongly see-through Liquid-Glass look; slide right for a more opaque panel that stays readable on bright wallpapers.",
                         "Ліворуч — максимально прозорий Liquid-Glass; праворуч — щільніша панель, що лишається читабельною на світлих шпалерах."),
        .matUltraThin:  ("Ultra thin", "Дуже тонкий"),
        .matThin:       ("Thin", "Тонкий"),
        .matRegular:    ("Regular", "Звичайний"),
        .matThick:      ("Thick", "Щільний"),
        .matUltraThick: ("Ultra thick", "Дуже щільний"),

        .permFooter:   ("Statuses refresh automatically each time you return to the app from System Settings.",
                        "Статуси оновлюються автоматично щоразу, коли ви повертаєтесь до застосунку із Системних налаштувань."),
        .optional:     ("optional", "необов'язково"),
        .openSettings: ("Open Settings", "Відкрити налаштування"),
        .permAccessibility:   ("Accessibility", "Доступність"),
        .permInputMonitoring: ("Input Monitoring", "Моніторинг вводу"),
        .permMicrophone:      ("Microphone", "Мікрофон"),
        .permAccessibilityWhy:   ("Required to capture the global hotkey via CGEventTap.",
                                  "Потрібно для перехоплення глобальної гарячої клавіші через CGEventTap."),
        .permInputMonitoringWhy: ("Required by macOS so keyboard events reach the hotkey listener.",
                                  "Потрібно macOS, щоб події клавіатури досягали слухача гарячої клавіші."),
        .permMicrophoneWhy:      ("Optional. Reserved for the future \"mic in use by X\" indicator.",
                                  "Необов'язково. Зарезервовано для майбутнього індикатора «мікрофон використовує X»."),

        .secLanguage: ("Language", "Мова"),
        .language:    ("Interface language", "Мова інтерфейсу"),

        .welcomeTitle: ("Welcome to Shh…", "Ласкаво просимо до Shh…"),
        .welcomeBody:  ("Mute or push-to-talk your microphone with a single keypress, system-wide.",
                        "Вимикайте мікрофон або говоріть у режимі push-to-talk одним натисканням, по всій системі."),
        .getStarted:   ("Get started", "Почати"),
        .onbPermBlurb: ("Shh… needs the two required permissions below to capture the global hotkey. Microphone access is optional and unrelated to mute itself.",
                        "Shh… потрібні два обов'язкові дозволи нижче, щоб перехоплювати глобальну гарячу клавішу. Доступ до мікрофона необов'язковий і не пов'язаний із самим вимкненням."),
        .onbAllGranted:      ("All required permissions are granted.", "Усі обов'язкові дозволи надано."),
        .onbGrantToContinue: ("Grant the required permissions to continue.", "Надайте обов'язкові дозволи, щоб продовжити."),
    ]
}