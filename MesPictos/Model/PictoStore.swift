import Foundation
import SwiftData
import UIKit
import PictoCore

/// All changes to pages and pictograms go through here.
@MainActor
struct PictoStore {
    let context: ModelContext

    // MARK: Queries

    func allPages() -> [Page] {
        let descriptor = FetchDescriptor<Page>(sortBy: [SortDescriptor(\.sortIndex), SortDescriptor(\.createdAt)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func normalPages() -> [Page] {
        allPages().filter { $0.kind == .normal }
    }

    /// The permanent bar. If two devices created one before syncing, the oldest is used.
    func permanentBar() -> Page? {
        Self.permanentBar(in: allPages())
    }

    static func permanentBar(in pages: [Page]) -> Page? {
        pages.filter { $0.kind == .permanentBar }.min { $0.createdAt < $1.createdAt }
    }

    func placement(withID id: UUID) -> Placement? {
        var descriptor = FetchDescriptor<Placement>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    // MARK: Pages

    @discardableResult
    func addPage(title: String, columns: Int = 2, rows: Int = 2) -> Page {
        let next = (normalPages().map(\.sortIndex).max() ?? -1) + 1
        let page = Page(title: title, columns: columns, rows: rows, sortIndex: next)
        context.insert(page)
        save()
        return page
    }

    func delete(_ page: Page) {
        for placement in page.placements ?? [] {
            removeWithoutSaving(placement)
        }
        context.delete(page)
        save()
    }

    /// Moves a page one position left (-1) or right (+1) among the normal pages.
    func movePage(_ page: Page, by offset: Int) {
        var pages = normalPages()
        guard let index = pages.firstIndex(where: { $0.id == page.id }) else { return }
        let target = index + offset
        guard pages.indices.contains(target) else { return }
        pages.swapAt(index, target)
        for (position, page) in pages.enumerated() {
            page.sortIndex = position
        }
        save()
    }

    /// Changes the grid size. Returns false when there are more pictograms than slots.
    @discardableResult
    func resize(_ page: Page, columns: Int, rows: Int) -> Bool {
        let newSize = GridSize(columns: columns, rows: rows)
        let placements = page.placements ?? []
        var slots: [UUID: Int] = [:]
        for placement in placements {
            slots[placement.id] = placement.slot
        }
        guard let mapping = GridMath.resize(slots, from: page.gridSize, to: newSize) else { return false }
        for placement in placements {
            if let slot = mapping[placement.id] {
                placement.slot = slot
            }
        }
        page.columns = newSize.columns
        page.rows = newSize.rows
        save()
        return true
    }

    // MARK: Pictograms

    /// Creates a pictogram and places it on a page, in the given slot or the first free one.
    @discardableResult
    func createPictogram(
        label: String,
        spokenText: String? = nil,
        imageData: Data? = nil,
        recordingData: Data? = nil,
        source: PictogramSource = .photo,
        on page: Page,
        slot: Int? = nil
    ) -> Placement? {
        let target: Int
        if let slot, page.gridSize.contains(slot), page.placement(at: slot) == nil {
            target = slot
        } else if let free = GridMath.firstFreeSlot(occupied: page.occupiedSlots, capacity: page.gridSize.capacity) {
            target = free
        } else {
            return nil
        }

        let pictogram = Pictogram(label: label, spokenText: spokenText, imageData: imageData, recordingData: recordingData, source: source)
        context.insert(pictogram)
        let placement = Placement(slot: target)
        context.insert(placement)
        placement.page = page
        placement.pictogram = pictogram
        save()
        return placement
    }

    /// Drops a placement on a slot. If the slot is taken, the two pictograms swap places,
    /// so every other pictogram stays where the child expects it.
    @discardableResult
    func move(_ placement: Placement, to page: Page, slot: Int) -> Bool {
        guard page.gridSize.contains(slot) else { return false }
        let sourcePage = placement.page
        let sourceSlot = placement.slot
        if sourcePage?.id == page.id, sourceSlot == slot { return true }

        if let occupant = page.placement(at: slot), occupant.id != placement.id {
            occupant.page = sourcePage
            occupant.slot = sourceSlot
        }
        placement.page = page
        placement.slot = slot
        save()
        return true
    }

    /// Moves a placement to the first free slot of another page. Returns false when that page is full.
    @discardableResult
    func move(_ placement: Placement, toPage page: Page) -> Bool {
        if placement.page?.id == page.id { return true }
        guard let slot = GridMath.firstFreeSlot(occupied: page.occupiedSlots, capacity: page.gridSize.capacity) else {
            return false
        }
        return move(placement, to: page, slot: slot)
    }

    /// Places the same pictogram on another page too. Returns false when that page is full.
    @discardableResult
    func duplicate(_ placement: Placement, toPage page: Page) -> Bool {
        guard let pictogram = placement.pictogram,
              let slot = GridMath.firstFreeSlot(occupied: page.occupiedSlots, capacity: page.gridSize.capacity)
        else { return false }
        let copy = Placement(slot: slot)
        context.insert(copy)
        copy.page = page
        copy.pictogram = pictogram
        save()
        return true
    }

    func setHidden(_ placement: Placement, _ hidden: Bool) {
        placement.isHidden = hidden
        save()
    }

    /// Removes a placement. The pictogram is deleted too when it is not placed anywhere else.
    func remove(_ placement: Placement) {
        removeWithoutSaving(placement)
        save()
    }

    private func removeWithoutSaving(_ placement: Placement) {
        let pictogram = placement.pictogram
        let isLastPlacement = (pictogram?.placements ?? []).allSatisfy { $0.id == placement.id }
        context.delete(placement)
        if let pictogram, isLastPlacement {
            context.delete(pictogram)
        }
    }

    // MARK: Starter content

    /// A first page with 4 empty slots and the permanent bar with "Non" and "Aide".
    /// Safe to call several times: it only creates what is missing.
    func seedStarterContent() {
        if normalPages().isEmpty {
            addPage(title: "Mes choses", columns: 2, rows: 2)
        }
        if permanentBar() == nil {
            let bar = Page(title: "Barre permanente", columns: 6, rows: 1, sortIndex: 0, kind: .permanentBar)
            context.insert(bar)
            createPictogram(
                label: "Non",
                spokenText: "Non",
                imageData: ImageTools.symbolCard(systemName: "hand.raised.fill", tint: .systemRed),
                source: .symbol,
                on: bar,
                slot: 0
            )
            createPictogram(
                label: "Aide",
                spokenText: "J'ai besoin d'aide",
                imageData: ImageTools.symbolCard(systemName: "person.fill.questionmark", tint: .systemBlue),
                source: .symbol,
                on: bar,
                slot: 1
            )
        }
        save()
    }

    func save() {
        do {
            try context.save()
        } catch {
            print("Save failed: \(error)")
        }
    }
}
