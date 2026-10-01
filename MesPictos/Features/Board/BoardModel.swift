import SwiftUI
import UIKit
import PictoCore

/// What the board is showing and which sheet is open.
@MainActor
@Observable
final class BoardModel {
    var isParentMode = false
    var selectedPageID: UUID?

    /// The card shown in the centre of the screen (show mode).
    var shown: Placement?
    /// Brief highlight when show mode is off.
    var highlightedID: UUID?

    var editor: EditorRequest?
    var pageSettings: Page?
    var pageToDelete: Page?
    var showSettings = false
    var alertMessage: String?

    @ObservationIgnored private var debouncer = TapDebouncer()

    /// The child tapped a card.
    func select(_ placement: Placement, reduceMotion: Bool) {
        let defaults = UserDefaults.standard
        let interval = defaults.double(forKey: SettingsKey.tapInterval, default: SettingsDefault.tapInterval)
        guard debouncer.shouldAccept(at: Date(), minimumInterval: interval) else { return }
        guard let pictogram = placement.pictogram else { return }

        SpeechService.shared.speak(pictogram)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        if defaults.bool(forKey: SettingsKey.showModeEnabled, default: SettingsDefault.showModeEnabled) {
            withAnimation(Self.showAnimation(reduceMotion: reduceMotion)) {
                shown = placement
            }
        } else {
            let id = placement.id
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                highlightedID = id
            }
            Task {
                try? await Task.sleep(for: .milliseconds(600))
                withAnimation(.easeOut(duration: 0.2)) {
                    if highlightedID == id { highlightedID = nil }
                }
            }
        }
    }

    func closeShown(reduceMotion: Bool) {
        guard shown != nil else { return }
        withAnimation(Self.showAnimation(reduceMotion: reduceMotion)) {
            shown = nil
        }
    }

    static func showAnimation(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.25) : .spring(response: 0.45, dampingFraction: 0.82)
    }
}

struct EditorRequest: Identifiable {
    let id = UUID()
    let page: Page
    let slot: Int
    /// nil when creating a new pictogram.
    let placement: Placement?
}

extension View {
    /// The flying-card effect between the grid and the centre of the screen.
    @ViewBuilder
    func heroEffect(id: UUID, in namespace: Namespace.ID, enabled: Bool) -> some View {
        if enabled {
            matchedGeometryEffect(id: id, in: namespace)
        } else {
            self
        }
    }
}
