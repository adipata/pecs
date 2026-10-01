import Foundation
import SwiftData
import UniformTypeIdentifiers
import CoreTransferable

/// Opérations sur le classeur : requêtes et logique de déplacement.
/// Toute la logique de déplacement / échange passe par ici pour être
/// testable unitairement (plan §10) et rester cohérente entre le glisser-déposer
/// et les menus contextuels.
enum BoardOps {

    // MARK: - Pages

    /// Pages triées par `sortIndex`, avec filtre optionnel.
    static func pages(in context: ModelContext,
                      includeHidden: Bool = true,
                      kind: PageKind? = nil) -> [Page] {
        let descriptor = FetchDescriptor<Page>(sortBy: [SortDescriptor(\.sortIndex), SortDescriptor(\.createdAt)])
        let all = (try? context.fetch(descriptor)) ?? []
        return all.filter { page in
            (includeHidden || !page.isHidden) && (kind == nil || page.kind == kind)
        }
    }

    /// La page de la barre permanente (Aide, Non…), créée si nécessaire.
    static func permanentBarPage(in context: ModelContext) -> Page {
        if let page = pages(in: context, kind: .permanentBar).first { return page }
        let page = Page(title: "Barre permanente", columns: 6, rows: 1, kind: .permanentBar, sortIndex: -1)
        context.insert(page)
        return page
    }

    static func page(withID id: UUID, in context: ModelContext) -> Page? {
        var descriptor = FetchDescriptor<Page>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    static func placement(withID id: UUID, in context: ModelContext) -> Placement? {
        var descriptor = FetchDescriptor<Placement>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    static func pictogram(withID id: UUID, in context: ModelContext) -> Pictogram? {
        var descriptor = FetchDescriptor<Pictogram>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    static func nextSortIndex(in context: ModelContext) -> Int {
        let all = pages(in: context)
        return (all.map(\.sortIndex).max() ?? 0) + 1
    }

    /// Déplace une page d'une position (±1) dans la liste triée donnée,
    /// puis normalise tous les `sortIndex` de la liste. Utilisée par les
    /// menus « Déplacer vers la gauche/droite » et le gestionnaire de pages.
    static func movePage(_ page: Page, by delta: Int, in pages: [Page]) {
        guard let index = pages.firstIndex(where: { $0.id == page.id }) else { return }
        let target = index + delta
        guard pages.indices.contains(target) else { return }
        var mutable = pages
        mutable.swapAt(index, target)
        for (position, sortedPage) in mutable.enumerated() {
            sortedPage.sortIndex = position
        }
    }

    // MARK: - Slots et placements

    /// Placements de la page, triés par slot. `includeHidden` faux = mode enfant.
    static func placements(on page: Page, includeHidden: Bool = true) -> [Placement] {
        let all = page.placements ?? []
        return all
            .filter { includeHidden || !$0.isHidden }
            .sorted { $0.slot < $1.slot }
    }

    /// Le placement qui occupe un slot (en ignorant celui qu'on déplace).
    static func occupant(atSlot slot: Int, on page: Page, excluding: Placement? = nil) -> Placement? {
        page.placements?.first { $0.slot == slot && $0.id != excluding?.id }
    }

    static func usedSlots(on page: Page) -> Set<Int> {
        Set((page.placements ?? []).map(\.slot))
    }

    /// Premier slot libre de la page, ou nil si elle est pleine.
    static func firstEmptySlot(on page: Page) -> Int? {
        let used = usedSlots(on: page)
        guard page.slotCount > 0 else { return nil }
        for slot in 0..<page.slotCount where !used.contains(slot) {
            return slot
        }
        return nil
    }

    // MARK: - Déplacements

    /// Dépose un placement sur un slot :
    /// - slot libre → le placement y va ;
    /// - slot occupé → échange des deux cartes (les autres ne bougent pas) ;
    /// - autre page → le placement change de page (déplacement entre pages).
    /// Retourne faux si le slot est hors grille.
    @discardableResult
    static func place(_ placement: Placement, atSlot slot: Int, on page: Page) -> Bool {
        guard slot >= 0, slot < page.slotCount else { return false }
        if placement.page?.id != page.id { placement.page = page }
        guard let occupant = occupant(atSlot: slot, on: page, excluding: placement) else {
            placement.slot = slot
            return true
        }
        // Échange : on échange simplement les slots, tout le reste ne bouge pas.
        let previous = placement.slot
        placement.slot = occupant.slot
        occupant.slot = previous
        return true
    }

    /// Déplace le placement vers le premier slot libre d'une autre page.
    /// Retourne nil (et ne touche à rien) si la page cible est pleine.
    @discardableResult
    static func place(_ placement: Placement, onPage page: Page) -> Bool {
        guard let slot = firstEmptySlot(on: page) else { return false }
        return place(placement, atSlot: slot, on: page)
    }

    /// Duplique le placement sur une autre page (même pictogramme, nouveau
    /// placement), vers le premier slot libre. Retourne nil si la page est pleine.
    static func duplicate(_ placement: Placement, onto page: Page, in context: ModelContext) -> Placement? {
        guard let pictogram = placement.pictogram,
              let slot = firstEmptySlot(on: page) else { return nil }
        let copy = Placement(slot: slot)
        context.insert(copy)
        copy.pictogram = pictogram
        copy.page = page
        return copy
    }

    // MARK: - Création / suppression

    /// Crée un pictogramme et le place sur un slot donné d'une page.
    @discardableResult
    static func add(_ pictogram: Pictogram, atSlot slot: Int, on page: Page, in context: ModelContext) -> Placement {
        context.insert(pictogram)
        let placement = Placement(slot: slot)
        context.insert(placement)
        placement.pictogram = pictogram
        placement.page = page
        return placement
    }

    /// Retire une carte de sa page sans supprimer le pictogramme.
    static func removePlacement(_ placement: Placement, in context: ModelContext) {
        context.delete(placement)
    }
}

// MARK: - Drag & drop

/// Charge utile transportée pendant un glisser-déposer de carte
/// (plan §7.4).
struct PlacementPayload: Codable, Transferable {
    let placementID: UUID

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .placementPayload)
    }
}

extension UTType {
    /// Type uniforme exporté pour les glissers internes de cartes.
    static let placementPayload = UTType(exportedAs: "fr.mespictos.placement")
}
