import Foundation

/// Fournisseur ARASAAC (plan §5) : recherche par mot-clé français et
/// image rendue par l'API. Aucune clé d'API nécessaire. Les appels réseau
/// ne se font que depuis le mode parent (éditeur de pictogrammes, plan §8).
final class ArasaacProvider: SymbolProvider {

    let id = "arasaac"
    let displayName = "ARASAAC"
    let attribution = SymbolAttribution.arasaac

    static let apiHost = "api.arasaac.org"
    static let staticHost = "static.arasaac.org"

    private let session: URLSession
    private let cache = SymbolImageCache()

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Recherche

    func search(_ query: String, language: String = "fr") async throws -> [SymbolHit] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let url = Self.searchURL(keyword: trimmed, language: language)
        let (data, _) = try await session.data(from: url)
        let pictograms = try Self.parseSearchResponse(data)
        return pictograms.map { pictogram in
            SymbolHit(
                id: "\(pictogram.id)",
                providerID: id,
                label: pictogram.keyword,
                thumbnailURL: Self.staticThumbnailURL(id: pictogram.id))
        }
    }

    // MARK: - Image

    func image(for hit: SymbolHit, options: SymbolOptions) async throws -> Data {
        let key = "\(id)-\(hit.id)-\(options.cacheKey)"
        if let cached = cache.data(forKey: key) { return cached }

        let url = Self.imageURL(id: hit.id, options: options)
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              Self.looksLikeImage(data) else {
            throw SymbolProviderError.badResponse
        }

        cache.set(data, forKey: key)
        return data
    }

    func thumbnail(for hit: SymbolHit) async -> Data? {
        let key = "\(id)-thumb-\(hit.id)"
        if let cached = cache.data(forKey: key) { return cached }
        guard let url = hit.thumbnailURL else { return nil }
        guard let (data, response) = try? await session.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200,
              Self.looksLikeImage(data) else { return nil }
        cache.set(data, forKey: key)
        return data
    }

    // MARK: - URLs (testables)

    /// `https://api.arasaac.org/api/pictograms/{lang}/search/{keyword}`
    /// Le mot-clé est encodé une seule fois (accents, espaces, apostrophes).
    static func searchURL(keyword: String, language: String) -> URL {
        let encoded = keyword.encodedForPath()
        return URL(string: "https://\(apiHost)/api/pictograms/\(language)/search/\(encoded)")!
    }

    /// `https://api.arasaac.org/api/pictograms/{id}?resolution=…&color=…&plural=…[&skin=…&hair=…]`
    static func imageURL(id: String, options: SymbolOptions) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = apiHost
        components.path = "/api/pictograms/\(id)"
        components.queryItems = [
            URLQueryItem(name: "resolution", value: String(options.resolution)),
            URLQueryItem(name: "color", value: options.color ? "true" : "false"),
            URLQueryItem(name: "plural", value: options.plural ? "true" : "false"),
        ]
        if let skin = options.skin {
            components.queryItems?.append(URLQueryItem(name: "skin", value: skin))
        }
        if let hair = options.hair {
            components.queryItems?.append(URLQueryItem(name: "hair", value: hair))
        }
        return components.url!
    }

    /// `https://static.arasaac.org/pictograms/{id}/{id}_300.png`
    static func staticThumbnailURL(id: Int) -> URL? {
        URL(string: "https://\(staticHost)/pictograms/\(id)/\(id)_300.png")
    }

    static func looksLikeImage(_ data: Data) -> Bool {
        // Signature PNG ou JPEG, pour ne pas stocker une page d'erreur.
        data.count > 8
            && data.prefix(8) == Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
            || (data.count > 2 && data.prefix(2) == Data([0xFF, 0xD8]))
    }

    // MARK: - Décodage (testé sur réponses enregistrées)

    struct AraPictogram: Decodable {
        let id: Int
        /// Premier mot-clé français non vide.
        let keyword: String
        let aac: Bool?

        private enum CodingKeys: String, CodingKey {
            case id = "_id"
            case keywords
            case aac
        }

        private struct AraKeyword: Decodable {
            let keyword: String?
        }

        init(id: Int, keyword: String, aac: Bool?) {
            self.id = id
            self.keyword = keyword
            self.aac = aac
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let id = try container.decode(Int.self, forKey: .id)
            let keywords = try container.decodeIfPresent([AraKeyword].self, forKey: .keywords)
            let keyword = keywords?.first(where: { !($0.keyword ?? "").isEmpty })?.keyword ?? ""
            let aac = try container.decodeIfPresent(Bool.self, forKey: .aac)
            self.init(id: id, keyword: keyword, aac: aac)
        }
    }

    /// Décode une réponse de recherche ARASAAC (forme vérifiée contre l'API
    /// réelle, testée unitairement sans réseau).
    static func parseSearchResponse(_ data: Data) throws -> [AraPictogram] {
        try JSONDecoder().decode([AraPictogram].self, from: data)
    }
}

private extension String {
    /// Encodage sûr pour un segment de chemin d'URL (les mots-clés peuvent
    /// contenir accents, espaces, apostrophes). Les caractères déjà encodés
    /// ne sont pas ré-encodés : construire l'URL finale avec `URL(string:)`,
    /// pas avec `URLComponents.path` (qui doublerait l'encodage).
    func encodedForPath() -> String {
        let allowed = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "/?'"))
        return addingPercentEncoding(withAllowedCharacters: allowed) ?? self
    }
}
