import AVFoundation

/// Enregistrement de la voix d'un parent pour un pictogramme (plan §3.3.3).
/// Produit un AAC .m4a stocké dans le modèle.
@Observable
final class AudioRecorderService {

    private(set) var isRecording = false
    private(set) var elapsed: TimeInterval = 0

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var fileURL: URL?

    /// Durée maximale d'un enregistrement : les pictogrammes disent un mot
    /// ou une courte phrase, pas de monologue.
    static let maxDuration: TimeInterval = 10

    /// Demande la permission micro (si besoin) puis démarre l'enregistrement.
    func start() async {
        guard !isRecording else { return }

        guard await requestMicPermission() else { return }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true, options: [])

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("mespictos-\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            ]
            let newRecorder = try AVAudioRecorder(url: url, settings: settings)
            newRecorder.isMeteringEnabled = true
            guard newRecorder.record() else { return }

            recorder = newRecorder
            fileURL = url
            elapsed = 0
            isRecording = true
            startTimer()
        } catch {
            // Micro indisponible : l'éditeur affiche l'état, on reste silencieux.
            isRecording = false
        }
    }

    /// Termine l'enregistrement et renvoie les données audio.
    func stop() -> Data? {
        guard isRecording else { return nil }
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        isRecording = false

        guard let url = fileURL else { return nil }
        defer {
            try? FileManager.default.removeItem(at: url)
            fileURL = nil
            recorder = nil
        }
        return try? Data(contentsOf: url)
    }

    /// Abandonne l'enregistrement sans garder les données.
    func cancel() {
        guard isRecording else { return }
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        recorder?.deleteRecording()
        isRecording = false
        if let url = fileURL {
            try? FileManager.default.removeItem(at: url)
            fileURL = nil
        }
        recorder = nil
    }

    private func startTimer() {
        timer?.invalidate()
        let start = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.elapsed = Date().timeIntervalSince(start)
                if self.elapsed >= Self.maxDuration {
                    _ = self.stop()
                }
            }
        }
    }

    private func requestMicPermission() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            return true
        case .denied:
            return false
        case .undetermined:
            return await AVAudioApplication.requestRecordPermission()
        @unknown default:
            return false
        }
    }
}
