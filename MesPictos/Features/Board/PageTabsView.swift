import SwiftUI

/// The page tabs. In parent mode they are also drop targets: hold a dragged card over a tab
/// to open that page, then drop it in a slot.
struct PageTabsView: View {
    let pages: [Page]
    let selectedID: UUID?

    @Environment(BoardModel.self) private var board
    @Environment(\.modelContext) private var context

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(pages) { page in
                    PageTab(page: page, isSelected: page.id == selectedID, isFirst: page.id == pages.first?.id, isLast: page.id == pages.last?.id)
                }
                if board.isParentMode {
                    Button {
                        let page = PictoStore(context: context).addPage(title: "Nouvelle page")
                        board.selectedPageID = page.id
                        board.pageSettings = page
                    } label: {
                        Label("Page", systemImage: "plus")
                            .padding(.horizontal, 6)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PageTab: View {
    let page: Page
    let isSelected: Bool
    let isFirst: Bool
    let isLast: Bool

    @Environment(BoardModel.self) private var board
    @Environment(\.modelContext) private var context
    @State private var isDropTarget = false
    @State private var springLoad: Task<Void, Never>?

    var body: some View {
        if board.isParentMode {
            tab
                .contextMenu {
                    Button {
                        board.pageSettings = page
                    } label: {
                        Label("Réglages de la page", systemImage: "slider.horizontal.3")
                    }
                    if !isFirst {
                        Button {
                            PictoStore(context: context).movePage(page, by: -1)
                        } label: {
                            Label("Déplacer à gauche", systemImage: "arrow.left")
                        }
                    }
                    if !isLast {
                        Button {
                            PictoStore(context: context).movePage(page, by: 1)
                        } label: {
                            Label("Déplacer à droite", systemImage: "arrow.right")
                        }
                    }
                    Divider()
                    Button(role: .destructive) {
                        board.pageToDelete = page
                    } label: {
                        Label("Supprimer la page", systemImage: "trash")
                    }
                }
                .dropDestination(for: String.self) { items, _ in
                    springLoad?.cancel()
                    guard let first = items.first, let id = UUID(uuidString: first) else { return false }
                    let store = PictoStore(context: context)
                    guard let moving = store.placement(withID: id) else { return false }
                    if !store.move(moving, toPage: page) {
                        board.alertMessage = "La page « \(page.displayTitle) » est pleine. Agrandissez sa grille ou libérez une case."
                        return false
                    }
                    board.selectedPageID = page.id
                    return true
                } isTargeted: { targeted in
                    isDropTarget = targeted
                    springLoad?.cancel()
                    if targeted {
                        springLoad = Task {
                            try? await Task.sleep(for: .milliseconds(700))
                            if !Task.isCancelled {
                                board.selectedPageID = page.id
                            }
                        }
                    }
                }
        } else {
            tab
        }
    }

    private var tab: some View {
        Button {
            board.selectedPageID = page.id
        } label: {
            HStack(spacing: 6) {
                if page.isHidden {
                    Image(systemName: "eye.slash")
                }
                Text(page.displayTitle)
                    .lineLimit(1)
            }
            .font(.title3.weight(.semibold))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                Capsule().stroke(Color.accentColor, lineWidth: isDropTarget ? 3 : 0)
            )
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .opacity(page.isHidden ? 0.6 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
