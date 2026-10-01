import AVFoundation
import PictoCore

/// Speaks pictograms in French: the recorded voice when there is one, otherwise the iPad's voice.
@MainActor
final class SpeechService {
    static let shared = SpeechService()

    /// Kept for the app's lifetime: a deallocated synthesizer stops speaking.
    private let synthesizer = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?

    private init() {}

    /// `.playback` so the app speaks even when the silent switch is on.
    func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
    }

    /// Avoids a delay on the very first tap.
    func prewarm() {
        let utterance = AVSpeechUtterance(string: " ")
        utterance.volume = 0
        utterance.voice = currentVoice()
        synthesizer.speak(utterance)
    }

    func speak(_ pictogram: Pictogram) {
        speak(label: pictogram.label, spokenText: pictogram.spokenText, recording: pictogram.recordingData)
    }

    func speak(label: String, spokenText: String?, recording: Data?) {
        stop()
        switch SpeechResolver.resolve(label: label, spokenText: spokenText, recording: recording) {
        case .recording(let data):
            if !play(data) {
                speakText(spokenText ?? label)
            }
        case .text(let text):
            speakText(text)
        case .none:
            break
        }
    }

    @discardableResult
    func play(_ recording: Data) -> Bool {
        stop()
        guard let player = try? AVAudioPlayer(data: recording) else { return false }
        self.player = player
        player.prepareToPlay()
        return player.play()
    }

    func speakText(_ text: String) {
        let defaults = UserDefaults.standard
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = currentVoice()
        utterance.rate = Float(defaults.double(forKey: SettingsKey.speechRate, default: SettingsDefault.speechRate))
        utterance.pitchMultiplier = Float(defaults.double(forKey: SettingsKey.speechPitch, default: SettingsDefault.speechPitch))
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        player?.stop()
        player = nil
    }

    func currentVoice() -> AVSpeechSynthesisVoice? {
        let identifier = UserDefaults.standard.string(forKey: SettingsKey.voiceIdentifier) ?? ""
        if !identifier.isEmpty, let voice = AVSpeechSynthesisVoice(identifier: identifier) {
            return voice
        }
        return Self.frenchVoices().first ?? AVSpeechSynthesisVoice(language: "fr-FR")
    }

    /// French voices, best first: fr-FR before other French locales, then premium, enhanced, default.
    nonisolated static func frenchVoices() -> [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("fr") && !$0.voiceTraits.contains(.isNoveltyVoice) }
            .sorted { a, b in
                let aFrance = a.language == "fr-FR"
                let bFrance = b.language == "fr-FR"
                if aFrance != bFrance { return aFrance }
                if a.quality.rawValue != b.quality.rawValue { return a.quality.rawValue > b.quality.rawValue }
                return a.name < b.name
            }
    }

    nonisolated static func qualityName(_ quality: AVSpeechSynthesisVoiceQuality) -> String {
        switch quality {
        case .premium: return "premium"
        case .enhanced: return "améliorée"
        default: return "standard"
        }
    }
}
