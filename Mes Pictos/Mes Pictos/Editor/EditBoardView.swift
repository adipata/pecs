import SwiftUI
import SwiftData

/// Mode parent : même classeur, mais éditable. Déplacement des cartes par
/// glisser-déposer (dans la page, entre les onglets), menus contextuels,
/// création de pages et réglages (plan §3.1).
struct EditBoardView: View {

    @Binding var isParentMode: Bool
    @Binding var currentPageID: UUID?

    @Environment(\.modelContext) private var context
    @Environment(SettingsStore.self) private var settings
    @Environment(SpeechService.self) private var speech

    @Query(sort: [SortDescriptor(\Page.sortIndex), SortDescriptor(\Page.createdAt)],
           animation: .default)
    private var allPages: [Page]

    private var normalPages: [Page] {
        allPages.filter { $0.kind == .normal }
    }

    private var barPages: [Page] {
        allPages.filter { $0.kind == .permanentBar }
    }

    // Feuilles et dialogues
    @State private var editorTarget: EditorTarget?
    @State private var pageSettingsTarget: PageSettingsTarget?
    @State private var showSettings = false
    @State private var showPageManager = false
    @State private var pageToDelete: Page?
    @State private var alertPayload: AlertPayload?

    struct AlertPayload: Identifiable {
        let id = UUID()
        let title: String
        let message: String?
    }

    enum PageSettingsTarget: Identifiable {
        case existing(Page)
        case new

        var id: String {
            switch self {
            case .existing(let page): return "existing-\(page.id)"
            case .new: return "new"
            }
        }
    }

    private var barPage: Page { barPages.first ?? BoardOps.permanentBarPage(in: context) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PageTabBar(
                    pages: normalPages,
                    selection: $currentPageID,
                    isEditing: true,
                    onAddPage: { pageSettingsTarget = .new },
                    onEditPage: { pageSettingsTarget = .existing($0) },
                    onHidePage: { page in
                        page.isHidden.toggle()
                    },
                    onDeletePage: { page in pageToDelete = page },
                    onMovePage: { page, delta in movePage(page, by: delta) },
                    onPlacementDropped: { payload, page in dropOnTab(payload, on: page) }
                )
                boardGrid
            }
            .safeAreaInset(edge: .bottom) {
                editBar
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Mode parent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isParentMode = false
                    } label: {
                        Label("Terminé", systemImage: "lock.fill")
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        pageSettingsTarget = .new
                    } label: {
                        Label("Nouvelle page", systemImage: "plus.rectangle")
                    }
                    Button {
                        showPageManager = true
                    } label: {
                        Label("Pages", systemImage: "rectangle.stack")
                    }
                    Button {
                        showSettings = true
                    } label: {
                        Label("Réglages", systemImage: "gearshape")
                    }
                }
            }
        }
        .sheet(item: $editorTarget) { target in
            PictogramEditorView(target: target)
        }
        .sheet(item: $pageSettingsTarget) { target in
            PageSettingsSheet(target: target) { payload in
                alertPayload = payload
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showPageManager) {
            PageManagerView(currentPageID: $currentPageID)
        }
        .alert(
            alertPayload?.title ?? "",
            isPresented: Binding(get: { alertPayload != nil },
                                 set: { if !$0 { alertPayload = nil } }),
            presenting: alertPayload
        ) { _ in
            Button("OK") {}
        } message: { payload in
            if let message = payload.message {
                Text(message)
            }
        }
        .confirmationDialog(
            pageToDelete.map { "Supprimer la page « \($0.title) » ?" } ?? "",
            isPresented: Binding(get: { pageToDelete != nil },
                                 set: { if !$0 { pageToDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Supprimer la page", role: .destructive) {
                if let page = pageToDelete { deletePage(page) }
            }
        } message: {
            Text("Ses cartes quittent la page mais restent dans la bibliothèque.")
        }
        .onAppear(perform: ensureCurrentPage)
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
                Text("Créez une première page avec le bouton + en haut à droite.")
                    .foregroundStyle(.secondary)
                    .padding(40)
            }
        }
    }

    private var currentPage: Page? {
        if let id = currentPageID, let page = normalPages.first(where: { $0.id == id }) {
            return page
        }
        return normalPages.first
    }

    private func ensureCurrentPage() {
        if currentPageID == nil || currentPage == nil {
            currentPageID = normalPages.first?.id
        }
    }

    private func gridColumns(for page: Page) -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 14), count: max(page.columns, 1))
    }

    @ViewBuilder
    private func cell(for slot: Int, on page: Page) -> some View {
        if let placement = BoardOps.occupant(atSlot: slot, on: page),
           let pictogram = placement.pictogram {
            occupiedCell(placement, pictogram: pictogram, slot: slot, page: page)
        } else {
            emptyCell(slot: slot, on: page)
        }
    }

    private func occupiedCell(_ placement: Placement,
                              pictogram: Pictogram,
                              slot: Int,
                              page: Page) -> some View {
        PictoCardView(pictogram: pictogram)
            .aspectRatio(1, contentMode: .fit)
            .opacity(placement.isHidden ? 0.45 : 1)
            .overlay(alignment: .topLeading) {
                if placement.isHidden {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(Circle().fill(.orange))
                        .padding(6)
                }
            }
            .draggable(PlacementPayload(placementID: placement.id))
            .dropDestination(for: PlacementPayload.self) { items, _ in
                drop(items.first, atSlot: slot, on: page)
            }
            .contextMenu {
                contextMenu(for: placement)
            }
            .onTapGesture {
                if let pictogramID = placement.pictogram?.id {
                    editorTarget = .editPictogram(pictogramID: pictogramID)
                }
            }
            .accessibilityHint("Touchez pour modifier la carte")
    }

    private func emptyCell(slot: Int, on page: Page) -> some View {
        Image(systemName: "plus")
            .font(.title2.weight(.semibold))
            .foregroundStyle(Color.accentColor.opacity(0.75))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(0.5),
                                  style: StrokeStyle(lineWidth: 1.5, dash: [7, 5]))
            )
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .onTapGesture {
                editorTarget = .create(pageID: page.id, slot: slot)
            }
            .dropDestination(for: PlacementPayload.self) { items, _ in
                drop(items.first, atSlot: slot, on: page)
            }
            .dropDestination(for: Image.self) { images, _ in
                // Image glissée depuis une autre app (Photos, Safari…).
                guard let image = images.first else { return false }
                return importImage(image, atSlot: slot, on: page)
            }
            .accessibilityLabel("Ajouter un pictogramme")
    }

    // MARK: - Barre permanente (édition)

    private var editBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(barPlacements) { placement in
                    if let pictogram = placement.pictogram {
                        BarPictoCardView(pictogram: pictogram)
                            .frame(width: 92)
                            .opacity(placement.isHidden ? 0.45 : 1)
                            .contextMenu {
                                barContextMenu(for: placement)
                            }
                            .onTapGesture {
                                editorTarget = .editPictogram(pictogramID: pictogram.id)
                            }
                    }
                }

                Button {
                    addBarCard()
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .frame(width: 52, height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.accentColor.opacity(0.5),
                                              style: StrokeStyle(lineWidth: 1.5, dash: [7, 5]))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Ajouter une carte à la barre permanente")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(height: 84)
        .background(Color(uiColor: .secondarySystemBackground).opacity(0.6))
    }

    private var barPlacements: [Placement] {
        (barPage.placements ?? [])
            .filter { !$0.isHidden }
            .sorted { $0.slot < $1.slot }
    }

    private func addBarCard() {
        let slot = BoardOps.firstEmptySlot(on: barPage) ?? barPage.slotCount
        editorTarget = .create(pageID: barPage.id, slot: slot)
    }

    @ViewBuilder
    private func barContextMenu(for placement: Placement) -> some View {
        Button {
            if let pictogramID = placement.pictogram?.id {
                editorTarget = .editPictogram(pictogramID: pictogramID)
            }
        } label: {
            Label("Modifier…", systemImage: "pencil")
        }
        Button(placement.isHidden ? "Afficher dans la barre" : "Masquer dans la barre") {
            placement.isHidden.toggle()
        }
        Divider()
        Button("Supprimer de la barre", role: .destructive) {
            BoardOps.removePlacement(placement, in: context)
        }
    }

    // MARK: - Menus contextuels

    @ViewBuilder
    private func contextMenu(for placement: Placement) -> some View {
        Button {
            if let pictogramID = placement.pictogram?.id {
                editorTarget = .editPictogram(pictogramID: pictogramID)
            }
        } label: {
            Label("Modifier…", systemImage: "pencil")
        }
        Button(placement.isHidden ? "Afficher sur la page" : "Masquer sur la page") {
            placement.isHidden.toggle()
        }
        if let page = placement.page {
            Menu("Déplacer vers…") {
                ForEach(otherPages(excluding: page)) { targetPage in
                    Button(targetPage.title.isEmpty ? "Sans titre" : targetPage.title) {
                        move(placement, to: targetPage)
                    }
                }
            }
            Menu("Dupliquer vers…") {
                ForEach(otherPages(excluding: page)) { targetPage in
                    Button(targetPage.title.isEmpty ? "Sans titre" : targetPage.title) {
                        duplicate(placement, to: targetPage)
                    }
                }
            }
        }
        Divider()
        Button("Supprimer de la page", role: .destructive) {
            BoardOps.removePlacement(placement, in: context)
        }
    }

    private func otherPages(excluding page: Page) -> [Page] {
        normalPages.filter { $0.id != page.id }
    }

    private func move(_ placement: Placement, to page: Page) {
        if !BoardOps.place(placement, onPage: page) {
            Haptics.warning()
            alertPayload = AlertPayload(
                title: "Page « \(page.title) » pleine",
                message: "Agrandissez la grille de cette page, ou masquez une carte.")
        } else {
            Haptics.success()
        }
    }

    private func duplicate(_ placement: Placement, to page: Page) {
        if BoardOps.duplicate(placement, onto: page, in: context) == nil {
            Haptics.warning()
            alertPayload = AlertPayload(
                title: "Page « \(page.title) » pleine",
                message: "Agrandissez la grille de cette page, ou masquez une carte.")
        } else {
            Haptics.success()
        }
    }

    // MARK: - Drag & drop

    private func drop(_ payload: PlacementPayload?, atSlot slot: Int, on page: Page) -> Bool {
        guard let payload,
              let placement = BoardOps.placement(withID: payload.placementID, in: context) else {
            return false
        }
        // Déposer sur sa propre case : rien à faire.
        if placement.page?.id == page.id && placement.slot == slot { return true }
        BoardOps.place(placement, atSlot: slot, on: page)
        Haptics.success()
        return true
    }

    /// Déposer sur un onglet : la carte va au premier slot libre de la page.
    private func dropOnTab(_ payload: PlacementPayload, on page: Page) {
        guard let placement = BoardOps.placement(withID: payload.placementID, in: context) else { return }
        if placement.page?.id != page.id {
            move(placement, to: page)
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            currentPageID = page.id
        }
    }

    private func importImage(_ image: Image, atSlot slot: Int, on page: Page) -> Bool {
        let renderer = ImageRenderer(content: image)
        guard let rendered = renderer.uiImage,
              let raw = rendered.jpegData(compressionQuality: 0.9) ?? rendered.pngData(),
              let normalized = ImageNormalizer.normalize(raw) else {
            return false
        }
        let pictogram = Pictogram(label: "", image: normalized, sourceKind: .imported)
        BoardOps.add(pictogram, atSlot: slot, on: page, in: context)
        try? context.save()
        editorTarget = .editPictogram(pictogramID: pictogram.id)
        return true
    }

    // MARK: - Pages

    private func movePage(_ page: Page, by delta: Int) {
        BoardOps.movePage(page, by: delta, in: normalPages)
    }

    private func deletePage(_ page: Page) {
        if currentPageID == page.id {
            currentPageID = nil
        }
        context.delete(page)
        try? context.save()
        ensureCurrentPage()
    }
}
