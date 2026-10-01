import Foundation
import SwiftData
import UIKit

/// Contenu de démarrage créé au premier lancement. Ce sont des exemples
/// à remplacer par les photos des vrais objets de l'enfant (renforçateurs)
/// et des photos de ses cartes papier (plan §0).
enum SeedData {

    struct SeedCard {
        let emoji: String
        let label: String
        let spokenText: String?
        let background: UIColor
    }

    /// Crée les pages de départ si la base est vide.
    static func seedIfNeeded(context: ModelContext) {
        let pageCount = (try? context.fetchCount(FetchDescriptor<Page>())) ?? 0
        guard pageCount == 0 else { return }

        // Barre permanente : « non » et « j'ai besoin d'aide » sont déjà dans
        // le classeur papier de l'enfant (plan §0). Les autres cartes critiques
        // s'ajouteront quand l'orthophoniste les introduira.
        let bar = BoardOps.permanentBarPage(in: context)
        let barCards: [SeedCard] = [
            SeedCard(emoji: "✋", label: "Non", spokenText: "non",
                     background: UIColor(red: 0.99, green: 0.87, blue: 0.87, alpha: 1)),
            SeedCard(emoji: "🙋", label: "Aide", spokenText: "j'ai besoin d'aide",
                     background: UIColor(red: 0.87, green: 0.93, blue: 0.99, alpha: 1)),
        ]
        for (slot, card) in barCards.enumerated() {
            let pictogram = Pictogram(
                label: card.label,
                spokenText: card.spokenText,
                image: emojiImage(card.emoji, background: card.background),
                wordType: .social)
            BoardOps.add(pictogram, atSlot: slot, on: bar, in: context)
        }

        // Deux pages d'exemples, 2×2 grandes cartes (plan §0 : 1 à 4 cartes).
        let mangerCards: [SeedCard] = [
            SeedCard(emoji: "🍎", label: "Pomme", spokenText: "une pomme",
                     background: UIColor(red: 0.99, green: 0.94, blue: 0.86, alpha: 1)),
            SeedCard(emoji: "🥛", label: "Lait", spokenText: "du lait",
                     background: UIColor(red: 0.90, green: 0.95, blue: 0.99, alpha: 1)),
            SeedCard(emoji: "🍌", label: "Banane", spokenText: "une banane",
                     background: UIColor(red: 0.99, green: 0.96, blue: 0.87, alpha: 1)),
            SeedCard(emoji: "🍰", label: "Gâteau", spokenText: "un gâteau",
                     background: UIColor(red: 0.99, green: 0.91, blue: 0.93, alpha: 1)),
        ]
        seedPage(title: "Manger", icon: "fork.knife", cards: mangerCards, context: context)

        let jouerCards: [SeedCard] = [
            SeedCard(emoji: "⚽️", label: "Ballon", spokenText: "le ballon",
                     background: UIColor(red: 0.88, green: 0.96, blue: 0.90, alpha: 1)),
            SeedCard(emoji: "🫧", label: "Bulles", spokenText: "des bulles",
                     background: UIColor(red: 0.88, green: 0.93, blue: 0.99, alpha: 1)),
            SeedCard(emoji: "🧸", label: "Nounours", spokenText: "le nounours",
                     background: UIColor(red: 0.99, green: 0.94, blue: 0.88, alpha: 1)),
            SeedCard(emoji: "🎵", label: "Musique", spokenText: "la musique",
                     background: UIColor(red: 0.93, green: 0.90, blue: 0.99, alpha: 1)),
        ]
        seedPage(title: "Jouer", icon: "gamecontroller.fill", cards: jouerCards, context: context)

        try? context.save()
    }

    private static func seedPage(title: String, icon: String, cards: [SeedCard], context: ModelContext) {
        let page = Page(title: title, columns: 2, rows: 2,
                        kind: .normal, sortIndex: BoardOps.nextSortIndex(in: context),
                        iconName: icon)
        context.insert(page)
        for (slot, card) in cards.enumerated() {
            let pictogram = Pictogram(
                label: card.label,
                spokenText: card.spokenText,
                image: emojiImage(card.emoji, background: card.background))
            BoardOps.add(pictogram, atSlot: slot, on: page, in: context)
        }
    }

    /// Dessine un pictogramme d'exemple : emoji centré sur fond pastel.
    /// Ces images de démonstration sont remplacées par de vraies photos.
    static func emojiImage(_ emoji: String, background: UIColor, side: CGFloat = 512) -> Data? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
        let image = renderer.image { _ in
            let rect = CGRect(x: 0, y: 0, width: side, height: side)
            background.setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: side * 0.14).fill()

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: side * 0.5),
            ]
            let attributed = NSAttributedString(string: emoji, attributes: attributes)
            let size = attributed.size()
            attributed.draw(at: CGPoint(x: (side - size.width) / 2,
                                        y: (side - size.height) / 2))
        }
        return image.pngData()
    }
}
