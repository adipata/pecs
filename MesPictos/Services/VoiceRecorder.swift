import AVFoundation
import Observation

/// Records the parent's voice for a pictogram.
@MainActor
@Observable
final class VoiceRecorder {
    private(set) var isRecording = false
    private(set) var permissionDenied = false
    private(set) var errorMessage: String?

    @ObservationIgnored private var recorder: AVAudioRecorder?
    @ObservationIgnored private let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("mespictos-recording.m4a")

    func start() async {
        errorMessage = nil
        let granted = await AVAudioApplication.requestRecordPermission()
        guard granted else {
            permissionDenied = true
            return
        }
        permissionDenied = false
        SpeechService.shared.stop()

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            try? FileManager.default.removeItem(at: fileURL)
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            ]
            let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            guard recorder.record() else {
                errorMessage = "L'enregistrement n'a pas pu démarrer."
                SpeechService.shared.configureSession()
                return
            }
            self.recorder = recorder
            isRecording = true
        } catch {
            errorMessage = "L'enregistrement n'a pas pu démarrer."
            SpeechService.shared.configureSession()
        }
    }

    /// Stops and returns the recorded audio.
    func stop() -> Data? {
        guard let recorder else { return nil }
        recorder.stop()
        self.recorder = nil
        isRecording = false
        SpeechService.shared.configureSession()
        let data = try? Data(contentsOf: fileURL)
        try? FileManager.default.removeItem(at: fileURL)
        return (data?.isEmpty ?? true) ? nil : data
    }
}
