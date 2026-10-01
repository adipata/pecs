import SwiftUI

/// Recherche de pictogrammes (plan §4.2) : ARASAAC en ligne et kit de
/// démarrage hors ligne. L'attribution ARASAAC reste affichée en pied
/// de l'écran (licence CC BY-NC-SA, plan §5).
struct SymbolSearchView: View {

    /// Ce que l'éditeur reçoit quand un pictogramme est choisi.
    struct Selection {
        let imageData: Data
        /// Id ARASAAC, stocké avec le pictogramme pour pouvoir le
        /// retélécharger plus tard (plan §5).
        let sourceID: String
        let label: String
        let licence: String
    }

    var onSelect: (Selection) -> Void

    enum Source: String, CaseIterable, Identifiable {
        case arasaac = "ARASAAC"
        case starterPack = "Kit de démarrage"

        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss

    @State private var source: Source = .arasaac
    @State private var query = ""
    @State private var hits: [SymbolHit] = []
    @State private var isSearching = false
    @State private var message: String?
    @State private var downloadingID: String?
    @State private var bundled = BundledProvider()

    private let provider = ArasaacProvider()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Source", selection: $source) {
                    ForEach(Source.allCases) { source in
                        Text(source.rawValue).tag(source)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch source {
                case .arasaac: arasaacPane
                case .starterPack: starterPackPane
                }
            }
            .navigationTitle("Pictogrammes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Text(SymbolAttribution.arasaac)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(.thinMaterial)
            }
            .task {
                try? bundled.load()
            }
            .onChange(of: source) { _, _ in
                message = nil
            }
        }
    }

    // MARK: - ARASAAC (en ligne)

    private var arasaacPane: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                TextField("Rechercher un mot (pomme, ballon…)", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.search)
                    .onSubmit(of: .text) {
                        Task { await runSearch() }
                    }
                Button {
                    Task { await runSearch() }
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .buttonStyle(.bordered)
                .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal)

            if isSearching {
                ProgressView("Recherche sur ARASAAC…")
                    .padding()
            } else if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 12)],
                          spacing: 14) {
                    ForEach(hits) { hit in
                        SymbolHitCell(
                            hit: hit,
                            provider: provider,
                            isDownloading: downloadingID == hit.id) {
                            Task { await chooseOnline(hit) }
                        }
                    }
                }
                .padding()
            }
        }
    }

    private func runSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSearching = true
        message = nil
        hits = []
        do {
            let found = try await provider.search(trimmed, language: "fr")
            hits = found
            if found.isEmpty {
                message = "Aucun pictogramme trouvé pour « \(trimmed) »."
            }
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet {
            message = "Pas de connexion Internet. Utilisez le Kit de démarrage, disponible hors ligne."
        } catch {
            message = "Recherche impossible. Vérifiez la connexion et réessayez."
        }
        isSearching = false
    }

    private func chooseOnline(_ hit: SymbolHit) async {
        downloadingID = hit.id
        defer { downloadingID = nil }
        do {
            let data = try await provider.image(for: hit, options: SymbolOptions())
            onSelect(Selection(imageData: data,
                              sourceID: hit.id,
                              label: hit.label,
                              licence: SymbolAttribution.arasaacLicence))
            dismiss()
        } catch {
            message = "Impossible de télécharger ce pictogramme. Réessayez."
        }
    }

    // MARK: - Kit de démarrage (hors ligne)

    private var starterPackPane: some View {
        Group {
            if bundled.items.isEmpty {
                ContentUnavailableView {
                    Label("Kit de démarrage indisponible", systemImage: "tray")
                } description: {
                    Text("Les pictogrammes embarqués n'ont pas pu être chargés.")
                }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                        ForEach(bundled.categories, id: \.self) { category in
                            Section(category) {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 12)],
                                          spacing: 14) {
                                    ForEach(bundled.hits(in: category)) { hit in
                                        SymbolHitCell(
                                            hit: hit,
                                            provider: bundled,
                                            isDownloading: false) {
                                            chooseBundled(hit)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
    }

    private func chooseBundled(_ hit: SymbolHit) {
        guard let data = bundled.imageData(forID: hit.id) else { return }
        onSelect(Selection(imageData: data,
                           sourceID: hit.id,
                           label: hit.label,
                           licence: SymbolAttribution.arasaacLicence))
        dismiss()
    }
}

/// Cellule d'un pictogramme : vignette chargée à la demande via le
/// fournisseur (cache mémoire), libellé français dessous.
struct SymbolHitCell: View {

    let hit: SymbolHit
    let provider: any SymbolProvider
    var isDownloading: Bool
    var action: () -> Void

    @State private var thumbData: Data?
    @State private var failed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemFill))
                    if let thumbData, let image = UIImage(data: thumbData) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(6)
                    } else if failed {
                        Image(systemName: "photo")
                            .foregroundStyle(.tertiary)
                    } else {
                        ProgressView()
                    }

                    if isDownloading {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.black.opacity(0.3))
                        ProgressView()
                            .tint(.white)
                    }
                }
                .frame(height: 76)

                Text(hit.label)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(hit.label)
        .task(id: hit.uniqueID) {
            if thumbData == nil {
                if let data = await provider.thumbnail(for: hit) {
                    thumbData = data
                } else {
                    failed = true
                }
            }
        }
    }
}
