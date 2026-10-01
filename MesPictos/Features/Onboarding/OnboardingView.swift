import SwiftUI

/// First launch.
struct OnboardingView: View {
    @AppStorage(SettingsKey.onboardingDone) private var onboardingDone = false
    @Environment(\.modelContext) private var context

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Color.accentColor)
                    .padding(.top, 40)

                Text("Bienvenue dans Mes Pictos")
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 12) {
                    point("hand.tap", "L'enfant touche une carte : elle est dite à voix haute et vient au centre de l'écran pour être montrée à un adulte.")
                    point("lock", "Appuyez 3 secondes sur le cadenas pour ouvrir le mode parent et créer les cartes à partir de vos photos.")
                    point("mic", "Vous pouvez enregistrer votre voix sur chaque carte.")
                    point("icloud", "Les pages se synchronisent avec vos autres appareils connectés au même compte iCloud.")
                }
                .frame(maxWidth: 560)

                VStack(spacing: 12) {
                    Button {
                        PictoStore(context: context).seedStarterContent()
                        onboardingDone = true
                    } label: {
                        Text("Commencer avec le contenu de départ")
                            .frame(maxWidth: 420)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Text("Une page « Mes choses » avec 4 cases vides, et une barre avec « Non » et « Aide ».")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        onboardingDone = true
                    } label: {
                        Text("Mes Pictos est déjà configuré sur un autre appareil")
                            .frame(maxWidth: 420)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Text("Vos pages arriveront par iCloud dans quelques instants.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 12)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
    }

    private func point(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)
            Text(text)
                .font(.body)
        }
    }
}
