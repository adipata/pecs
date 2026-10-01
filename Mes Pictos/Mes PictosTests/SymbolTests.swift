import Foundation
import Testing
@testable import Mes_Pictos

// MARK: - ARASAAC : décodage et URLs (réponses enregistrées, sans réseau)

struct SymbolProviderTests {

    // Réponse réelle de https://api.arasaac.org/api/pictograms/fr/search/pomme
    // (enregistrée le 30/09/2026, raccourcie à deux entrées).
    static let searchFixture = """
    [
      {"_id":2462,"created":"2007-12-14T12:34:03.000Z","downloads":0,
       "tags":["feeding","food","plant-based food","fruit","core vocabulary"],
       "sex":false,"schematic":false,
       "keywords":[{"type":2,"keyword":"pomme","hasLocation":false,"plural":"pommes"}],
       "categories":["fruit","core vocabulary-feeding"],
       "violence":false,"hair":false,"skin":false,"aac":true,"aacColor":true},
      {"_id":13644,"created":"2010-02-25T16:54:24.000Z","downloads":0,
       "tags":["feeding","food","plant-based food","fruit"],
       "sex":false,"schematic":false,
       "keywords":[{"type":2,"keyword":"pomme","plural":"pommes"}],
       "categories":["fruit"],
       "violence":false,"hair":false,"skin":false,"aac":false,"aacColor":false}
    ]
    """

    @Test func parseSearchResponseDecodesFrenchKeyword() throws {
        let pictograms = try ArasaacProvider.parseSearchResponse(
            Data(SymbolProviderTests.searchFixture.utf8))

        #expect(pictograms.count == 2)
        #expect(pictograms[0].id == 2462)
        #expect(pictograms[0].keyword == "pomme")
        #expect(pictograms[0].aac == true)
        #expect(pictograms[1].id == 13644)
        #expect(pictograms[1].aac == false)
    }

    @Test func parseSearchResponseToleratesMissingKeywords() throws {
        let json = """
        [{"_id":907,"keywords":[{"keyword":""}],"aac":true}]
        """
        let pictograms = try ArasaacProvider.parseSearchResponse(Data(json.utf8))
        #expect(pictograms[0].id == 907)
        #expect(pictograms[0].keyword == "")
    }

    @Test func searchURLBuildsExpectedPath() {
        let url = ArasaacProvider.searchURL(keyword: "pomme", language: "fr")
        #expect(url.absoluteString == "https://api.arasaac.org/api/pictograms/fr/search/pomme")
    }

    @Test func searchURLEncodesAccentsAndSpaces() {
        let gâteau = ArasaacProvider.searchURL(keyword: "gâteau", language: "fr")
        #expect(gâteau.absoluteString == "https://api.arasaac.org/api/pictograms/fr/search/g%C3%A2teau")

        let teeth = ArasaacProvider.searchURL(keyword: "brosser les dents", language: "fr")
        #expect(teeth.absoluteString == "https://api.arasaac.org/api/pictograms/fr/search/brosser%20les%20dents")

        let apostrophe = ArasaacProvider.searchURL(keyword: "j'ai", language: "fr")
        #expect(apostrophe.absoluteString == "https://api.arasaac.org/api/pictograms/fr/search/j%27ai")
    }

    @Test func imageURLBuildsQueryOptions() {
        let url = ArasaacProvider.imageURL(
            id: "2462",
            options: SymbolOptions(resolution: 500, color: true, plural: false))
        #expect(url.absoluteString == "https://api.arasaac.org/api/pictograms/2462?resolution=500&color=true&plural=false")
    }

    @Test func imageURLIncludesSkinAndHairWhenProvided() {
        var options = SymbolOptions()
        options.skin = "SC"
        options.hair = "BC"
        let url = ArasaacProvider.imageURL(id: "907", options: options)
        #expect(url.absoluteString == "https://api.arasaac.org/api/pictograms/907?resolution=500&color=true&plural=false&skin=SC&hair=BC")
    }

    @Test func staticThumbnailURLMatchesStaticCDN() {
        #expect(ArasaacProvider.staticThumbnailURL(id: 2462)?.absoluteString
                == "https://static.arasaac.org/pictograms/2462/2462_300.png")
    }

    @Test func looksLikeImageDetectsPNGAndJPEG() {
        let png = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00])
        let jpeg = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00])
        let html = Data("<html>404</html>".utf8)

        #expect(ArasaacProvider.looksLikeImage(png))
        #expect(ArasaacProvider.looksLikeImage(jpeg))
        #expect(!ArasaacProvider.looksLikeImage(html))
    }
}

// MARK: - Kit de démarrage : manifeste

struct BundledProviderTests {

    static let manifestFixture = """
    {
      "format": "mespictos-starter-pack",
      "version": 1,
      "licence": "CC BY-NC-SA – ARASAAC",
      "attribution": "Les symboles pictographiques…",
      "items": [
        {"id": "2462", "keyword": "pomme", "category": "Manger"},
        {"id": "7713", "keyword": "eau", "category": "Manger"},
        {"id": "27098", "keyword": "ballon", "category": "Jouer"},
        {"id": "24365", "keyword": "non", "category": "Cartes critiques"}
      ]
    }
    """

    @Test func manifestDecodesItemsAndCategories() throws {
        let manifest = try JSONDecoder().decode(
            BundledProvider.Manifest.self,
            from: Data(BundledProviderTests.manifestFixture.utf8))

        #expect(manifest.format == "mespictos-starter-pack")
        #expect(manifest.items.count == 4)
        #expect(manifest.items[0].keyword == "pomme")
        #expect(manifest.items[0].category == "Manger")

        let provider = BundledProvider()
        provider.items = manifest.items

        // Les catégories suivent l'ordre de première apparition.
        #expect(provider.categories == ["Manger", "Jouer", "Cartes critiques"])
        #expect(provider.hits(in: "Manger").count == 2)
    }

    @Test func bundledSearchMatchesCaseAndAccentInsensitive() async throws {
        let provider = BundledProvider()
        provider.items = [
            .init(id: "2462", keyword: "Pomme", category: "Manger"),
            .init(id: "13644", keyword: "gâteau", category: "Manger"),
            .init(id: "27098", keyword: "Ballon", category: "Jouer"),
        ]

        let byCase = try await provider.search("pomme", language: "fr")
        #expect(byCase.count == 1)
        #expect(byCase[0].id == "2462")

        // « gateau » sans accent trouve « gâteau ».
        let byAccent = try await provider.search("gateau", language: "fr")
        #expect(byAccent.count == 1)
        #expect(byAccent[0].id == "13644")
    }

    @Test func symbolOptionsCacheKeyDistinguishesVariants() {
        let plain = SymbolOptions()
        var big = SymbolOptions()
        big.resolution = 2500

        #expect(plain.cacheKey != big.cacheKey)
        #expect(SymbolOptions().cacheKey == plain.cacheKey)
    }

    /// Test d'intégration : le vrai kit embarqué, chargé depuis le bundle
    /// de l'app hôte (le simulateur), sans réseau. Vérifie aussi que chaque
    /// image du manifeste est bien présente dans le bundle.
    @Test func starterPackLoadsFromAppBundle() throws {
        let provider = BundledProvider()
        try provider.load()

        #expect(provider.items.count >= 70)
        #expect(provider.categories.count >= 10)

        for item in provider.items {
            #expect(provider.imageData(forID: item.id) != nil,
                     "\(item.keyword) (id \(item.id)) : image absente du bundle")
        }
    }

    /// Non-régression : la grille appelle `thumbnail(for:)` à travers le
    /// type existentiel `any SymbolProvider`. Si la méthode n'est pas un
    /// *requirement* du protocole, c'est l'extension par défaut (nil) qui
    /// était appelée : aucune vignette ne s'affichait, alors que choisir un
    /// pictogramme fonctionnait (ce chemin passe par `image(for:)`).
    @Test func thumbnailDispatchesThroughProviderExistential() async throws {
        let concrete = BundledProvider()
        try concrete.load()

        let hit = try #require(concrete.hits(in: "Cartes critiques").first)
        let provider: any SymbolProvider = concrete

        let data = await provider.thumbnail(for: hit)
        #expect(data != nil)
        #expect((data?.count ?? 0) > 100, "La vignette doit contenir une vraie image PNG")
    }
}
