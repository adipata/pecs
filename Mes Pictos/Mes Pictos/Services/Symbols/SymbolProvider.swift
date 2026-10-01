import Foundation

/// Attribution ARASAAC à conserver avec chaque pictogramme importé
/// (plan §5, licence CC BY-NC-SA).
enum SymbolAttribution {
    static let arasaac =
        "Les symboles pictographiques utilisés sont la propriété du Gouvernement "
        + "d'Aragon et ont été créés par Sergio Palao pour ARASAAC "
        + "(https://arasaac.org), qui les distribue sous licence Creative Commons BY-NC-SA."

    /// Mention courte stockée dans chaque pictogramme importé.
    static let arasaacLicence = "CC BY-NC-SA – ARASAAC"
}

/// Un pictogramme proposé par une source (plan §7.5).
struct SymbolHit: Identifiable, Hashable, Sendable {
    /// Identifiant chez le fournisseur (id numérique ARASAAC).
    let id: String
    let providerID: String
    /// Mot-clé français du pictogramme.
    let label: String
    /// Vignette, quand le fournisseur en fournit une.
    let thumbnailURL: URL?

    var uniqueID: String { "\(providerID)-\(id)" }
}

/// Options de rendu demandées au fournisseur (résolution, couleurs,
/// peau/cheveux pour ARASAAC).
struct SymbolOptions: Sendable {
    var resolution: Int = 500
    var color: Bool = true
    var plural: Bool = false
    var skin: String? = nil
    var hair: String? = nil

    var cacheKey: String {
        "\(resolution)-\(color)-\(plural)-\(skin ?? "")-\(hair ?? "")"
    }
}

/// Source de pictogrammes (plan §7.5). Premières implémentations :
/// `ArasaacProvider` (réseau) et `BundledProvider` (kit embarqué, hors ligne).
/// Un fournisseur Mulberry ou Global Symbols s'ajoute sans toucher l'interface.
protocol SymbolProvider: Sendable {
    var id: String { get }
    var displayName: String { get }
    var attribution: String { get }

    /// Recherche par mot-clé dans une langue (« fr » par défaut).
    func search(_ query: String, language: String) async throws -> [SymbolHit]

    /// Image PNG du pictogramme. Copiée dans le modèle : tout continue de
    /// fonctionner hors ligne.
    func image(for hit: SymbolHit, options: SymbolOptions) async throws -> Data

    /// Petite vignette pour les grilles de résultats. Doit être un
    /// *requirement* du protocole (et pas seulement une extension) pour que
    /// l'implémentation concrète soit bien appelée à travers le type
    /// existentiel `any SymbolProvider`.
    func thumbnail(for hit: SymbolHit) async -> Data?
}

extension SymbolProvider {
    /// Fournisseur sans vignettes : la grille affiche un gabarit.
    func thumbnail(for hit: SymbolHit) async -> Data? { nil }
}

enum SymbolProviderError: LocalizedError {
    case badResponse
    case missingImage

    var errorDescription: String? {
        switch self {
        case .badResponse:
            return "Réponse invalide du serveur de pictogrammes."
        case .missingImage:
            return "Pictogramme introuvable dans le kit de démarrage."
        }
    }
}

/// Cache mémoire des images téléchargées (plan §7.5 :
/// « Search results are cached in memory »). NSCache est sûr entre threads.
final class SymbolImageCache: Sendable {
    private let cache = NSCache<NSString, NSData>()

    func data(forKey key: String) -> Data? {
        cache.object(forKey: key as NSString) as Data?
    }

    func set(_ data: Data, forKey key: String) {
        cache.setObject(data as NSData, forKey: key as NSString)
    }
}
