import SwiftUI
import AVFoundation

/// Réglages de l'app (plan §4.2) : voix, étiquettes, mode montrer,
/// toucher, sécurité, synchronisation, crédits.
struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsStore.self) private var settings
    @Environment(SpeechService.self) private var speech
    @Environment(\.cloudSyncActive) private var cloudSyncActive

    @State private var showingCodeSetup = false
    @State private var showingVoiceHelp = false
    @State private var showingGuidedAccess = false

    var body: some View {
        NavigationStack {
            Form {
                voiceSection
                labelSection
                showModeSection
                touchSection
                securitySection
                syncSection
                aboutSection
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Terminé") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingCodeSetup) {
            CodeSetupSheet(onDone: {})
        }
        .sheet(isPresented: $showingVoiceHelp) {
            voiceHelpSheet
        }
        .sheet(isPresented: $showingGuidedAccess) {
            guidedAccessSheet
        }
    }

    // MARK: - Voix

    private var voiceSection: some View {
        @Bindable var settings = settings
        return Section {
            voiceRow(name: "Voix du système (fr-FR)",
                     identifier: nil)
            ForEach(SpeechService.frenchVoices(), id: \.identifier) { voice in
                voiceRow(name: voice.name,
                         identifier: voice.identifier,
                         quality: voice.quality)
            }
            Button {
                showingVoiceHelp = true
            } label: {
                Label("Installer une meilleure voix", systemImage: "arrow.down.circle")
            }
            HStack {
                Text("Vitesse")
                    .foregroundStyle(.primary)
                Spacer()
                Slider(value: $settings.speechRate, in: 0.3...0.8)
                    .frame(maxWidth: 220)
            }
            HStack {
                Text("Tonalité")
                    .foregroundStyle(.primary)
                Spacer()
                Slider(value: $settings.speechPitch, in: 0.6...1.4)
                    .frame(maxWidth: 220)
            }
        } header: {
            Text("Voix")
        } footer: {
            Text("La voix s'entraîne : testez la vitesse avec votre enfant. Un peu plus lent aide souvent.")
        }
    }

    private func voiceRow(name: String,
                          identifier: String?,
                          quality: AVSpeechSynthesisVoiceQuality? = nil) -> some View {
        let isSelected = settings.voiceIdentifier == identifier
        let resolvedVoice = identifier.flatMap { AVSpeechSynthesisVoice(identifier: $0) }
            ?? AVSpeechSynthesisVoice(language: "fr-FR")
        return HStack {
            Button {
                if let resolvedVoice {
                    speech.preview(voice: resolvedVoice)
                }
            } label: {
                Image(systemName: "speaker.wave.2")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Écouter \(name)")

            Text(name)
                .lineLimit(1)

            if let quality, quality != .default {
                Text(qualityBadge(quality))
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.accentColor.opacity(0.2)))
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.accentColor)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            settings.voiceIdentifier = identifier
        }
    }

    private func qualityBadge(_ quality: AVSpeechSynthesisVoiceQuality) -> String {
        switch quality {
        case .premium: return "Premium"
        case .enhanced: return "Améliorée"
        default: return ""
        }
    }

    private var voiceHelpSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Installer une voix française de meilleure qualité")
                .font(.title3.bold())
            Text("""
                1. Ouvrez Réglages ▸ Accessibilité ▸ Contenu énoncé ▸ Voix ▸ Français.
                2. Téléchargez une voix « Améliorée » ou « Premium » — elles sonnent bien mieux que la voix de base.
                3. Revenez dans Mes Pictos et choisissez-la dans la liste.
                """)
            Spacer()
        }
        .padding()
        .presentationDetents([.medium])
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Étiquettes

    private var labelSection: some View {
        @Bindable var settings = settings
        return Section {
            Picker("Style du libellé", selection: $settings.labelStyle) {
                ForEach(LabelStyle.allCases) { style in
                    Text(style.displayName).tag(style)
                }
            }
            .pickerStyle(.segmented)
            HStack {
                Text("Taille du texte")
                    .foregroundStyle(.primary)
                Spacer()
                Slider(value: $settings.labelFontScale, in: 0.7...1.6)
                    .frame(maxWidth: 220)
            }
        } header: {
            Text("Libellés")
        } footer: {
            Text("Les enfants apprennent d'abord les MAJUSCULES d'imprimerie à la maternelle.")
        }
    }

    // MARK: - Mode montrer

    private var showModeSection: some View {
        @Bindable var settings = settings
        return Section {
            Toggle("Mode montrer", isOn: $settings.showModeEnabled)
            if settings.showModeEnabled {
                Picker("Fermeture", selection: $settings.showModeClose) {
                    ForEach(ShowModeClose.allCases) { close in
                        Text(close.displayName).tag(close)
                    }
                }
                Picker("Fermeture automatique", selection: $settings.showModeAutoCloseSeconds) {
                    Text("Non").tag(0)
                    ForEach([3, 5, 8, 10, 15, 30], id: \.self) { seconds in
                        Text("\(seconds) s").tag(seconds)
                    }
                }
                Toggle("Petite fête à l'arrivée", isOn: $settings.showModeCelebration)
            }
        } header: {
            Text("Mode montrer")
        } footer: {
            Text("La carte tapée part au centre de l'écran pour être montrée à un adulte, comme une carte papier tendue.")
        }
    }

    // MARK: - Toucher

    private var touchSection: some View {
        @Bindable var settings = settings
        return Section {
            HStack {
                Text(debounceTitle)
                    .foregroundStyle(.primary)
                Spacer()
                Slider(value: $settings.tapDebounceSeconds, in: 0...2, step: 0.05)
                    .frame(maxWidth: 200)
            }
        } header: {
            Text("Toucher")
        } footer: {
            Text("Ignore les tapes répétés : utile quand l'enfant tape vite sur la même carte.")
        }
    }

    private var debounceTitle: String {
        settings.tapDebounceSeconds <= 0.01
            ? "Ignorer les tapes répétés : non"
            : String(format: "Ignorer les tapes répétés : %.1f s", settings.tapDebounceSeconds)
    }

    // MARK: - Sécurité

    private var securitySection: some View {
        @Bindable var settings = settings
        return Section {
            Button {
                showingCodeSetup = true
            } label: {
                Label(ParentLock.hasCode() ? "Modifier le code" : "Définir un code (4 chiffres)",
                      systemImage: "lock.rotation")
            }
            if ParentLock.hasCode() {
                Button("Supprimer le code", role: .destructive) {
                    ParentLock.clearCode()
                }
            }
            Toggle("Face ID pour le mode parent", isOn: $settings.faceIDEnabled)
                .disabled(!ParentLock.biometricsAvailable())
            if !ParentLock.biometricsAvailable() {
                Text("Face ID n'est pas disponible sur cet appareil.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Button {
                showingGuidedAccess = true
            } label: {
                Label("Empêcher de quitter l'app (Accès guidé)", systemImage: "lock.shield")
            }
        } header: {
            Text("Sécurité")
        } footer: {
            Text("Sans code ni Face ID, un appui long de 3 secondes suffit pour entrer en mode parent.")
        }
    }

    private var guidedAccessSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("L'accès guidé verrouille l'iPad sur une seule app")
                .font(.title3.bold())
            Text("""
                C'est le seul moyen fiable d'empêcher votre enfant de quitter Mes Pictos :

                1. Réglages ▸ Accessibilité ▸ Accès guidé : activez-le.
                2. Dans Mes Pictos, ouvrez le menu (ou appuyez trois fois sur le bouton latéral), puis « Démarrer ».
                3. Pour quitter, appuyez trois fois et saisissez le code.

                Pensez aussi à désactiver le multitâche si nécessaire.
                """)
            Spacer()
        }
        .padding()
        .presentationDetents([.medium])
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Synchronisation

    private var syncSection: some View {
        Section {
            HStack {
                Label(cloudSyncActive
                      ? "Synchronisation iCloud activée"
                      : "Données locales uniquement (iCloud indisponible)",
                      systemImage: cloudSyncActive ? "icloud.fill" : "icloud.slash")
                if cloudSyncActive {
                    Spacer()
                    Text("iPad ↔ iPhone")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Synchronisation")
        } footer: {
            Text("Les pages et les pictogrammes se synchronisent entre l'iPad de l'enfant et l'iPhone du parent via iCloud. Les photos restent dans l'iCloud familial.")
        }
    }

    // MARK: - À propos

    private var aboutSection: some View {
        Section("À propos") {
            LabeledContent("Version", value: appVersion)
            NavigationLink("Crédits et licences") {
                CreditsView()
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

/// Crédits (plan §5) : l'attribution ARASAAC doit apparaître dès que des
/// pictogrammes ARASAAC sont utilisés ; le texte est prêt.
struct CreditsView: View {
    var body: some View {
        List {
            Section("Images de démonstration") {
                Text("Les pictogrammes d'exemple fournis au premier lancement sont des dessins simples créés pour l'app. Remplacez-les par les photos des vrais objets de votre enfant (renforçateurs) et par les photos de ses cartes papier.")
            }
            Section("ARASAAC") {
                Text("Les symboles pictographiques utilisés sont la propriété du Gouvernement d'Aragon et ont été créés par Sergio Palao pour ARASAAC (https://arasaac.org), qui les distribue sous licence Creative Commons BY-NC-SA.")
                Text("Licence CC BY-NC-SA : usage non commercial, partage aux mêmes conditions. L'attribution est conservée dans chaque pictogramme importé depuis ARASAAC.")
            }
        }
        .navigationTitle("Crédits")
    }
}
