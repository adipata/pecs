import SwiftUI

/// Onglets de pages. En mode enfant : simples boutons. En mode parent :
/// menus contextuels, ajout, réorganisation et dépôt de cartes déplacées
/// vers la page (avec ouverture automatique après 0,6 s d'hover, plan §7.4).
struct PageTabBar: View {

    let pages: [Page]
    @Binding var selection: UUID?

    var isEditing = false

    // Rappels du mode parent
    var onAddPage: (() -> Void)? = nil
    var onEditPage: ((Page) -> Void)? = nil
    var onHidePage: ((Page) -> Void)? = nil
    var onDeletePage: ((Page) -> Void)? = nil
    var onMovePage: ((Page, Int) -> Void)? = nil
    var onPlacementDropped: ((PlacementPayload, Page) -> Void)? = nil

    @State private var springLoadingTask: Task<Void, Never>?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(pages) { page in
                    tabButton(for: page)
                }
                if isEditing {
                    addButton
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(uiColor: .secondarySystemBackground).opacity(0.5))
    }

    private func tabButton(for page: Page) -> some View {
        let isSelected = selection == page.id
        let symbol = PageIconCatalog.resolvedSymbol(for: page)

        return VStack(spacing: 3) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .frame(height: 20)
            Text(page.title.isEmpty ? "Sans titre" : page.title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 12)
        .frame(minWidth: 76)
        .frame(height: 54)
        .background(
            Capsule(style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(page.isHidden ? 0.5 : 1)
                                 : Color(uiColor: .systemBackground).opacity(page.isHidden ? 0.4 : 1))
        )
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .overlay(alignment: .trailing) {
            if isEditing && page.isHidden {
                Image(systemName: "eye.slash")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.orange)
                    .padding(.trailing, 4)
            }
        }
        .clipShape(Capsule(style: .continuous))
        .contentShape(Capsule())
        .onTapGesture { 
            withAnimation(.easeInOut(duration: 0.2)) { selection = page.id }
            Haptics.tap()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(page.title.isEmpty ? "Sans titre" : page.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            .contextMenu {
                if isEditing {
                    Button("Modifier la page…") { onEditPage?(page) }
                    Button(page.isHidden ? "Afficher la page" : "Masquer la page") { onHidePage?(page) }
                    Button("Déplacer vers la gauche") { onMovePage?(page, -1) }
                    Button("Déplacer vers la droite") { onMovePage?(page, 1) }
                    Divider()
                    Button(page.kind == .permanentBar ? "Barre permanente" : "Supprimer la page…",
                           role: page.kind == .permanentBar ? nil : .destructive) {
                        onDeletePage?(page)
                    }
                    .disabled(page.kind == .permanentBar)
                }
            }
            .apply {
                if isEditing, let onPlacementDropped {
                    $0.dropDestination(for: PlacementPayload.self) { items, _ in
                        guard let payload = items.first else { return false }
                        onPlacementDropped(payload, page)
                        return true
                    } isTargeted: { targeted in
                        handleHover(on: page, targeted: targeted)
                    }
                } else {
                    $0
                }
            }
    }

    private var addButton: some View {
        Button {
            onAddPage?()
        } label: {
            Image(systemName: "plus")
                .font(.system(.headline, design: .rounded))
                .frame(width: 54, height: 54)
                .background(Capsule(style: .continuous).fill(Color(uiColor: .systemBackground)))
                .overlay(Capsule(style: .continuous).strokeBorder(Color.accentColor.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ajouter une page")
    }

    /// Ouverture automatique (spring-loading) après 0,6 s d'hover pendant
    /// un glisser-déposer, comme dans l'app Fichiers (plan §7.4).
    private func handleHover(on page: Page, targeted: Bool) {
        springLoadingTask?.cancel()
        springLoadingTask = nil
        guard targeted, selection != page.id else { return }
        springLoadingTask = Task {
            try? await Task.sleep(for: .seconds(0.6))
            guard !Task.isCancelled else { return }
            selection = page.id
        }
    }
}
