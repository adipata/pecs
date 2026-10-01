import Foundation

/// Ignores taps that come too quickly after the previous accepted one.
public struct TapDebouncer: Sendable {
    private var lastAccepted: Date?

    public init() {}

    public mutating func shouldAccept(at date: Date, minimumInterval: TimeInterval) -> Bool {
        if let lastAccepted, date.timeIntervalSince(lastAccepted) < minimumInterval {
            return false
        }
        lastAccepted = date
        return true
    }
}
