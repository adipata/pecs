import SwiftUI

/// Une carte de pictogramme (image + libellé), utilisée par la grille,
/// la barre permanente et le mode montrer. Le style du libellé vient
/// des réglages (plan §3.3.5).
struct PictoCardView: View {

    let pictogram: Pictogram

    @Environment(SettingsStore.self) private var settings

    var body: some View {
        VStack(spacing: 8) {
            imageView
                .frame(maxHeight: .infinity)
            labelView
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .systemBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.10), radius: 4, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(pictogram.label)
    }

    @ViewBuilder
    private var imageView: some View {
        if let data = pictogram.image, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: "photo")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var labelView: some View {
        if let label = settings.labelStyle.display(for: pictogram.label) {
            Text(label)
                .font(.system(size: 20 * settings.labelFontScale,
                              weight: .semibold, design: .rounded))
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(.horizontal, 4)
        }
    }
}

/// Version compacte pour la barre permanente.
struct BarPictoCardView: View {

    let pictogram: Pictogram

    @Environment(SettingsStore.self) private var settings

    var body: some View {
        VStack(spacing: 4) {
            if let data = pictogram.image, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 46)
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.tertiary)
                    .frame(maxHeight: 46)
            }
            if let label = settings.labelStyle.display(for: pictogram.label) {
                Text(label)
                    .font(.system(size: 13 * settings.labelFontScale,
                                  weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .systemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(pictogram.label)
    }
}
