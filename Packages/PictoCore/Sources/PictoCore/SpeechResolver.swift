import Foundation

/// What to play when a pictogram is selected.
public enum SpeechContent: Equatable, Sendable {
    case recording(Data)
    case text(String)
    case none
}

public enum SpeechResolver {
    /// Priority: recorded voice, then spoken text, then label.
    public static func resolve(label: String, spokenText: String?, recording: Data?) -> SpeechContent {
        if let recording, !recording.isEmpty {
            return .recording(recording)
        }
        if let spoken = spokenText?.trimmingCharacters(in: .whitespacesAndNewlines), !spoken.isEmpty {
            return .text(spoken)
        }
        let label = label.trimmingCharacters(in: .whitespacesAndNewlines)
        return label.isEmpty ? .none : .text(label)
    }
}
