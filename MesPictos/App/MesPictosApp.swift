import SwiftUI
import SwiftData

@main
struct MesPictosApp: App {
    private let container: ModelContainer

    init() {
        container = Persistence.makeContainer()
        SpeechService.shared.configureSession()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}

struct RootView: View {
    @AppStorage(SettingsKey.onboardingDone) private var onboardingDone = false

    var body: some View {
        if onboardingDone {
            BoardView()
        } else {
            OnboardingView()
        }
    }
}
