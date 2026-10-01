import AVFoundation

/// Synthèse et lecture vocale. Un seul synthétiseur vivant pendant toute
/// la session (le synthétiseur s'arrête s'il est libéré, plan §6).
///
/// Priorité de lecture (plan §6) : 1. l'enregistrement de la voix du parent,
/// 2. le texte prononcé, 3. le libellé.
@Observable
final class SpeechService {

    private let settings: SettingsStore
    private let synthesizer = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?

    init(settings: SettingsStore) {
        self.settings = settings
        configureAudioSession()
        observeInterruptions()
    }

    /// `.playback` : la voix parle même si le commutateur silencieux est
    /// activé — problème classique des apps de communication (plan §6).
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true, options: [])
    }

    private func activate() {
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(true, options: [])
    }

    private func observeInterruptions() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self,
                  let info = note.userInfo,
                  let raw = (info[AVAudioSessionInterruptionTypeKey] as? NSNumber)?.uint32Value,
                  AVAudioSession.InterruptionType(rawValue: UInt(raw)) == .began else { return }
            Task { @MainActor in
                self.stop()
            }
        }
    }

    /// Chauffe le moteur TTS au lancement pour éviter le délai du premier tap.
    func prewarm() {
        let utterance = AVSpeechUtterance(string: " ")
        utterance.volume = 0
        utterance.rate = 0.5
        utterance.voice = AVSpeechSynthesisVoice(language: "fr-FR")
        synthesizer.speak(utterance)
    }

    /// Remet la session en lecture après un enregistrement (le micro passe
    /// la session en `playAndRecord`, ce qui changerait le haut-parleur utilisé).
    func restorePlaybackCategory() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true, options: [])
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        player?.stop()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    /// Dit un pictogramme à voix haute.
    func speak(_ pictogram: Pictogram) {
        stop()
        activate()
        switch Self.playbackContent(for: pictogram) {
        case .recording(let data):
            playRecording(data)
        case .text(let text):
            speakText(text)
        case nil:
            break
        }
    }

    /// Contenu à jouer pour un pictogramme, selon la priorité du plan §6 :
    /// 1. l'enregistrement, 2. le texte prononcé, 3. le libellé.
    /// Fonction pure, testée unitairement.
    static func playbackContent(for pictogram: Pictogram) -> PlaybackContent? {
        if let recording = pictogram.recording, !recording.isEmpty {
            return .recording(recording)
        }
        let text = (pictogram.spokenText ?? pictogram.label)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        return .text(text)
    }

    /// Ce qu'il faut jouer pour une carte.
    enum PlaybackContent: Equatable {
        case recording(Data)
        case text(String)
    }

    /// Lit un texte avec la voix choisie dans les réglages.
    func speakText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = resolveVoice()
        utterance.rate = Float(settings.speechRate)
        utterance.pitchMultiplier = settings.speechPitch
        utterance.volume = 1
        synthesizer.speak(utterance)
    }

    /// Pré-écoute d'une voix dans les réglages.
    func preview(voice: AVSpeechSynthesisVoice) {
        stop()
        activate()
        let utterance = AVSpeechUtterance(string: "Bonjour ! Je veux une pomme.")
        utterance.voice = voice
        utterance.rate = Float(settings.speechRate)
        utterance.pitchMultiplier = settings.speechPitch
        synthesizer.speak(utterance)
    }

    /// Joue un extrait enregistré (AAC .m4a).
    func playRecording(_ data: Data) {
        guard let audioPlayer = try? AVAudioPlayer(data: data) else { return }
        player = audioPlayer
        player?.play()
    }

    private func resolveVoice() -> AVSpeechSynthesisVoice? {
        if let identifier = settings.voiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: identifier) {
            return voice
        }
        return AVSpeechSynthesisVoice(language: "fr-FR")
    }

    /// Voix françaises disponibles sur l'appareil, triées par qualité.
    static func frenchVoices() -> [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("fr") }
            .sorted { lhs, rhs in
                let lq = qualityRank(lhs.quality)
                let rq = qualityRank(rhs.quality)
                if lq != rq { return lq > rq }
                return lhs.name < rhs.name
            }
    }

    private static func qualityRank(_ quality: AVSpeechSynthesisVoiceQuality) -> Int {
        switch quality {
        case .premium: return 3
        case .enhanced: return 2
        case .default: return 1
        default: return 0
        }
    }
}
