import SwiftUI
import PictoCore

/// A pictogram card: picture and label on a white rounded card. Fills the size it is given.
struct CardView: View {
    let pictogram: Pictogram
    @AppStorage(SettingsKey.labelStyle) private var labelStyleRaw = LabelStyle.uppercase.rawValue

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let style = LabelStyle(rawValue: labelStyleRaw) ?? .uppercase
            let text = style.format(pictogram.label)

            VStack(spacing: side * 0.03) {
                picture
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if let text {
                    Text(text)
                        .font(.system(size: max(11, side * 0.12), weight: .bold, design: .rounded))
                        .foregroundStyle(Color.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                }
            }
            .padding(side * 0.07)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(
                RoundedRectangle(cornerRadius: side * 0.1, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: side * 0.1, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.12), lineWidth: max(1, side * 0.012))
            )
            .shadow(color: .black.opacity(0.12), radius: side * 0.03, y: side * 0.015)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(pictogram.label)
    }

    @ViewBuilder
    private var picture: some View {
        if let image = ImageCache.shared.image(for: pictogram) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.gray.opacity(0.4))
                .padding()
        }
    }
}
