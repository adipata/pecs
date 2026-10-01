import SwiftUI

/// Barre permanente en bas de l'écran : les cartes critiques (Non, Aide…)
/// toujours visibles, plus le verrou du mode parent (plan §3.1).
struct PermanentBarView: View {

    let placements: [Placement]
    let shownPlacementID: UUID?
    let namespace: Namespace.ID
    var onCardTap: ((Placement) -> Void)
    var onUnlocked: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(placements) { placement in
                if let pictogram = placement.pictogram {
                    BarPictoCardView(pictogram: pictogram)
                        .matchedGeometryEffect(id: placement.id, in: namespace,
                                               isSource: shownPlacementID != placement.id)
                        .opacity(shownPlacementID == placement.id ? 0 : 1)
                        .onTapGesture { onCardTap(placement) }
                        .accessibilityAddTraits(.isButton)
                }
            }
            Spacer(minLength: 0)
            LockButton(onUnlocked: onUnlocked)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(height: 84)
        .background(Color(uiColor: .secondarySystemBackground).opacity(0.6))
    }
}

/// Verrou du mode parent : appui long de 3 secondes (plan §3.1),
/// avec un anneau de progression pour montrer que ça avance.
struct LockButton: View {

    var onUnlocked: () -> Void

    @State private var progress: Double = 0
    @State private var holdStart: Date?
    @State private var timer: Timer?

    private let duration: TimeInterval = 3.0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.25), lineWidth: 3)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: progress > 0 ? "lock.open" : "lock.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(width: 44, height: 44)
        .background(Circle().fill(Color(uiColor: .systemBackground)))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in beginHoldIfNeeded() }
                .onEnded { _ in endHold() }
        )
        .accessibilityLabel("Mode parent")
        .accessibilityHint("Gardez appuyé 3 secondes pour déverrouiller le mode parent.")
        .accessibilityAddTraits(.isButton)
        // Accessibilité : l'appui long est difficile avec Switch Control ;
        // l'action d'accessibilité déclenche le même flux (protégé par code/Face ID).
        .accessibilityAction { onUnlocked() }
    }

    private func beginHoldIfNeeded() {
        guard holdStart == nil else { return }
        holdStart = Date()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            Task { @MainActor in
                guard let start = holdStart else { return }
                progress = min(Date().timeIntervalSince(start) / duration, 1)
                if progress >= 1 {
                    finish()
                }
            }
        }
    }

    private func finish() {
        timer?.invalidate()
        timer = nil
        holdStart = nil
        progress = 0
        Haptics.success()
        onUnlocked()
    }

    private func endHold() {
        timer?.invalidate()
        timer = nil
        holdStart = nil
        withAnimation(.easeOut(duration: 0.2)) { progress = 0 }
    }
}
