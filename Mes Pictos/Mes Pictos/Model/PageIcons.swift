import Foundation

/// Catalogue d'icônes (SF Symbols) pour les onglets de pages.
/// Un enfant qui ne lit pas encore reconnaît sa page à l'image,
/// avant de pouvoir lire le titre (plan §2, correspondance image/mot).
enum PageIconCatalog {

    /// Icône utilisée quand une page n'en a pas encore (et valeur par défaut du modèle).
    static let defaultSymbol = "square.grid.2x2"

    struct Item: Identifiable, Hashable {
        let symbol: String
        let label: String

        var id: String { symbol }
    }

    /// Icônes proposées dans l'éditeur de page, en français.
    /// Toutes disponibles à partir d'iOS 18 (vérifier les disponibilités
    /// si ajout : SF Symbols 4 = iOS 16, SF Symbols 5 = iOS 17).
    static let all: [Item] = [
        Item(symbol: "square.grid.2x2", label: "Général"),
        Item(symbol: "fork.knife", label: "Manger"),
        Item(symbol: "cup.and.saucer.fill", label: "Boire"),
        Item(symbol: "gamecontroller.fill", label: "Jeux"),
        Item(symbol: "puzzlepiece.fill", label: "Puzzle"),
        Item(symbol: "soccerball", label: "Ballon"),
        Item(symbol: "paintpalette.fill", label: "Dessin"),
        Item(symbol: "music.note", label: "Musique"),
        Item(symbol: "balloon.fill", label: "Bulles"),
        Item(symbol: "person.2.fill", label: "Personnes"),
        Item(symbol: "heart.fill", label: "Famille"),
        Item(symbol: "figure.run", label: "Sport"),
        Item(symbol: "house.fill", label: "Maison"),
        Item(symbol: "map.fill", label: "Lieux"),
        Item(symbol: "car.fill", label: "Transport"),
        Item(symbol: "face.smiling", label: "Émotions"),
        Item(symbol: "tshirt.fill", label: "Vêtements"),
        Item(symbol: "bed.double.fill", label: "Dormir"),
        Item(symbol: "toilet.fill", label: "Toilettes"),
        Item(symbol: "drop.fill", label: "Bain"),
        Item(symbol: "book.fill", label: "Livres"),
        Item(symbol: "backpack.fill", label: "École"),
        Item(symbol: "pawprint.fill", label: "Animaux"),
        Item(symbol: "tv.fill", label: "Télé"),
        Item(symbol: "sun.max.fill", label: "Dehors"),
        Item(symbol: "clock.fill", label: "Horaires"),
        Item(symbol: "gift.fill", label: "Cadeaux"),
        Item(symbol: "star.fill", label: "Favoris"),
        Item(symbol: "sparkles", label: "Magie"),
        Item(symbol: "party.popper.fill", label: "Fête"),
    ]

    /// Nom de symbole sûr pour l'affichage : jamais vide.
    static func resolvedSymbol(for page: Page) -> String {
        page.iconName.isEmpty ? defaultSymbol : page.iconName
    }
}
