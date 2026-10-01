import Foundation

/// UserDefaults keys. Settings are per device (not synced), so the iPad and the parent's
/// iPhone can use different voices or show-mode options.
enum SettingsKey {
    static let onboardingDone = "onboardingDone"
    static let lastPageID = "lastPageID"

    static let voiceIdentifier = "voiceIdentifier"
    static let speechRate = "speechRate"
    static let speechPitch = "speechPitch"

    static let showModeEnabled = "showModeEnabled"
    static let showDismissMode = "showDismissMode"
    static let showAutoCloseSeconds = "showAutoCloseSeconds"
    static let showCelebration = "showCelebration"

    static let labelStyle = "labelStyle"
    static let showPageTabs = "showPageTabs"
    static let tapInterval = "tapInterval"

    static let parentProtection = "parentProtection"
    static let parentCode = "parentCode"
}

enum SettingsDefault {
    static let speechRate = 0.45
    static let speechPitch = 1.0
    static let showModeEnabled = true
    static let showAutoCloseSeconds = 0
    static let showCelebration = true
    static let showPageTabs = true
    static let tapInterval = 0.6
}

/// How the card shown in the centre is closed.
enum DismissMode: String, CaseIterable, Identifiable {
    /// Tap outside the card, or swipe down.
    case tapOutside
    /// Long press (1 s) outside the card, so the child does not close it before showing it.
    case adultLongPress

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tapOutside: return "Toucher à côté ou glisser vers le bas"
        case .adultLongPress: return "Appui long (adulte)"
        }
    }
}

/// What protects the parent mode, in addition to the 3-second press on the lock.
enum ParentProtection: String, CaseIterable, Identifiable {
    case gestureOnly
    case code
    case deviceAuth

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gestureOnly: return "Appui long seulement"
        case .code: return "Code parent"
        case .deviceAuth: return "Face ID / Touch ID"
        }
    }
}

extension UserDefaults {
    func double(forKey key: String, default value: Double) -> Double {
        object(forKey: key) as? Double ?? value
    }

    func bool(forKey key: String, default value: Bool) -> Bool {
        object(forKey: key) as? Bool ?? value
    }
}
