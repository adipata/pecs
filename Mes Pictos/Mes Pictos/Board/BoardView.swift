import SwiftUI
import SwiftData

/// Tableau de l'enfant (mode par défaut) : onglets de pages, grille de
/// grandes cartes, barre permanente, mode montrer. Rien ici ne peut être
/// modifié ni supprimé par l'enfant (plan §3.1).
struct BoardView: View {

    @Binding var isParentMode: Bool
    @Binding var currentPageID: UUID?

    @Environment(\.modelContext) private var context
    @Environment(SettingsStore.self) private var settings
    @Environment(SpeechService.self) private var speech
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query(sort: [SortDescriptor(\Page.sortIndex), SortDescriptor(\Page.createdAt)],
           animation: .default)
    private var allPages: [Page]

    @State private var shownPlacement: Placement?
    @State private var lastTapAt: Date?
    @State private var presentingCodeEntry = false
    @Namespace private var cardNamespace

    /// Pages visibles du mode enfant (les pages masquées restent en mode parent).
    private var visiblePages: [Page] {
        allPages.filter { $0.kind == .normal && !$0.isHidden }
    }

    private var barPages: [Page] {
        allPages.filter { $0.kind == .permanentBar }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                PageTabBar(
                    pages: visiblePages,
                    selection: selectionBinding
                )
                boardGrid
            }
            .safeAreaInset(edge: .bottom) {
                PermanentBarView(
                    placements: barPlacements,
                    shownPlacementID: shownPlacement?.id,
                    namespace: cardNamespace,
                    onCardTap: handleTap,
                    onUnlocked: requestUnlock
                )
            }

            if let shown = shownPlacement {
                ShowModeOverlay(
                    placement: shown,
                    namespace: cardNamespace,
                    onClose: closeShowMode
                )
                .zIndex(10)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .sheet(isPresented: $presentingCodeEntry) {
            CodeEntrySheet(onSuccess: enterParentMode)
        }
        .onAppear(perform: ensureCurrentPage)
        .onChange(of: visiblePages) { _, _ in
            ensureCurrentPage()
        }
    }

    // MARK: - Grille

    private var boardGrid: some View {
        ScrollView {
            if let page = currentPage {
                LazyVGrid(columns: gridColumns(for: page), spacing: 14) {
                    ForEach(0..<page.slotCount, id: \.self) { slot in
                        cell(for: slot, on: page)
                    }
                }
                .padding()
                .id(page.id)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 52, weight: .light))
                        .foregroundStyle(.tertiary)
                    Text("Aucune page visible")
                        .font(.headline)
                    Text("Un adulte peut en créer une depuis le mode parent (verrou en bas à droite).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: 480)
                .padding(32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func gridColumns(for page: Page) -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 14), count: max(page.columns, 1))
    }

    @ViewBuilder
    private func cell(for slot: Int, on page: Page) -> some View {
        if let placement = visiblePlacement(at: slot, on: page),
           let pictogram = placement.pictogram {
            PictoCardView(pictogram: pictogram)
                .aspectRatio(1, contentMode: .fit)
                .matchedGeometryEffect(id: placement.id, in: cardNamespace,
                                       isSource: shownPlacement?.id != placement.id)
                .opacity(shownPlacement?.id == placement.id ? 0 : 1)
                .onTapGesture { handleTap(placement) }
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Touchez pour entendre et montrer")
        } else {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
        }
    }

    private func visiblePlacement(at slot: Int, on page: Page) -> Placement? {
        page.placements?.first { $0.slot == slot && !$0.isHidden }
    }

    private var barPlacements: [Placement] {
        (barPages.first?.placements ?? [])
            .filter { !$0.isHidden }
            .sorted { $0.slot < $1.slot }
    }

    // MARK: - Page courante

    /// L'app s'ouvre sur la dernière page utilisée (phase II, plan §0).
    private var currentPage: Page? {
        if let id = currentPageID,
           let page = visiblePages.first(where: { $0.id == id }) {
            return page
        }
        return visiblePages.first
    }

    private var selectionBinding: Binding<UUID?> {
        Binding(
            get: { currentPage?.id },
            set: { newValue in
                currentPageID = newValue
            }
        )
    }

    private func ensureCurrentPage() {
        if currentPageID == nil || currentPage == nil {
            currentPageID = visiblePages.first?.id
        }
    }

    // MARK: - Interaction carte

    /// Parle à chaque tap, immédiatement : le son est la récompense.
    /// Les tapes répétés sont ignorés pendant le délai réglé (plan §3.3.6).
    private func handleTap(_ placement: Placement) {
        guard let pictogram = placement.pictogram else { return }

        let now = Date()
        if let last = lastTapAt,
           now.timeIntervalSince(last) < settings.tapDebounceSeconds {
            return
        }
        lastTapAt = now

        speech.speak(pictogram)
        Haptics.tap()

        guard settings.showModeEnabled else { return }
        let animation: Animation = reduceMotion
            ? .easeInOut(duration: 0.25)
            : .spring(response: 0.4, dampingFraction: 0.8)
        withAnimation(animation) {
            shownPlacement = placement
        }
    }

    private func closeShowMode() {
        withAnimation(.easeInOut(duration: 0.25)) {
            shownPlacement = nil
        }
    }

    // MARK: - Verrou parent

    /// Après l'appui long : code et/ou Face ID si configurés.
    private func requestUnlock() {
        if settings.faceIDEnabled && ParentLock.biometricsAvailable() {
            Task {
                if await ParentLock.authenticateWithBiometrics() {
                    enterParentMode()
                } else if ParentLock.hasCode() {
                    // Face ID a échoué : le code de l'app reste utilisable.
                    presentingCodeEntry = true
                }
            }
        } else if ParentLock.hasCode() {
            presentingCodeEntry = true
        } else {
            enterParentMode()
        }
    }

    private func enterParentMode() {
        shownPlacement = nil
        isParentMode = true
    }
}
