import SwiftUI
import SwiftData

/// Gestionnaire de pages (mode parent, plan §4.2 « réglages de page ») :
/// créer, modifier, masquer, réordonner et supprimer les pages du classeur.
/// Les pictogrammes supprimés restent dans la bibliothèque.
struct PageManagerView: View {

    /// Sélection courante du classeur, pour l'étiquette « affichée » et
    /// pour retomber sur une page valide après une suppression.
    @Binding var currentPageID: UUID?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: [SortDescriptor(\Page.sortIndex), SortDescriptor(\Page.createdAt)],
           animation: .default)
    private var allPages: [Page]

    @State private var settingsTarget: EditBoardView.PageSettingsTarget?
    @State private var pageToDelete: Page?

    private var normalPages: [Page] {
        allPages.filter { $0.kind == .normal }
    }

    var body: some View {
        NavigationStack {
            Group {
                if normalPages.isEmpty {
                    ContentUnavailableView {
                        Label("Aucune page", systemImage: "rectangle.stack")
                    } description: {
                        Text("Créez une première page pour votre enfant.")
                    }
                } else {
                    List {
                        ForEach(normalPages) { page in
                            row(for: page)
                        }
                    }
                }
            }
            .navigationTitle("Pages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        settingsTarget = .new
                    } label: {
                        Label("Ajouter une page", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $settingsTarget) { target in
                PageSettingsSheet(target: target)
            }
            .confirmationDialog(
                pageToDelete.map { "Supprimer la page « \($0.title) » ?" } ?? "",
                isPresented: Binding(get: { pageToDelete != nil },
                                     set: { if !$0 { pageToDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("Supprimer la page", role: .destructive) {
                    if let page = pageToDelete {
                        delete(page)
                    }
                }
            } message: {
                Text("Ses cartes quittent la page mais restent dans la bibliothèque.")
            }
        }
    }

    // MARK: - Ligne de page

    private func row(for page: Page) -> some View {
        Button {
            settingsTarget = .existing(page)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: PageIconCatalog.resolvedSymbol(for: page))
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(page.title.isEmpty ? "Sans titre" : page.title)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(page.isHidden
                         ? "\(page.columns)×\(page.rows) · masquée"
                         : "\(page.columns)×\(page.rows)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if currentPageID == page.id {
                    Text("affichée")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.accentColor.opacity(0.12)))
                }
            }
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                page.isHidden.toggle()
            } label: {
                Label(page.isHidden ? "Afficher" : "Masquer",
                      systemImage: page.isHidden ? "eye" : "eye.slash")
            }
            .tint(.orange)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                pageToDelete = page
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
        }
        .contextMenu {
            Button {
                settingsTarget = .existing(page)
            } label: {
                Label("Modifier…", systemImage: "pencil")
            }
            Button(page.isHidden ? "Afficher la page" : "Masquer la page") {
                page.isHidden.toggle()
            }
            Button {
                BoardOps.movePage(page, by: -1, in: normalPages)
            } label: {
                Label("Monter", systemImage: "arrow.up")
            }
            Button {
                BoardOps.movePage(page, by: 1, in: normalPages)
            } label: {
                Label("Descendre", systemImage: "arrow.down")
            }
            Divider()
            Button("Supprimer…", role: .destructive) {
                pageToDelete = page
            }
        }
    }

    // MARK: - Suppression

    private func delete(_ page: Page) {
        // La sélection retombe d'elle-même sur la première page visible ;
        // on la réinitialise si la page supprimée était affichée.
        if currentPageID == page.id {
            currentPageID = nil
        }
        context.delete(page)
        try? context.save()
        if currentPageID == nil {
            currentPageID = allPages.first { $0.kind == .normal && !$0.isHidden }?.id
        }
        Haptics.success()
    }
}
