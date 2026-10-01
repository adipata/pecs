import SwiftUI
import SwiftData

/// Réglages d'une page : titre et taille de grille (1 à 8 colonnes/rangées,
/// plan §2 phase III : grille ajustable pour la discrimination).
struct PageSettingsSheet: View {

    let target: EditBoardView.PageSettingsTarget
    var onAlert: ((EditBoardView.AlertPayload) -> Void)? = nil

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var columns: Int = 2
    @State private var rows: Int = 2
    @State private var icon: String = PageIconCatalog.defaultSymbol
    @State private var loadedPage: Page?

    var body: some View {
        NavigationStack {
            Form {
                Section("Page") {
                    TextField("Titre", text: $title)
                        .textInputAutocapitalization(.words)
                }
                iconSection
                Section("Taille de la grille") {
                    Stepper("Colonnes : \(columns)", value: $columns, in: 1...8)
                    Stepper("Rangées : \(rows)", value: $rows, in: 1...8)
                    Text("\(columns * rows) emplacements au maximum.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if let page = loadedPage, let hiddenCount = outOfGridCount(for: page), hiddenCount > 0 {
                    Section {
                        Label("\(hiddenCount) carte(s) restent hors grille. "
                              + "Elles seront invisibles : agrandissez la grille ou déplacez-les.",
                              systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle(target.isNew ? "Nouvelle page" : "Modifier la page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { cancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(target.isNew ? "Créer" : "OK", action: save)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear(perform: load)
    }

    private var isNew: Bool { target.isNew }

    /// Choix de l'icône de l'onglet (catalogue PageIconCatalog).
    private var iconSection: some View {
        Section("Icône de l'onglet") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                      spacing: 10) {
                ForEach(PageIconCatalog.all) { item in
                    iconButton(for: item)
                }
            }
            .padding(.vertical, 6)
        }
    }

    private func iconButton(for item: PageIconCatalog.Item) -> some View {
        let isSelected = icon == item.symbol
        return Button {
            icon = item.symbol
            Haptics.tap()
        } label: {
            VStack(spacing: 5) {
                Image(systemName: item.symbol)
                    .font(.system(size: 21, weight: .medium))
                    .frame(height: 25)
                Text(item.label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Icône \(item.label)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func load() {
        guard loadedPage == nil else { return }
        switch target {
        case .new:
            let page = Page(title: "",
                            columns: 2,
                            rows: 2,
                            kind: .normal,
                            sortIndex: BoardOps.nextSortIndex(in: context))
            context.insert(page)
            loadedPage = page
        case .existing(let page):
            title = page.title
            columns = page.columns
            rows = page.rows
            icon = PageIconCatalog.resolvedSymbol(for: page)
            loadedPage = page
        }
    }

    private func save() {
        guard let page = loadedPage else { return }
        page.title = title.trimmingCharacters(in: .whitespaces)
        page.columns = columns
        page.rows = rows
        page.iconName = icon
        try? context.save()
        dismiss()
    }

    private func cancel() {
        // Une page « nouvelle » non confirmée disparaît.
        if case .new = target, let page = loadedPage {
            context.delete(page)
        }
        dismiss()
    }

    private func outOfGridCount(for page: Page) -> Int? {
        let placements = page.placements ?? []
        let used = placements.filter { $0.slot >= page.columns * page.rows }
        return used.isEmpty ? nil : used.count
    }
}

extension EditBoardView.PageSettingsTarget {
    var isNew: Bool {
        if case .new = self { return true }
        return false
    }
}
