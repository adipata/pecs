import Foundation
import SwiftData
import PictoCore

// CloudKit sync rules, respected by every model:
// no unique attributes, every property optional or with a default, every relationship optional.

enum PageKind: String, Codable {
    case normal
    case permanentBar
}

enum PictogramSource: String, Codable {
    case photo
    case symbol
    case arasaac
    case imported
}

@Model
final class Pictogram {
    var id: UUID = UUID()
    var label: String = ""
    /// Overrides the label for speech, e.g. label "pomme", spoken "une pomme".
    var spokenText: String?
    @Attribute(.externalStorage) var imageData: Data?
    /// Incremented when the image changes, used as image cache key.
    var imageVersion: Int = 0
    /// Parent's recorded voice (AAC). Played instead of text-to-speech.
    @Attribute(.externalStorage) var recordingData: Data?
    var wordTypeRaw: String = "noun"
    var sourceRaw: String = PictogramSource.photo.rawValue
    /// Identifier in the source library, e.g. an ARASAAC id.
    var sourceRef: String?
    var licence: String?
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Placement.pictogram)
    var placements: [Placement]? = []

    init(label: String, spokenText: String? = nil, imageData: Data? = nil, recordingData: Data? = nil, source: PictogramSource = .photo) {
        self.id = UUID()
        self.label = label
        self.spokenText = spokenText
        self.imageData = imageData
        self.recordingData = recordingData
        self.sourceRaw = source.rawValue
        self.createdAt = Date()
    }

    var source: PictogramSource {
        get { PictogramSource(rawValue: sourceRaw) ?? .photo }
        set { sourceRaw = newValue.rawValue }
    }
}

@Model
final class Page {
    var id: UUID = UUID()
    var title: String = ""
    var sortIndex: Int = 0
    var columns: Int = 2
    var rows: Int = 2
    /// Hidden pages are not shown in child mode.
    var isHidden: Bool = false
    var kindRaw: String = PageKind.normal.rawValue
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Placement.page)
    var placements: [Placement]? = []

    init(title: String, columns: Int, rows: Int, sortIndex: Int, kind: PageKind = .normal) {
        let size = GridSize(columns: columns, rows: rows)
        self.id = UUID()
        self.title = title
        self.columns = size.columns
        self.rows = size.rows
        self.sortIndex = sortIndex
        self.kindRaw = kind.rawValue
        self.createdAt = Date()
    }

    var kind: PageKind {
        get { PageKind(rawValue: kindRaw) ?? .normal }
        set { kindRaw = newValue.rawValue }
    }

    var gridSize: GridSize { GridSize(columns: columns, rows: rows) }

    var displayTitle: String {
        if kind == .permanentBar { return "Barre permanente" }
        return title.isEmpty ? "Sans titre" : title
    }

    /// The placement in a slot. If sync ever produced two, the oldest wins.
    func placement(at slot: Int) -> Placement? {
        (placements ?? [])
            .filter { $0.slot == slot }
            .min { $0.createdAt < $1.createdAt }
    }

    var occupiedSlots: Set<Int> {
        Set((placements ?? []).map(\.slot))
    }

    var hasVisibleCards: Bool {
        (placements ?? []).contains { !$0.isHidden && $0.pictogram != nil }
    }
}

/// A pictogram placed in a slot of a page. The same pictogram can be placed on several pages.
@Model
final class Placement {
    var id: UUID = UUID()
    /// row * columns + column
    var slot: Int = 0
    /// Hidden in child mode, but kept (and shown faded) in parent mode.
    var isHidden: Bool = false
    var createdAt: Date = Date()
    var page: Page?
    var pictogram: Pictogram?

    init(slot: Int) {
        self.id = UUID()
        self.slot = slot
        self.createdAt = Date()
    }
}
