import SwiftUI
import AVFoundation
import PictoCore

/// Parent settings. They are stored on this device only.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(SettingsKey.voiceIdentifier) private var voiceIdentifier = ""
    @AppStorage(SettingsKey.speechRate) private var speechRate = SettingsDefault.speechRate
    @AppStorage(SettingsKey.speechPitch) private var speechPitch = SettingsDefault.speechPitch

    @AppStorage(SettingsKey.showModeEnabled) private var showModeEnabled = SettingsDefault.showModeEnabled
    @AppStorage(SettingsKey.showDismissMode) private var dismissRaw = DismissMode.tapOutside.rawValue
    @AppStorage(SettingsKey.showAutoCloseSeconds) private var autoCloseSeconds = SettingsDefault.showAutoCloseSeconds
    @AppStorage(SettingsKey.showCelebration) private var celebration = SettingsDefault.showCelebration

    @AppStorage(SettingsKey.labelStyle) private var labelStyleRaw = LabelStyle.uppercase.rawValue
    @AppStorage(SettingsKey.showPageTabs) private var showPageTabs = SettingsDefault.showPageTabs
    @AppStorage(SettingsKey.tapInterval) private var tapInterval = SettingsDefault.tapInterval

    @AppStorage(SettingsKey.parentProtection) private var protectionRaw = ParentProtection.gestureOnly.rawValue
    @AppStorage(SettingsKey.parentCode) private var parentCode = ""
    @State private var newCode = ""

    private let voices = SpeechService.frenchVoices()

    var body: some View {
        NavigationStack {
            Form {
                voiceSection
                showSection
                displaySection
                protectionSection
                syncSection
                aboutSection
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
    }

    // MARK: Voice

    private var voiceSection: some View {
        Section {
            Picker("Voix", selection: $voiceIdentifier) {
                Text("Automatique").tag("")
                ForEach(voices, id: \.identifier) { voice in
                    Text("\(voice.name) (\(SpeechService.qualityName(voice.quality)), \(voice.language))")
                        .tag(voice.identifier)
                }
            }
            VStack(alignment: .leading) {
                Text("Vitesse")
                Slider(value: $speechRate, in: 0.3...0.6) {
                    Text("Vitesse")
                } minimumValueLabel: {
                    Image(systemName: "tortoise")
                } maximumValueLabel: {
                    Image(systemName: "hare")
                }
            }
            VStack(alignment: .leading) {
                Text("Hauteur")
                Slider(value: $speechPitch, in: 0.8...1.3)
            }
            Button {
                SpeechService.shared.speakText("Bonjour ! Je veux une pomme.")
            } label: {
                Label("Tester la voix", systemImage: "speaker.wave.2.fill")
            }
        } header: {
            Text("Voix de l'iPad")
        } footer: {
            Text("Pour une voix plus naturelle, téléchargez une voix française « améliorée » ou « premium » dans Réglages > Accessibilité > Contenu énoncé > Voix > Français. Les enregistrements de votre voix sont toujours joués en priorité.")
        }
    }

    // MARK: Show mode

    private var showSection: some View {
        Section {
            Toggle("Montrer la carte au centre", isOn: $showModeEnabled)
            if showModeEnabled {
                Picker("Pour fermer", selection: $dismissRaw) {
                    ForEach(DismissMode.allCases) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                }
                Stepper(
                    autoCloseSeconds == 0 ? "Fermeture automatique : jamais" : "Fermeture automatique : \(autoCloseSeconds) s",
                    value: $autoCloseSeconds,
                    in: 0...60,
                    step: 5
                )
                Toggle("Petite animation de joie", isOn: $celebration)
            }
        } header: {
            Text("Mode montrer")
        } footer: {
            Text("Quand l'enfant choisit une carte, elle vient au centre de l'écran pour qu'il puisse la montrer à un adulte, comme une carte papier. Avec « Appui long », seul un adulte la ferme.")
        }
    }

    // MARK: Display

    private var displaySection: some View {
        Section {
            Picker("Texte des cartes", selection: $labelStyleRaw) {
                ForEach(LabelStyle.allCases, id: \.rawValue) { style in
                    Text(style.displayName).tag(style.rawValue)
                }
            }
            Toggle("Onglets des pages visibles pour l'enfant", isOn: $showPageTabs)
            VStack(alignment: .leading) {
                Text("Ignorer les touches répétées : \(tapInterval, specifier: "%.1f") s")
                Slider(value: $tapInterval, in: 0...2, step: 0.1)
            }
        } header: {
            Text("Affichage")
        } footer: {
            Text("Sans onglets, l'enfant reste sur la page choisie en mode parent.")
        }
    }

    // MARK: Protection

    private var protectionSection: some View {
        Section {
            Picker("Protection", selection: $protectionRaw) {
                ForEach(ParentProtection.allCases) { protection in
                    Text(protection.displayName).tag(protection.rawValue)
                }
            }
            if protectionRaw == ParentProtection.code.rawValue {
                SecureField(parentCode.isEmpty ? "Nouveau code (4 à 6 chiffres)" : "Changer le code (4 à 6 chiffres)", text: $newCode)
                    .keyboardType(.numberPad)
                Button("Enregistrer le code") {
                    parentCode = newCode
                    newCode = ""
                }
                .disabled(!ParentCode.isValid(newCode))
                if parentCode.isEmpty {
                    Text("Aucun code défini : l'appui long suffit.")
                        .foregroundStyle(.secondary)
                }
            }
            if protectionRaw == ParentProtection.deviceAuth.rawValue && !DeviceAuth.isAvailable {
                Text("Face ID, Touch ID ou un code de l'appareil doit être configuré.")
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Mode parent")
        } footer: {
            Text("Le mode parent s'ouvre par un appui de 3 secondes sur le cadenas. Pour que l'enfant ne puisse pas quitter l'application, activez l'Accès guidé : Réglages > Accessibilité > Accès guidé, puis triple-cliquez sur le bouton latéral (ou principal) dans Mes Pictos.")
        }
    }

    // MARK: Sync

    private var syncSection: some View {
        Section {
            Label(
                FileManager.default.ubiquityIdentityToken == nil ? "Pas de compte iCloud sur cet appareil" : "Compte iCloud disponible",
                systemImage: FileManager.default.ubiquityIdentityToken == nil ? "icloud.slash" : "icloud"
            )
        } header: {
            Text("Synchronisation")
        } footer: {
            Text("Les pages et pictogrammes se synchronisent entre vos appareils connectés au même compte iCloud. Les réglages de cet écran restent propres à chaque appareil.")
        }
    }

    private var aboutSection: some View {
        Section("À propos") {
            LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?")
        }
    }
}
