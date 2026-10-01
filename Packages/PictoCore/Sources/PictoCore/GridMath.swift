import Foundation

/// Size of a page grid. Slots are numbered row by row: `slot = row * columns + column`.
public struct GridSize: Equatable, Sendable {
    public static let columnRange = 1...8
    public static let rowRange = 1...6

    public let columns: Int
    public let rows: Int

    public init(columns: Int, rows: Int) {
        self.columns = min(max(columns, Self.columnRange.lowerBound), Self.columnRange.upperBound)
        self.rows = min(max(rows, Self.rowRange.lowerBound), Self.rowRange.upperBound)
    }

    public var capacity: Int { columns * rows }

    public func row(of slot: Int) -> Int { slot / columns }
    public func column(of slot: Int) -> Int { slot % columns }
    public func contains(_ slot: Int) -> Bool { slot >= 0 && slot < capacity }
}

public enum GridMath {
    /// The lowest slot that is not occupied, or nil when the page is full.
    public static func firstFreeSlot(occupied: Set<Int>, capacity: Int) -> Int? {
        (0..<max(capacity, 0)).first { !occupied.contains($0) }
    }

    /// New slots after a grid resize.
    ///
    /// Items keep their visual position (row, column) when it still exists in the new grid.
    /// The others are placed in the free slots, in their previous order.
    /// Returns nil when there are more items than slots in the new grid.
    public static func resize<ID: Hashable>(
        _ slots: [ID: Int],
        from old: GridSize,
        to new: GridSize
    ) -> [ID: Int]? {
        guard slots.count <= new.capacity else { return nil }

        var result: [ID: Int] = [:]
        var overflow: [(ID, Int)] = []
        var taken = Set<Int>()

        for (id, slot) in slots.sorted(by: { $0.value < $1.value }) {
            let row = old.row(of: slot)
            let column = old.column(of: slot)
            let candidate = row * new.columns + column
            if row < new.rows, column < new.columns, !taken.contains(candidate) {
                result[id] = candidate
                taken.insert(candidate)
            } else {
                overflow.append((id, slot))
            }
        }

        for (id, _) in overflow {
            guard let free = firstFreeSlot(occupied: taken, capacity: new.capacity) else { return nil }
            result[id] = free
            taken.insert(free)
        }
        return result
    }
}
