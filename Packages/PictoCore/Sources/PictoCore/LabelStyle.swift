import Foundation

/// How the label is written under the picture.
public enum LabelStyle: String, CaseIterable, Sendable {
    /// Capital letters, which French children learn first in maternelle.
    case uppercase
    case lowercase
    case asTyped
    case hidden

    public var displayName: String {
        switch self {
        case .uppercase: return "MAJUSCULES"
        case .lowercase: return "minuscules"
        case .asTyped: return "Comme saisi"
        case .hidden: return "Pas de texte"
        }
    }

    /// The text to show, or nil when the label is hidden or empty.
    public func format(_ label: String) -> String? {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let french = Locale(identifier: "fr_FR")
        switch self {
        case .uppercase: return trimmed.uppercased(with: french)
        case .lowercase: return trimmed.lowercased(with: french)
        case .asTyped: return trimmed
        case .hidden: return nil
        }
    }
}
