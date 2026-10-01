import SwiftUI
import SwiftData

/// The main screen. Child mode by default; parent mode after the 3-second press on the lock.
struct BoardView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Query(sort: [SortDescriptor(\Page.sortIndex), SortDescriptor(\Page.createdAt)]) private var allPages: [Page]

    @State private var board = BoardModel()
    @State private var showCodeEntry = false
    @Namespace private var hero

    @AppStorage(SettingsKey.showPageTabs) private var showPageTabs = SettingsDefault.showPageTabs
    @AppStorage(SettingsKey.parentProtection) private var protectionRaw = ParentProtection.gestureOnly.rawValue
    @AppStorage(SettingsKey.lastPageID) private var lastPageID = ""

    private var normalPages: [Page] { allPages.filter { $0.kind == .normal } }
    private var visiblePages: [Page] { board.isParentMode ? normalPages : normalPages.filter { !$0.isHidden } }
    private var bar: Page? { PictoStore.permanentBar(in: allPages) }
    private var currentPage: Page? {
        visiblePages.first { $0.id == board.selectedPageID } ?? visiblePages.first
    }
    private var menuPages: [Page] {
        var pages = normalPages
        if let bar { pages.append(bar) }
        return pages
    }
    private var isCompact: Bool { sizeClass == .compact }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                mainContent
                    .blur(radius: board.shown == nil ? 0 : 6)
                    .allowsHitTesting(board.shown == nil)

                if let shown = board.shown {
                    ShowOverlay(placement: shown, namespace: hero, containerSize: geometry.size)
                        .zIndex(1)
                }
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .statusBarHidden(!board.isParentMode)
        .persistentSystemOverlays(board.isParentMode ? .automatic : .hidden)
        .onAppear {
            if board.selectedPageID == nil, let id = UUID(uuidString: lastPageID) {
                board.selectedPageID = id
            }
            SpeechService.shared.prewarm()
        }
        .onChange(of: board.selectedPageID) { _, newValue in
            lastPageID = newValue?.uuidString ?? ""
        }
        .sheet(item: $board.editor) { request in
            PictogramEditorView(request: request)
        }
        .sheet(item: $board.pageSettings) { page in
            PageSettingsView(page: page)
        }
        .sheet(isPresented: $board.showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showCodeEntry) {
            ParentCodeEntryView {
                enterParentMode()
            }
        }
        .alert("Impossible", isPresented: alertBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(board.alertMessage ?? "")
        }
        .confirmationDialog(
            "Supprimer la page « \(board.pageToDelete?.displayTitle ?? "") » ?",
            isPresented: deleteBinding,
            titleVisibility: .visible
        ) {
            Button("Supprimer la page et ses pictogrammes", role: .destructive) {
                if let page = board.pageToDelete {
                    PictoStore(context: context).delete(page)
                }
                board.pageToDelete = nil
            }
            Button("Annuler", role: .cancel) {
                board.pageToDelete = nil
            }
        } message: {
            Text("Les pictogrammes qui sont aussi sur une autre page y restent.")
        }
        .environment(board)
    }

    // MARK: Layout

    private var mainContent: some View {
        VStack(spacing: 0) {
            if board.isParentMode {
                ParentToolbar(currentPage: currentPage, onDone: leaveParentMode)
            }

            topRow
                .padding(.horizontal, 16)
                .padding(.top, 8)

            if let page = currentPage {
                GridPageView(page: page, menuPages: menuPages, namespace: hero, spacing: isCompact ? 10 : 18)
                    .padding(isCompact ? 12 : 24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                EmptyBoardView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if let bar, board.isParentMode || bar.hasVisibleCards {
                permanentBar(bar)
            }
        }
    }

    private var topRow: some View {
        HStack(spacing: 12) {
            if board.isParentMode || (showPageTabs && visiblePages.count > 1) {
                PageTabsView(pages: visiblePages, selectedID: currentPage?.id)
            } else {
                Spacer()
            }
            if !board.isParentMode {
                ParentLockButton(onUnlock: requestParentMode)
            }
        }
        .frame(minHeight: 52)
    }

    private func permanentBar(_ bar: Page) -> some View {
        VStack(spacing: 6) {
            if board.isParentMode {
                HStack {
                    Text("Barre permanente : toujours visible")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        board.pageSettings = bar
                    } label: {
                        Label("Cases", systemImage: "slider.horizontal.3")
                            .font(.footnote)
                    }
                }
            }
            GridPageView(page: bar, menuPages: menuPages, namespace: hero, spacing: isCompact ? 8 : 14)
                .frame(height: isCompact ? 76 : 120)
        }
        .padding(.horizontal, isCompact ? 12 : 24)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground).ignoresSafeArea(edges: .bottom))
    }

    // MARK: Parent mode

    private func requestParentMode() {
        switch ParentProtection(rawValue: protectionRaw) ?? .gestureOnly {
        case .gestureOnly:
            enterParentMode()
        case .code:
            if (UserDefaults.standard.string(forKey: SettingsKey.parentCode) ?? "").isEmpty {
                enterParentMode()
            } else {
                showCodeEntry = true
            }
        case .deviceAuth:
            Task {
                if await DeviceAuth.authenticate() {
                    enterParentMode()
                }
            }
        }
    }

    private func enterParentMode() {
        board.closeShown(reduceMotion: true)
        withAnimation(.easeInOut(duration: 0.2)) {
            board.isParentMode = true
        }
    }

    private func leaveParentMode() {
        withAnimation(.easeInOut(duration: 0.2)) {
            board.isParentMode = false
        }
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { board.alertMessage != nil },
            set: { if !$0 { board.alertMessage = nil } }
        )
    }

    private var deleteBinding: Binding<Bool> {
        Binding(
            get: { board.pageToDelete != nil },
            set: { if !$0 { board.pageToDelete = nil } }
        )
    }
}

/// Toolbar shown at the top in parent mode.
private struct ParentToolbar: View {
    let currentPage: Page?
    let onDone: () -> Void
    @Environment(BoardModel.self) private var board

    var body: some View {
        HStack(spacing: 12) {
            Label("Mode parent", systemImage: "lock.open.fill")
                .font(.headline)
                .foregroundStyle(Color.accentColor)
            Spacer()
            if let currentPage {
                Button {
                    board.pageSettings = currentPage
                } label: {
                    Label("Page", systemImage: "square.grid.2x2")
                }
            }
            Button {
                board.showSettings = true
            } label: {
                Label("Réglages", systemImage: "gearshape")
            }
            Button("Terminé", action: onDone)
                .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
    }
}

/// Shown when there is no page yet.
private struct EmptyBoardView: View {
    @Environment(BoardModel.self) private var board
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            if board.isParentMode {
                Text("Aucune page pour l'instant.")
                    .font(.title3)
                Button("Créer le contenu de départ") {
                    PictoStore(context: context).seedStarterContent()
                }
                .buttonStyle(.borderedProminent)
                Text("Si Mes Pictos est configuré sur un autre appareil avec le même compte iCloud, les pages arriveront automatiquement.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            } else {
                Text("Pas encore de page.\nAppuyez 3 secondes sur le cadenas pour ouvrir le mode parent.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
