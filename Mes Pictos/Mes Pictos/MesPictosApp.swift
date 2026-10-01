import SwiftUI
import SwiftData

@main
struct MesPictosApp: App {

    /// Conteneur partagé par tout le cycle de vie de l'app.
    private let container: ModelContainer
    private let settings: SettingsStore
    private let speech: SpeechService
    private let cloudSyncActive: Bool

    init() {
        let made = ModelContainerFactory.make()
        container = made.container
        cloudSyncActive = made.cloudSyncActive
        settings = SettingsStore()
        speech = SpeechService(settings: settings)
    }

    var body: some Scene {
        WindowGroup {
            RootView(cloudSyncActive: cloudSyncActive)
                .modelContainer(container)
                .environment(settings)
                .environment(speech)
        }
    }
}

/// Racine de l'interface : alterne entre le tableau de l'enfant et l'édition
/// du parent. La page courante est partagée entre les deux modes.
struct RootView: View {

    @Environment(\.modelContext) private var context
    @Environment(SpeechService.self) private var speech
    @Environment(SettingsStore.self) private var settings

    @State private var isParentMode = false
    @State private var currentPageID: UUID?

    private let cloudSyncActive: Bool

    init(cloudSyncActive: Bool) {
        self.cloudSyncActive = cloudSyncActive
    }

    var body: some View {
        Group {
            if isParentMode {
                EditBoardView(isParentMode: $isParentMode, currentPageID: $currentPageID)
            } else {
                BoardView(isParentMode: $isParentMode, currentPageID: $currentPageID)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isParentMode)
        .task {
            SeedData.seedIfNeeded(context: context)
            speech.prewarm()
        }
        .onChange(of: currentPageID) { _, newValue in
            if let newValue { settings.lastPageID = newValue }
        }
        .environment(\.cloudSyncActive, cloudSyncActive)
    }
}

extension EnvironmentValues {
    /// Indique si les données sont synchronisées via iCloud (booléen figé au lancement).
    var cloudSyncActive: Bool {
        get { self[CloudSyncKey.self] }
        set { self[CloudSyncKey.self] = newValue }
    }
}

struct CloudSyncKey: EnvironmentKey {
    static let defaultValue = false
}
