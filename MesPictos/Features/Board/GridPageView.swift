import SwiftUI

/// A page laid out as a fixed grid. Every slot is always visible: no scrolling.
struct GridPageView: View {
    let page: Page
    /// Pages offered in the "Move to / Duplicate to" menus.
    let menuPages: [Page]
    let namespace: Namespace.ID
    var spacing: CGFloat = 16

    var body: some View {
        GeometryReader { geometry in
            let columns = page.columns
            let rows = page.rows
            let cellWidth = (geometry.size.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
            let cellHeight = (geometry.size.height - spacing * CGFloat(rows - 1)) / CGFloat(rows)
            let side = max(20, min(cellWidth, cellHeight))

            VStack(spacing: spacing) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<columns, id: \.self) { column in
                            SlotView(
                                page: page,
                                slot: row * columns + column,
                                menuPages: menuPages,
                                namespace: namespace
                            )
                            .frame(width: side, height: side)
                        }
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

/// One slot of a page: a card, an empty space (child mode) or a "+" (parent mode).
struct SlotView: View {
    let page: Page
    let slot: Int
    let menuPages: [Page]
    let namespace: Namespace.ID

    @Environment(BoardModel.self) private var board
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDropTarget = false

    var body: some View {
        let placement = page.placement(at: slot)
        if board.isParentMode {
            parentSlot(placement)
        } else {
            childSlot(placement)
        }
    }

    // MARK: Child mode

    @ViewBuilder
    private func childSlot(_ placement: Placement?) -> some View {
        if let placement, let pictogram = placement.pictogram, !placement.isHidden {
            if board.shown?.id == placement.id {
                // The card is in the centre of the screen; keep its place empty.
                Color.clear
            } else {
                CardView(pictogram: pictogram)
                    .heroEffect(id: placement.id, in: namespace, enabled: !reduceMotion)
                    .scaleEffect(board.highlightedID == placement.id ? 1.08 : 1)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        board.select(placement, reduceMotion: reduceMotion)
                    }
                    .accessibilityAddTraits(.isButton)
            }
        } else {
            Color.clear
        }
    }

    // MARK: Parent mode

    private func parentSlot(_ placement: Placement?) -> some View {
        ZStack {
            if let placement, let pictogram = placement.pictogram {
                CardView(pictogram: pictogram)
                    .opacity(placement.isHidden ? 0.35 : 1)
                    .overlay(alignment: .topTrailing) {
                        if placement.isHidden {
                            Image(systemName: "eye.slash.fill")
                                .font(.title3)
                                .padding(6)
                                .background(Circle().fill(.thinMaterial))
                                .padding(6)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        board.editor = EditorRequest(page: page, slot: slot, placement: placement)
                    }
                    .draggable(placement.id.uuidString) {
                        CardView(pictogram: pictogram)
                            .frame(width: 120, height: 120)
                    }
                    .contextMenu {
                        PlacementMenu(placement: placement, page: page, slot: slot, menuPages: menuPages)
                    }
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                    .foregroundStyle(Color.secondary.opacity(0.6))
                    .overlay(
                        Image(systemName: "plus")
                            .font(.largeTitle)
                            .foregroundStyle(Color.secondary)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        board.editor = EditorRequest(page: page, slot: slot, placement: nil)
                    }
                    .accessibilityLabel("Ajouter un pictogramme")
                    .accessibilityAddTraits(.isButton)
            }
        }
        .overlay {
            if isDropTarget {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.accentColor, lineWidth: 4)
            }
        }
        .dropDestination(for: String.self) { items, _ in
            guard let first = items.first, let id = UUID(uuidString: first) else { return false }
            let store = PictoStore(context: context)
            guard let moving = store.placement(withID: id) else { return false }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                _ = store.move(moving, to: page, slot: slot)
            }
            return true
        } isTargeted: { targeted in
            isDropTarget = targeted
        }
    }
}

/// Long-press menu on a card in parent mode.
struct PlacementMenu: View {
    let placement: Placement
    let page: Page
    let slot: Int
    let menuPages: [Page]

    @Environment(BoardModel.self) private var board
    @Environment(\.modelContext) private var context

    var body: some View {
        let store = PictoStore(context: context)
        let others = menuPages.filter { $0.id != page.id }

        Button {
            board.editor = EditorRequest(page: page, slot: slot, placement: placement)
        } label: {
            Label("Modifier", systemImage: "pencil")
        }

        if !others.isEmpty {
            Menu {
                ForEach(others) { target in
                    Button(target.displayTitle) {
                        if !store.move(placement, toPage: target) {
                            board.alertMessage = "La page « \(target.displayTitle) » est pleine. Agrandissez sa grille ou libérez une case."
                        }
                    }
                }
            } label: {
                Label("Déplacer vers…", systemImage: "arrow.right.doc.on.clipboard")
            }

            Menu {
                ForEach(others) { target in
                    Button(target.displayTitle) {
                        if !store.duplicate(placement, toPage: target) {
                            board.alertMessage = "La page « \(target.displayTitle) » est pleine. Agrandissez sa grille ou libérez une case."
                        }
                    }
                }
            } label: {
                Label("Ajouter aussi sur…", systemImage: "plus.square.on.square")
            }
        }

        Button {
            store.setHidden(placement, !placement.isHidden)
        } label: {
            if placement.isHidden {
                Label("Afficher pour l'enfant", systemImage: "eye")
            } else {
                Label("Masquer pour l'enfant", systemImage: "eye.slash")
            }
        }

        Divider()

        Button(role: .destructive) {
            store.remove(placement)
        } label: {
            Label("Retirer de la page", systemImage: "trash")
        }
    }
}
