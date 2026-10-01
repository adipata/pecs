import SwiftUI

/// Mode montrer (plan §3.1) : la carte choisie part au centre de l'écran,
/// la page s'assombrit derrière. La carte reste affichée pour que l'enfant
/// montre la tablette à un adulte, comme il tendrait une carte papier.
/// L'adulte referme. L'enfant peut retaper la carte pour la réentendre.
struct ShowModeOverlay: View {

    let placement: Placement
    let namespace: Namespace.ID
    var onClose: () -> Void

    @Environment(SettingsStore.self) private var settings
    @Environment(SpeechService.self) private var speech
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Petite fête (rebond + halo doux), optionnelle dans les réglages.
    @State private var celebrated = false

    private var closeBehavior: ShowModeClose { settings.showModeClose }

    var body: some View {
        GeometryReader { geo in
            let side = min(min(geo.size.width, geo.size.height) * 0.62, 440)
            ZStack {
                background
                if let pictogram = placement.pictogram {
                    card(pictogram: pictogram, side: side)
                }
            }
        }
        .ignoresSafeArea()
        .overlay {
            if closeBehavior == .adultOnly {
                // Fermeture adulte : tap à deux doigts ou appui long.
                TwoFingerTapper { onClose() }
                    .ignoresSafeArea()
            }
        }
        .apply { overlay in
            if closeBehavior == .adultOnly {
                overlay.onLongPressGesture(minimumDuration: 1.2) {
                    onClose()
                }
            } else {
                overlay
            }
        }
        .task(id: placement.id) {
            await autoCloseIfEnabled()
        }
    }

    // MARK: - Carte agrandie

    private func card(pictogram: Pictogram, side: CGFloat) -> some View {
        let base = PictoCardView(pictogram: pictogram)
            .frame(width: side, height: side * 1.05)
            .scaleEffect(celebrated ? 1 : 0.92)
            .shadow(color: shadowColor, radius: celebrated ? 24 : 12, y: 6)
            .onTapGesture {
                // Retaper la carte : la faire parler encore.
                Haptics.tap()
                speech.speak(pictogram)
            }
            .onAppear(perform: celebrateIfNeeded)

        let withGeometryEffect: AnyView
        if reduceMotion {
            // « Réduire le mouvement » : fondu sur place, pas de vol.
            withGeometryEffect = AnyView(base.transition(.opacity))
        } else {
            withGeometryEffect = AnyView(
                base.matchedGeometryEffect(id: placement.id, in: namespace))
        }

        let withSwipe: AnyView
        if closeBehavior == .swipeDown {
            withSwipe = AnyView(withGeometryEffect.gesture(swipeDownGesture))
        } else {
            withSwipe = withGeometryEffect
        }
        return withSwipe
    }

    private var shadowColor: Color {
        if celebrated {
            return Color.yellow.opacity(0.35)
        }
        return Color.black.opacity(0.25)
    }

    // MARK: - Fond

    /// Fond assombri et flouté. Referme le mode montrer si le réglage
    /// « toucher à côté » est actif.
    private var background: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(Color.black.opacity(0.30))
            .ignoresSafeArea()
            .onTapGesture {
                if closeBehavior == .tapOutside {
                    onClose()
                }
            }
    }

    // MARK: - Fermetures

    /// Glisser la carte vers le bas (réglage dédié).
    private var swipeDownGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                if value.translation.height > 100 {
                    onClose()
                }
            }
    }

    /// Fermeture automatique après N secondes (0 = désactivée).
    private func autoCloseIfEnabled() async {
        let seconds = settings.showModeAutoCloseSeconds
        guard seconds > 0 else { return }
        try? await Task.sleep(for: .seconds(seconds))
        guard !Task.isCancelled else { return }
        onClose()
    }

    private func celebrateIfNeeded() {
        guard settings.showModeCelebration else { return }
        withAnimation(.spring(response: 0.38, dampingFraction: 0.55).delay(0.4)) {
            celebrated = true
        }
    }
}

// Utilitaire partagé pour appliquer conditionnellement des modificateurs.
extension View {
    @ViewBuilder
    func apply(@ViewBuilder _ modifier: (Self) -> some View) -> some View {
        modifier(self)
    }
}
