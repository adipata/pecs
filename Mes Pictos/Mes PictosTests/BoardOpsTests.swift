import Foundation
import Testing
import SwiftData
@testable import Mes_Pictos

/// Infrastructure commune : conteneur SwiftData en mémoire.
@MainActor
struct TestWorld {

    let context: ModelContext

    init() throws {
        let schema = Schema([Pictogram.self, Page.self, Placement.self])
        // Conteneur mémoire pour les tests, avec CloudKit explicitement
        // désactivé : l'init « url » de ModelConfiguration vaut `.automatic`
        // par défaut, et le miroir CloudKit s'attachait au store de test
        // (bruit dans les logs, enregistrements non déterministes).
        let configuration = ModelConfiguration(
            schema: schema,
            url: URL(fileURLWithPath: "/dev/null"),
            cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: configuration)
        context = ModelContext(container)
        context.autosaveEnabled = false
    }

    static func makePage(title: String = "Page",
                         columns: Int = 2,
                         rows: Int = 2,
                         context: ModelContext) -> Page {
        let page = Page(title: title, columns: columns, rows: rows)
        context.insert(page)
        return page
    }

    @discardableResult
    static func makeCard(label: String,
                         spokenText: String? = nil,
                         recording: Data? = nil,
                         context: ModelContext,
                         on page: Page,
                         slot: Int) -> (Pictogram, Placement) {
        let pictogram = Pictogram(label: label, spokenText: spokenText, recording: recording)
        let placement = BoardOps.add(pictogram, atSlot: slot, on: page, in: context)
        return (pictogram, placement)
    }
}

// MARK: - Déplacements et échanges (plan §10)

@MainActor
struct BoardOpsTests {

    // MARK: Slots

    @Test func firstEmptySlotOnEmptyPage() throws {
        let world = try TestWorld()
        let page = TestWorld.makePage(columns: 2, rows: 2, context: world.context)
        #expect(BoardOps.firstEmptySlot(on: page) == 0)
    }

    @Test func firstEmptySlotSkipsUsedSlots() throws {
        let world = try TestWorld()
        let page = TestWorld.makePage(context: world.context)
        TestWorld.makeCard(label: "Pomme", context: world.context, on: page, slot: 0)
        TestWorld.makeCard(label: "Lait", context: world.context, on: page, slot: 2)
        #expect(BoardOps.firstEmptySlot(on: page) == 1)
    }

    @Test func fullPageHasNoEmptySlot() throws {
        let world = try TestWorld()
        let page = TestWorld.makePage(columns: 2, rows: 1, context: world.context)
        TestWorld.makeCard(label: "Pomme", context: world.context, on: page, slot: 0)
        TestWorld.makeCard(label: "Lait", context: world.context, on: page, slot: 1)
        #expect(BoardOps.firstEmptySlot(on: page) == nil)
    }

    // MARK: Déposer sur un slot libre

    @Test func moveIntoEmptySlot() throws {
        let world = try TestWorld()
        let page = TestWorld.makePage(context: world.context)
        let (_, placement) = TestWorld.makeCard(label: "Pomme", context: world.context, on: page, slot: 0)

        let moved = BoardOps.place(placement, atSlot: 3, on: page)
        #expect(moved)
        #expect(placement.slot == 3)
        // L'ancien slot est libéré.
        #expect(BoardOps.firstEmptySlot(on: page) == 0)
    }

    @Test func dropOutsideGridIsRejected() throws {
        let world = try TestWorld()
        let page = TestWorld.makePage(columns: 2, rows: 2, context: world.context)
        let (_, placement) = TestWorld.makeCard(label: "Pomme", context: world.context, on: page, slot: 0)

        #expect(!BoardOps.place(placement, atSlot: 99, on: page))
        #expect(placement.slot == 0)
    }

    // MARK: Échange sur un slot occupé

    @Test func droppingOnOccupiedSlotSwaps() throws {
        let world = try TestWorld()
        let page = TestWorld.makePage(context: world.context)
        let (_, apple) = TestWorld.makeCard(label: "Pomme", context: world.context, on: page, slot: 0)
        let (_, milk) = TestWorld.makeCard(label: "Lait", context: world.context, on: page, slot: 3)

        let swapped = BoardOps.place(apple, atSlot: 3, on: page)
        #expect(swapped)
        #expect(apple.slot == 3)
        #expect(milk.slot == 0)
        // Les autres cartes ne bougent pas.
        #expect(BoardOps.occupant(atSlot: 1, on: page) == nil)
    }

    @Test func droppingOnOwnSlotIsNoop() throws {
        let world = try TestWorld()
        let page = TestWorld.makePage(context: world.context)
        let (_, apple) = TestWorld.makeCard(label: "Pomme", context: world.context, on: page, slot: 2)

        let moved = BoardOps.place(apple, atSlot: 2, on: page)
        #expect(moved)
        #expect(apple.slot == 2)
    }

    // MARK: Déplacement entre pages

    @Test func moveBetweenPagesUsesFirstEmptySlot() throws {
        let world = try TestWorld()
        let source = TestWorld.makePage(title: "Manger", context: world.context)
        let target = TestWorld.makePage(title: "Jouer", columns: 3, rows: 1, context: world.context)
        TestWorld.makeCard(label: "Ballon", context: world.context, on: target, slot: 0)
        let (_, apple) = TestWorld.makeCard(label: "Pomme", context: world.context, on: source, slot: 0)

        let moved = BoardOps.place(apple, onPage: target)
        #expect(moved)
        #expect(apple.page?.id == target.id)
        #expect(apple.slot == 1)
        #expect(source.placements?.isEmpty ?? false)
        #expect(target.placements?.count == 2)
    }

    @Test func moveIntoFullPageFails() throws {
        let world = try TestWorld()
        let source = TestWorld.makePage(title: "Manger", context: world.context)
        let target = TestWorld.makePage(title: "Jouer", columns: 1, rows: 1, context: world.context)
        TestWorld.makeCard(label: "Ballon", context: world.context, on: target, slot: 0)
        let (_, apple) = TestWorld.makeCard(label: "Pomme", context: world.context, on: source, slot: 0)

        #expect(!BoardOps.place(apple, onPage: target))
        // Rien n'a bougé.
        #expect(apple.page?.id == source.id)
        #expect(apple.slot == 0)
    }

    // MARK: Duplication

    @Test func duplicateKeepsPictogramAndOriginalInPlace() throws {
        let world = try TestWorld()
        let source = TestWorld.makePage(title: "Manger", context: world.context)
        let target = TestWorld.makePage(title: "Jouer", context: world.context)
        let (pictogram, placement) = TestWorld.makeCard(label: "Pomme", context: world.context, on: source, slot: 0)

        let copy = BoardOps.duplicate(placement, onto: target, in: world.context)

        #expect(copy != nil)
        #expect(copy?.pictogram?.id == pictogram.id)
        #expect(copy?.slot == 0)
        // L'original reste sur sa page.
        #expect(placement.page?.id == source.id)
        #expect(pictogram.placements?.count == 2)
    }

    // MARK: Masquer sans supprimer (phase III)

    @Test func hiddenCardsAreFilteredForChildMode() throws {
        let world = try TestWorld()
        let page = TestWorld.makePage(columns: 2, rows: 1, context: world.context)
        let (_, apple) = TestWorld.makeCard(label: "Pomme", context: world.context, on: page, slot: 0)
        TestWorld.makeCard(label: "Lait", context: world.context, on: page, slot: 1)
        apple.isHidden = true

        let visible = BoardOps.placements(on: page, includeHidden: false)
        #expect(visible.count == 1)
        #expect(visible.first?.pictogram?.label == "Lait")

        let all = BoardOps.placements(on: page, includeHidden: true)
        #expect(all.count == 2)
    }

    // MARK: Réordonnancement des pages

    @Test func movePageSwapsWithNeighbour() throws {
        let world = try TestWorld()
        let a = TestWorld.makePage(title: "A", context: world.context)
        let b = TestWorld.makePage(title: "B", context: world.context)
        let c = TestWorld.makePage(title: "C", context: world.context)
        a.sortIndex = 0
        b.sortIndex = 1
        c.sortIndex = 2

        BoardOps.movePage(a, by: 1, in: [a, b, c])

        // A et B échangent leurs places, C ne bouge pas.
        #expect(b.sortIndex == 0)
        #expect(a.sortIndex == 1)
        #expect(c.sortIndex == 2)
    }

    @Test func movePageAtEdgeIsNoop() throws {
        let world = try TestWorld()
        let a = TestWorld.makePage(title: "A", context: world.context)
        let b = TestWorld.makePage(title: "B", context: world.context)
        a.sortIndex = 0
        b.sortIndex = 1

        BoardOps.movePage(a, by: -1, in: [a, b])
        BoardOps.movePage(b, by: 1, in: [a, b])

        #expect(a.sortIndex == 0)
        #expect(b.sortIndex == 1)
    }

    @Test func movePageNormalizesIndexes() throws {
        let world = try TestWorld()
        let a = TestWorld.makePage(title: "A", context: world.context)
        let b = TestWorld.makePage(title: "B", context: world.context)
        let c = TestWorld.makePage(title: "C", context: world.context)
        // Des index en désordre ou dupliqués sont normalisés.
        a.sortIndex = 5
        b.sortIndex = 5
        c.sortIndex = 9

        BoardOps.movePage(b, by: 1, in: [a, b, c])

        // [A, B, C] devient [A, C, B], avec des index réécrits de 0 à 2.
        #expect(a.sortIndex == 0)
        #expect(c.sortIndex == 1)
        #expect(b.sortIndex == 2)
    }

    // MARK: Suppression d'un placement

    @Test func removingPlacementKeepsPictogram() throws {
        let world = try TestWorld()
        let page = TestWorld.makePage(context: world.context)
        let (pictogram, placement) = TestWorld.makeCard(label: "Pomme", context: world.context, on: page, slot: 0)

        BoardOps.removePlacement(placement, in: world.context)
        try world.context.save()

        #expect(page.placements?.isEmpty ?? false)
        #expect(pictogram.placements?.isEmpty ?? false)
        // Le pictogramme existe toujours dans la bibliothèque.
        let fetched = BoardOps.pictogram(withID: pictogram.id, in: world.context)
        #expect(fetched?.label == "Pomme")
    }
}

// MARK: - Priorité de lecture (plan §6 : enregistrement > texte prononcé > libellé)

@MainActor
struct SpeechPriorityTests {

    @Test func recordingWinsOverEverything() throws {
        let world = try TestWorld()
        let pictogram = Pictogram(label: "Pomme",
                                  spokenText: "une pomme",
                                  recording: Data([1, 2, 3]))
        world.context.insert(pictogram)

        guard case .recording(let data)? = SpeechService.playbackContent(for: pictogram) else {
            Issue.record("La voix enregistrée doit passer en priorité")
            return
        }
        #expect(data == Data([1, 2, 3]))
    }

    @Test func spokenTextWinsOverLabel() throws {
        let world = try TestWorld()
        let pictogram = Pictogram(label: "Pomme", spokenText: "une pomme")
        world.context.insert(pictogram)

        #expect(SpeechService.playbackContent(for: pictogram) == .text("une pomme"))
    }

    @Test func labelIsUsedAsFallback() throws {
        let world = try TestWorld()
        let pictogram = Pictogram(label: "pomme")
        world.context.insert(pictogram)

        #expect(SpeechService.playbackContent(for: pictogram) == .text("pomme"))
    }

    @Test func emptyRecordingFallsBackToText() throws {
        let world = try TestWorld()
        let pictogram = Pictogram(label: "Pomme", spokenText: nil, recording: Data())
        world.context.insert(pictogram)

        #expect(SpeechService.playbackContent(for: pictogram) == .text("Pomme"))
    }

    @Test func blankLabelProducesNoSpeech() throws {
        let world = try TestWorld()
        let pictogram = Pictogram(label: "   ")
        world.context.insert(pictogram)

        #expect(SpeechService.playbackContent(for: pictogram) == nil)
    }
}
