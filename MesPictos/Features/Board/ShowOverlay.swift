import SwiftUI

/// Show mode: the selected card in the centre of the screen, so the child can show it to an adult.
struct ShowOverlay: View {
    let placement: Placement
    let namespace: Namespace.ID
    let containerSize: CGSize

    @Environment(BoardModel.self) private var board
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(SettingsKey.showDismissMode) private var dismissRaw = DismissMode.tapOutside.rawValue
    @AppStorage(SettingsKey.showAutoCloseSeconds) private var autoCloseSeconds = SettingsDefault.showAutoCloseSeconds
    @AppStorage(SettingsKey.showCelebration) private var celebration = SettingsDefault.showCelebration
    @State private var bump = 0
    @State private var glow = false

    private var dismissMode: DismissMode { DismissMode(rawValue: dismissRaw) ?? .tapOutside }
    private var side: CGFloat { min(containerSize.width, containerSize.height) * 0.72 }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    if dismissMode == .tapOutside { close() }
                }
                .onLongPressGesture(minimumDuration: 1) {
                    close()
                }
                .gesture(
                    DragGesture(minimumDistance: 40).onEnded { value in
                        if dismissMode == .tapOutside, value.translation.height > 120 { close() }
                    }
                )
                .transition(.opacity)

            if let pictogram = placement.pictogram {
                CardView(pictogram: pictogram)
                    .heroEffect(id: placement.id, in: namespace, enabled: !reduceMotion)
                    .frame(width: side, height: side)
                    .shadow(
                        color: glow ? Color.yellow.opacity(0.7) : Color.black.opacity(0.25),
                        radius: glow ? side * 0.08 : side * 0.03
                    )
                    .phaseAnimator([0, 1, 2], trigger: bump) { content, phase in
                        content.scaleEffect(phase == 1 ? 1.06 : 1)
                    } animation: { _ in
                        .spring(response: 0.22, dampingFraction: 0.55)
                    }
                    .onTapGesture {
                        SpeechService.shared.speak(pictogram)
                        if celebration && !reduceMotion { bump += 1 }
                    }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint("Touchez pour réécouter")
            }

            VStack {
                Spacer()
                Text(dismissMode == .tapOutside ? "Touchez à côté pour fermer" : "Appui long à côté pour fermer")
                    .font(.footnote)
                    .foregroundStyle(Color.white.opacity(0.55))
                    .padding(.bottom, 16)
            }
            .allowsHitTesting(false)
        }
        .task(id: placement.id) {
            if celebration && !reduceMotion {
                try? await Task.sleep(for: .milliseconds(420))
                withAnimation(.easeOut(duration: 0.4)) { glow = true }
                bump += 1
            }
            if autoCloseSeconds > 0 {
                try? await Task.sleep(for: .seconds(autoCloseSeconds))
                if !Task.isCancelled { close() }
            }
        }
    }

    private func close() {
        glow = false
        board.closeShown(reduceMotion: reduceMotion)
    }
}
