import Foundation
import SwiftUI

// MARK: - Réglages simples

/// Style du libellé sur les cartes (plan §3.3.5).
/// Les enfants apprennent d'abord les MAJUSCULES d'imprimerie à la maternelle.
enum LabelStyle: String, Codable, CaseIterable, Identifiable {
    case uppercase
    case lowercase
    case none

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .uppercase: return "MAJUSCULES"
        case .lowercase: return "minuscules"
        case .none: return "Sans libellé"
        }
    }

    func display(for label: String) -> String? {
        switch self {
        case .uppercase: return label.uppercased()
        case .lowercase: return label.lowercased()
        case .none: return nil
        }
    }
}

/// Comment l'adulte ferme le mode montrer (plan §3.1).
enum ShowModeClose: String, Codable, CaseIterable, Identifiable {
    case tapOutside
    case swipeDown
    case adultOnly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tapOutside: return "Toucher à côté de la carte"
        case .swipeDown: return "Glisser la carte vers le bas"
        case .adultOnly: return "Adulte uniquement (2 doigts ou appui long)"
        }
    }
}

// MARK: - Store

/// Réglages de l'app, persistés dans UserDefaults. Injecté dans l'environnement
/// SwiftUI et lu par `SpeechService`.
@Observable
final class SettingsStore {

    private let defaults: UserDefaults

    private enum Keys {
        static let voiceIdentifier = "settings.voiceIdentifier"
        static let speechRate = "settings.speechRate"
        static let speechPitch = "settings.speechPitch"
        static let labelStyle = "settings.labelStyle"
        static let labelFontScale = "settings.labelFontScale"
        static let showModeEnabled = "settings.showModeEnabled"
        static let showModeClose = "settings.showModeClose"
        static let showModeAutoClose = "settings.showModeAutoCloseSeconds"
        static let showModeCelebration = "settings.showModeCelebration"
        static let tapDebounce = "settings.tapDebounceSeconds"
        static let faceIDEnabled = "settings.faceIDEnabled"
        static let lastPageID = "settings.lastPageID"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        voiceIdentifier = defaults.string(forKey: Keys.voiceIdentifier)
        speechRate = defaults.object(forKey: Keys.speechRate) as? Double ?? 0.5
        speechPitch = defaults.object(forKey: Keys.speechPitch) as? Float ?? 1.0
        labelStyle = LabelStyle(rawValue: defaults.string(forKey: Keys.labelStyle) ?? "") ?? .uppercase
        labelFontScale = defaults.object(forKey: Keys.labelFontScale) as? Double ?? 1.0
        showModeEnabled = defaults.object(forKey: Keys.showModeEnabled) as? Bool ?? true
        showModeClose = ShowModeClose(rawValue: defaults.string(forKey: Keys.showModeClose) ?? "") ?? .tapOutside
        showModeAutoCloseSeconds = defaults.object(forKey: Keys.showModeAutoClose) as? Int ?? 0
        showModeCelebration = defaults.object(forKey: Keys.showModeCelebration) as? Bool ?? false
        tapDebounceSeconds = defaults.object(forKey: Keys.tapDebounce) as? Double ?? 0.35
        faceIDEnabled = defaults.object(forKey: Keys.faceIDEnabled) as? Bool ?? false
        lastPageID = defaults.string(forKey: Keys.lastPageID).flatMap(UUID.init(uuidString:))
    }

    // MARK: Voix (plan §6)

    /// Identifiant de voix `AVSpeechSynthesisVoice`, nil = voix fr-FR par défaut.
    var voiceIdentifier: String? {
        didSet {
            if let voiceIdentifier { defaults.set(voiceIdentifier, forKey: Keys.voiceIdentifier) }
            else { defaults.removeObject(forKey: Keys.voiceIdentifier) }
        }
    }

    /// 0.5 = vitesse d'AVSpeechSynthesizer par défaut.
    var speechRate: Double {
        didSet { defaults.set(speechRate, forKey: Keys.speechRate) }
    }

    var speechPitch: Float {
        didSet { defaults.set(speechPitch, forKey: Keys.speechPitch) }
    }

    // MARK: Étiquettes

    var labelStyle: LabelStyle {
        didSet { defaults.set(labelStyle.rawValue, forKey: Keys.labelStyle) }
    }

    var labelFontScale: Double {
        didSet { defaults.set(labelFontScale, forKey: Keys.labelFontScale) }
    }

    // MARK: Mode montrer (plan §3.1)

    /// Activé : la carte tapée part au centre pour être montrée à un adulte.
    var showModeEnabled: Bool {
        didSet { defaults.set(showModeEnabled, forKey: Keys.showModeEnabled) }
    }

    var showModeClose: ShowModeClose {
        didSet { defaults.set(showModeClose.rawValue, forKey: Keys.showModeClose) }
    }

    /// Fermeture automatique après N secondes ; 0 = désactivé.
    var showModeAutoCloseSeconds: Int {
        didSet { defaults.set(showModeAutoCloseSeconds, forKey: Keys.showModeAutoClose) }
    }

    /// Petite fête visuelle (rebond + halo doux) à l'arrivée de la carte.
    var showModeCelebration: Bool {
        didSet { defaults.set(showModeCelebration, forKey: Keys.showModeCelebration) }
    }

    // MARK: Toucher

    /// Ignore les tapes répétés pendant ce délai, en secondes.
    var tapDebounceSeconds: Double {
        didSet { defaults.set(tapDebounceSeconds, forKey: Keys.tapDebounce) }
    }

    // MARK: Sécurité

    /// Face ID / Touch ID pour entrer en mode parent (le code reste actif en secours).
    var faceIDEnabled: Bool {
        didSet { defaults.set(faceIDEnabled, forKey: Keys.faceIDEnabled) }
    }

    // MARK: Divers

    /// Dernière page ouverte, pour rouvrir dessus (phase II : dispositif toujours prêt).
    var lastPageID: UUID? {
        didSet {
            if let lastPageID { defaults.set(lastPageID.uuidString, forKey: Keys.lastPageID) }
            else { defaults.removeObject(forKey: Keys.lastPageID) }
        }
    }
}
