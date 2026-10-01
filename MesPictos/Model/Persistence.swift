import Foundation
import SwiftData

enum Persistence {
    static let schema = Schema([Pictogram.self, Page.self, Placement.self])

    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    /// The app's store. Syncs through the iCloud container declared in the entitlements, when there is one.
    static func makeContainer() -> ModelContainer {
        if isRunningTests {
            return makeInMemoryContainer()
        }
        do {
            let config = ModelConfiguration("MesPictos", schema: schema, cloudKitDatabase: .automatic)
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            print("Could not open the iCloud store (\(error)). Falling back to a local store.")
        }
        do {
            let config = ModelConfiguration("MesPictos", schema: schema, cloudKitDatabase: .none)
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Impossible d'ouvrir la base de données : \(error)")
        }
    }

    static func makeInMemoryContainer() -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Impossible de créer la base de test : \(error)")
        }
    }
}
