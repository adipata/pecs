import Foundation
import Observation

/// Kit de démarrage embarqué (plan §5) : pictogrammes ARASAAC groupés par
/// catégories, disponibles hors ligne dès le premier lancement. Les images
/// sont dans le bundle, le manifeste liste id / mot-clé français / catégorie.
///
/// `@Observable` : la vue qui affiche le kit se rafraîchit dès que le
/// manifeste est chargé (la feuille peut s'afficher avant la fin du chargement).
@Observable
final class BundledProvider: SymbolProvider {

    let id = "bundled"
    let displayName = "Kit de démarrage"
    let attribution = SymbolAttribution.arasaac

    struct Item: Codable, Identifiable, Hashable {
        /// Id ARASAAC du pictogramme.
        let id: String
        let keyword: String
        let category: String
    }

    struct Manifest: Codable {
        let format: String
        let version: Int
        let licence: String
        let attribution: String
        let items: [Item]
    }

    /// Éléments du kit. Settable directement pour les tests unitaires ;
    /// le chemin normal passe par `load(from:)`.
    var items: [Item] = []
    /// Dossier du bundle contenant le manifeste et les images.
    private var manifestDirectory: URL?

    // MARK: - Chargement

    /// Charge le manifeste depuis le bundle. Sans kit embarqué, ne lève pas :
    /// l'app reste utilisable avec la recherche ARASAAC en ligne.
    func load(from bundle: Bundle = .main) throws {
        guard let manifestURL = Self.locateManifest(in: bundle) else { return }
        let data = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(Manifest.self, from: data)
        items = manifest.items
        manifestDirectory = manifestURL.deletingLastPathComponent()
    }

    /// Le manifeste peut se trouver dans un sous-dossier (structure
    /// préservée) ou à la racine du bundle (ressources aplaties).
    static func locateManifest(in bundle: Bundle) -> URL? {
        if let url = bundle.url(forResource: "manifest", withExtension: "json", subdirectory: "StarterPack") {
            return url
        }
        if let url = bundle.url(forResource: "manifest", withExtension: "json", subdirectory: "StarterPack/images") {
            return url.deletingLastPathComponent().deletingLastPathComponent()
        }
        return bundle.urls(forResourcesWithExtension: "json", subdirectory: nil)?
            .first { $0.lastPathComponent == "manifest.json" }
    }

    // MARK: - Catalogue

    /// Catégories dans l'ordre de leur première apparition.
    var categories: [String] {
        var seen: Set<String> = []
        var ordered: [String] = []
        for item in items where !seen.contains(item.category) {
            seen.insert(item.category)
            ordered.append(item.category)
        }
        return ordered
    }

    func hits(in category: String) -> [SymbolHit] {
        items.filter { $0.category == category }.map(Self.hit(for:))
    }

    func search(_ query: String, language: String = "fr") async throws -> [SymbolHit] {
        let needle = Self.fold(query.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !needle.isEmpty else { return [] }
        return items
            .filter { Self.fold($0.keyword).contains(needle) }
            .map(Self.hit(for:))
    }

    /// Recherche insensible à la casse et aux accents : « gateau » trouve « gâteau ».
    private static func fold(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR"))
    }

    private static func hit(for item: Item) -> SymbolHit {
        SymbolHit(id: item.id, providerID: "bundled", label: item.keyword, thumbnailURL: nil)
    }

    // MARK: - Images

    func image(for hit: SymbolHit, options: SymbolOptions) async throws -> Data {
        guard let data = imageData(forID: hit.id) else {
            throw SymbolProviderError.missingImage
        }
        return data
    }

    func thumbnail(for hit: SymbolHit) async -> Data? {
        imageData(forID: hit.id)
    }

    /// Retrouve l'image d'un pictogramme du kit, quel que soit l'endroit où
    /// les ressources ont atterri dans le bundle.
    func imageData(forID id: String) -> Data? {
        if let data = tryLoadImage(named: id, subdirectory: "images")
            ?? tryLoadImage(named: id, subdirectory: nil) {
            return data
        }
        // Dernier recours : recherche plate dans le bundle.
        if let url = Bundle.main.url(forResource: id, withExtension: "png") {
            return try? Data(contentsOf: url)
        }
        return nil
    }

    private func tryLoadImage(named id: String, subdirectory: String?) -> Data? {
        guard let directory = manifestDirectory else { return nil }
        var url = directory
        if let subdirectory {
            url.append(path: subdirectory)
        }
        url.append(path: "\(id).png")
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try? Data(contentsOf: url)
    }
}
