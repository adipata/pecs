import SwiftUI
import SwiftData
import PhotosUI

/// Cible de l'éditeur : création dans un slot donné, ou modification
/// d'un pictogramme existant.
enum EditorTarget: Identifiable {
    case create(pageID: UUID, slot: Int)
    case editPictogram(pictogramID: UUID)

    var id: String {
        switch self {
        case .create(let pageID, let slot): return "create-\(pageID.uuidString)-\(slot)"
        case .editPictogram(let pictogramID): return "edit-\(pictogramID.uuidString)"
        }
    }
}

/// Éditeur de pictogramme (plan §3.1) : image (photothèque, caméra),
/// libellé, texte prononcé, type de mot, voix enregistrée, pré-écoute.
struct PictogramEditorView: View {

    let target: EditorTarget

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(SpeechService.self) private var speech

    // Champs
    @State private var label: String = ""
    @State private var spokenText: String = ""
    @State private var wordType: WordType = .noun
    @State private var imageData: Data?
    @State private var recordingData: Data?

    /// Origine de l'image : photo, pictogramme ARASAAC, import…
    /// L'origine ARASAAC est conservée pour respecter la licence (plan §5)
    /// et pouvoir retélécharger le pictogramme en meilleure résolution.
    @State private var imageSourceKind: SymbolSourceKind = .photo
    @State private var imageSourceID: String?
    @State private var imageLicence: String?

    // UI
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showingSymbolSearch = false
    @State private var recorder = AudioRecorderService()
    @State private var didLoad = false

    private var isEditingExisting: Bool {
        if case .editPictogram = target { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                imageSection
                textSection
                voiceSection
                wordTypeSection
            }
            .navigationTitle(isEditingExisting ? "Modifier la carte" : "Nouvelle carte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler", role: .cancel) {
                        recorder.cancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer", action: save)
                        .disabled(label.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear(perform: load)
        .onChange(of: photoItem) { _, item in
            loadPhoto(item)
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in
                importUIImage(image)
            }
        }
        .sheet(isPresented: $showingSymbolSearch) {
            SymbolSearchView { selection in
                handleSymbolSelection(selection)
            }
        }
    }

    // MARK: - Sections

    private var imageSection: some View {
        Section("Image") {
            if let imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Image du pictogramme")
            }
            Button {
                showingSymbolSearch = true
            } label: {
                Label("Bibliothèque de pictogrammes", systemImage: "square.grid.3x3.fill")
            }
            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Choisir une photo", systemImage: "photo.on.rectangle")
            }
            if CameraPicker.isAvailable {
                Button {
                    showCamera = true
                } label: {
                    Label("Prendre une photo", systemImage: "camera")
                }
            }
            if imageData != nil {
                Button("Supprimer l'image", role: .destructive) {
                    imageData = nil
                }
            }
        }
    }

    /// Un pictogramme ARASAAC est choisi : l'image est normalisée, l'origine
    /// (id ARASAAC + licence CC BY-NC-SA) est conservée avec le pictogramme.
    private func handleSymbolSelection(_ selection: SymbolSearchView.Selection) {
        if let normalized = ImageNormalizer.normalize(selection.imageData) {
            imageData = normalized
        } else {
            imageData = selection.imageData
        }
        imageSourceKind = .arasaac
        imageSourceID = selection.sourceID
        imageLicence = selection.licence
        // Suggestion du mot-clé si le libellé est encore vide.
        if label.trimmingCharacters(in: .whitespaces).isEmpty {
            label = selection.label
        }
    }

    private var textSection: some View {
        Section {
            LabeledContent("Libellé affiché") {
                TextField("pomme", text: $label)
                    .multilineTextAlignment(.trailing)
            }
            LabeledContent("Texte prononcé") {
                TextField("une pomme", text: $spokenText)
                    .multilineTextAlignment(.trailing)
            }
            Button {
                Haptics.tap()
                speech.speakText(spokenText.isEmpty ? label : spokenText)
            } label: {
                Label("Écouter", systemImage: "speaker.wave.2")
            }
            .disabled(label.isEmpty && spokenText.isEmpty)
        } header: {
            Text("Textes")
        } footer: {
            Text("Le texte prononcé sert aussi à corriger la voix : ajoutez l'article (« une pomme ») ou épeler un prénom.")
        }
    }

    private var voiceSection: some View {
        Section {
            if recorder.isRecording {
                HStack {
                    Image(systemName: "waveform")
                        .foregroundStyle(.red)
                        .symbolEffect(.variableColor.iterative, options: .repeating)
                    Text("Enregistrement… \(recorder.elapsed, format: .number.precision(.fractionLength(1))) s")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Arrêter") {
                        recordingData = recorder.stop()
                        speech.restorePlaybackCategory()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            } else {
                Button {
                    Task {
                        await recorder.start()
                    }
                } label: {
                    Label(recordingData == nil ? "Enregistrer une voix" : "Réenregistrer",
                          systemImage: "mic")
                }
            }
            if recordingData != nil {
                Button {
                    speech.playRecording(recordingData!)
                } label: {
                    Label("Écouter la voix", systemImage: "play.circle")
                }
                Button("Supprimer la voix", role: .destructive) {
                    recordingData = nil
                }
            }
        } header: {
            Text("Voix enregistrée")
        } footer: {
            Text("La voix du parent passe avant la voix de l'iPad. Maximum \(Int(AudioRecorderService.maxDuration)) secondes.")
        }
    }

    private var wordTypeSection: some View {
        Section("Type de mot") {
            Picker("Type", selection: $wordType) {
                ForEach(WordType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
        }
    }

    // MARK: - Chargement

    private func load() {
        guard !didLoad else { return }
        didLoad = true
        guard case .editPictogram(let pictogramID) = target,
              let pictogram = BoardOps.pictogram(withID: pictogramID, in: context) else { return }
        label = pictogram.label
        spokenText = pictogram.spokenText ?? ""
        wordType = pictogram.wordType
        imageData = pictogram.image
        recordingData = pictogram.recording
        imageSourceKind = pictogram.sourceKind
        imageSourceID = pictogram.sourceID
        imageLicence = pictogram.licence
    }

    // MARK: - Import d'image

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let normalized = ImageNormalizer.normalize(data) {
                imageData = normalized
                imageSourceKind = .photo
                imageSourceID = nil
                imageLicence = nil
            }
            photoItem = nil
        }
    }

    private func importUIImage(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.9) ?? image.pngData(),
           let normalized = ImageNormalizer.normalize(data) {
            imageData = normalized
            imageSourceKind = .photo
            imageSourceID = nil
            imageLicence = nil
        }
    }

    // MARK: - Enregistrement

    private func save() {
        let trimmedLabel = label.trimmingCharacters(in: .whitespaces)
        guard !trimmedLabel.isEmpty else { return }

        if recorder.isRecording {
            _ = recorder.stop()
            speech.restorePlaybackCategory()
        }

        let spoken = spokenText.trimmingCharacters(in: .whitespaces)

        switch target {
        case .create(let pageID, let slot):
            guard let page = BoardOps.page(withID: pageID, in: context) else { return }
            let pictogram = Pictogram(
                label: trimmedLabel,
                spokenText: spoken.isEmpty ? nil : spoken,
                image: imageData,
                recording: recordingData,
                wordType: wordType,
                sourceKind: imageSourceKind,
                sourceID: imageSourceID,
                licence: imageLicence)
            BoardOps.add(pictogram, atSlot: slot, on: page, in: context)

        case .editPictogram(let pictogramID):
            guard let pictogram = BoardOps.pictogram(withID: pictogramID, in: context) else { return }
            pictogram.label = trimmedLabel
            pictogram.spokenText = spoken.isEmpty ? nil : spoken
            pictogram.image = imageData
            pictogram.recording = recordingData
            pictogram.wordType = wordType
            pictogram.sourceKind = imageSourceKind
            pictogram.sourceID = imageSourceID
            pictogram.licence = imageLicence
        }

        try? context.save()
        dismiss()
    }
}
