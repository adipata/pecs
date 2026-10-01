import Foundation
import SwiftData

/// Fabrique du conteneur SwiftData. La synchronisation iCloud (plan §0 :
/// édition depuis l'iPhone du parent) est tentée en premier ; en cas d'échec
/// (pas de compte iCloud, entitlements absents) l'app repart en local.
enum ModelContainerFactory {

    static func make() -> (container: ModelContainer, cloudSyncActive: Bool) {
        let schema = Schema([Pictogram.self, Page.self, Placement.self])

        let cloudConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        if let cloudContainer = try? ModelContainer(for: schema, configurations: cloudConfig) {
            return (cloudContainer, true)
        }

        let localConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        do {
            let localContainer = try ModelContainer(for: schema, configurations: localConfig)
            return (localContainer, false)
        } catch {
            // Base locale illisible : sans sauvegarde (étape 3 du plan), il n'y a
            // rien de récupérable ; échouer vite vaut mieux que des données fausses.
            fatalError("Impossible de créer la base de données Mes Pictos : \(error)")
        }
    }
}
