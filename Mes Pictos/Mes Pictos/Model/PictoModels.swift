import Foundation
import SwiftData

// MARK: - Enums

/// Type de mot, utilisé pour le futur code couleur (clé de Fitzgerald modifiée)
/// et pour repérer les débuts de phrase.
enum WordType: String, Codable, CaseIterable, Identifiable {
    case person, verb, noun, adjective, social, starter, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .person: return "Personne"
        case .verb: return "Verbe"
        case .noun: return "Nom"
        case .adjective: return "Adjectif"
        case .social: return "Mot social"
        case .starter: return "Début de phrase"
        case .other: return "Autre"
        }
    }
}

/// Type de page. `permanentBar` est la barre toujours visible (Aide, Non…),
/// `starters` servira pour les débuts de phrase (bande phrase, étape 4).
enum PageKind: String, Codable {
    case normal
    case permanentBar
    case starters
}

/// Origine de l'image d'un pictogramme (plan §5 et §7.3).
/// Stocké en deux champs plat (kind + id) pour rester compatible CloudKit.
enum SymbolSourceKind: String, Codable {
    case photo
    case arasaac
    case mulberry
    case imported
}

// MARK: - Models

/// Un pictogramme de la bibliothèque. Il peut apparaître sur plusieurs pages
/// via des `Placement` (un pictogramme "Je veux" ou "Aide" peut être partout).
///
/// Contraintes CloudKit respectées (plan §7.3) : pas d'attribut unique,
/// chaque propriété a une valeur par défaut ou est optionnelle.
@Model
final class Pictogram {
    var id: UUID = UUID()

    /// Texte affiché sur la carte, par exemple « pomme ».
    var label: String = ""

    /// Texte prononcé s'il est différent du libellé, par exemple « une pomme ».
    /// Corrige aussi les erreurs de prononciation du TTS (prénoms).
    var spokenText: String? = nil

    /// Image normalisée (PNG carré, ~512 px), optionnelle : une carte sans
    /// image affiche le libellé seul.
    @Attribute(.externalStorage)
    var image: Data? = nil

    /// Voix enregistrée (AAC .m4a). Prioritaire sur le TTS (plan §6).
    @Attribute(.externalStorage)
    var recording: Data? = nil

    var wordTypeRaw: String = WordType.noun.rawValue
    var sourceKindRaw: String = SymbolSourceKind.photo.rawValue

    /// Identifiant chez la source (id ARASAAC, nom de fichier Mulberry…).
    var sourceID: String? = nil

    /// Mention de licence, par exemple « CC BY-NC-SA – ARASAAC ».
    var licence: String? = nil

    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Placement.pictogram)
    var placements: [Placement]? = []

    var wordType: WordType {
        get { WordType(rawValue: wordTypeRaw) ?? .other }
        set { wordTypeRaw = newValue.rawValue }
    }

    var sourceKind: SymbolSourceKind {
        get { SymbolSourceKind(rawValue: sourceKindRaw) ?? .photo }
        set { sourceKindRaw = newValue.rawValue }
    }

    init(label: String,
         spokenText: String? = nil,
         image: Data? = nil,
         recording: Data? = nil,
         wordType: WordType = .noun,
         sourceKind: SymbolSourceKind = .photo,
         sourceID: String? = nil,
         licence: String? = nil) {
        self.id = UUID()
        self.label = label
        self.spokenText = spokenText
        self.image = image
        self.recording = recording
        self.wordTypeRaw = wordType.rawValue
        self.sourceKindRaw = sourceKind.rawValue
        self.sourceID = sourceID
        self.licence = licence
        self.createdAt = Date()
    }
}

/// Une page du classeur. La grille est définie par `columns` × `rows` slots ;
/// les positions stables aident la mémoire motrice (phase III).
@Model
final class Page {
    var id: UUID = UUID()
    var title: String = ""
    var sortIndex: Int = 0

    /// Grille de la page. Par défaut 2×2 : 1 à 4 grandes cartes (plan §0).
    var columns: Int = 2
    var rows: Int = 2

    /// Page masquée : cachée au mode enfant, visible en mode parent.
    var isHidden: Bool = false

    /// Icône de l'onglet (SF Symbol du catalogue `PageIconCatalog`).
    /// Un enfant qui ne lit pas encore reconnaît sa page à l'image.
    var iconName: String = "square.grid.2x2"

    var kindRaw: String = PageKind.normal.rawValue
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Placement.page)
    var placements: [Placement]? = []

    var kind: PageKind {
        get { PageKind(rawValue: kindRaw) ?? .normal }
        set { kindRaw = newValue.rawValue }
    }

    var slotCount: Int { columns * rows }

    init(title: String,
         columns: Int = 2,
         rows: Int = 2,
         kind: PageKind = .normal,
         isHidden: Bool = false,
         sortIndex: Int = 0,
         iconName: String = "square.grid.2x2") {
        self.id = UUID()
        self.title = title
        self.columns = columns
        self.rows = rows
        self.kindRaw = kind.rawValue
        self.isHidden = isHidden
        self.sortIndex = sortIndex
        self.iconName = iconName
        self.createdAt = Date()
    }
}

/// La position d'un pictogramme sur une page. Séparer pictogramme et placement
/// permet de déplacer une carte sans la recréer, et de masquer sans supprimer.
@Model
final class Placement {
    var id: UUID = UUID()

    /// Position stable : rangée * columns + colonne.
    var slot: Int = 0

    /// Masqué au mode enfant, conservé en mode parent (phase III).
    var isHidden: Bool = false

    /// Pictogramme « dossier » qui ouvre une autre page (plus tard).
    var linkedPageID: UUID? = nil

    var page: Page? = nil
    var pictogram: Pictogram? = nil

    init(slot: Int = 0, isHidden: Bool = false) {
        self.id = UUID()
        self.slot = slot
        self.isHidden = isHidden
    }
}
