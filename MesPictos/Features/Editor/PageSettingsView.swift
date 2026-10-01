import SwiftUI
import PictoCore

/// Title, grid size and visibility of a page (or the number of slots of the permanent bar).
struct PageSettingsView: View {
    let page: Page

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var title: String
    @State private var columns: Int
    @State private var rows: Int
    @State private var isHidden: Bool
    @State private var message: String?

    private static let presets: [(label: String, columns: Int, rows: Int)] = [
        ("1", 1, 1), ("2", 2, 1), ("4", 2, 2), ("6", 3, 2), ("9", 3, 3), ("12", 4, 3), ("20", 5, 4),
    ]

    init(page: Page) {
        self.page = page
        _title = State(initialValue: page.title)
        _columns = State(initialValue: page.columns)
        _rows = State(initialValue: page.rows)
        _isHidden = State(initialValue: page.isHidden)
    }

    private var isBar: Bool { page.kind == .permanentBar }

    var body: some View {
        NavigationStack {
            Form {
                if !isBar {
                    Section("Titre") {
                        TextField("Titre de la page", text: $title)
                    }
                }

                Section {
                    if !isBar {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(Self.presets, id: \.label) { preset in
                                    Button(preset.label) {
                                        columns = preset.columns
                                        rows = preset.rows
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(columns == preset.columns && rows == preset.rows ? Color.accentColor : Color.secondary)
                                }
                            }
                        }
                    }
                    Stepper("Colonnes : \(columns)", value: $columns, in: GridSize.columnRange)
                    if !isBar {
                        Stepper("Lignes : \(rows)", value: $rows, in: GridSize.rowRange)
                    }
                    if let message {
                        Text(message)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text(isBar ? "Nombre de cases" : "Nombre de cartes")
                } footer: {
                    Text(isBar
                         ? "\(columns) cases dans la barre."
                         : "\(columns * rows) cases. Au début, peu de grandes cartes aident l'enfant à choisir. Les cartes gardent leur place quand la grille change.")
                }

                if !isBar {
                    Section {
                        Toggle("Masquer cette page pour l'enfant", isOn: $isHidden)
                    } footer: {
                        Text("Une page masquée reste visible en mode parent.")
                    }
                }
            }
            .navigationTitle(isBar ? "Barre permanente" : "Réglages de la page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK", action: apply)
                }
            }
        }
    }

    private func apply() {
        let store = PictoStore(context: context)
        let targetRows = isBar ? 1 : rows
        if columns != page.columns || targetRows != page.rows {
            guard store.resize(page, columns: columns, rows: targetRows) else {
                message = "Il y a plus de pictogrammes que de cases. Retirez des pictogrammes ou gardez une grille plus grande."
                return
            }
        }
        if !isBar {
            page.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            page.isHidden = isHidden
        }
        store.save()
        dismiss()
    }
}
