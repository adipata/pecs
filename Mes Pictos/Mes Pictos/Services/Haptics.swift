import UIKit

/// Retours haptiques discrets (plan §3.1) : la voix est la récompense,
/// le haptique confirme le choix.
enum Haptics {
    /// Tap léger à la sélection d'une carte.
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Confirmation d'une action adulte (déverrouillage, déplacement réussi).
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Signal doux quand une action est refusée (page pleine…).
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
