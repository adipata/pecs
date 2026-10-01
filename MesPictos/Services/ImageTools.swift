import UIKit

enum ImageTools {
    /// Pictogram images are stored as squares of this size, in pixels.
    static let outputSide: CGFloat = 600

    /// Renders `rect` (in image points) of `image` into a white square.
    static func crop(_ image: UIImage, to rect: CGRect, side: CGFloat = outputSide) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let size = CGSize(width: side, height: side)
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            guard rect.width > 0 else { return }
            let scale = side / rect.width
            let drawRect = CGRect(
                x: -rect.minX * scale,
                y: -rect.minY * scale,
                width: image.size.width * scale,
                height: image.size.height * scale
            )
            image.draw(in: drawRect)
        }
    }

    /// Limits the size of camera and library photos before cropping.
    static func downscaled(_ image: UIImage, maxSide: CGFloat = 2048) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxSide else { return image }
        let factor = maxSide / longest
        let size = CGSize(width: image.size.width * factor, height: image.size.height * factor)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    static func jpegData(_ image: UIImage) -> Data? {
        image.jpegData(compressionQuality: 0.85)
    }

    /// A simple card made from an SF Symbol, used for the starter "Non" and "Aide" cards
    /// until they are replaced by photos of the real cards.
    static func symbolCard(systemName: String, tint: UIColor, side: CGFloat = outputSide) -> Data? {
        let configuration = UIImage.SymbolConfiguration(pointSize: side * 0.5, weight: .regular)
        guard let symbol = UIImage(systemName: systemName, withConfiguration: configuration)?
            .withTintColor(tint, renderingMode: .alwaysOriginal)
        else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let size = CGSize(width: side, height: side)
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let box = side * 0.7
            let factor = min(box / symbol.size.width, box / symbol.size.height)
            let drawSize = CGSize(width: symbol.size.width * factor, height: symbol.size.height * factor)
            symbol.draw(in: CGRect(
                x: (side - drawSize.width) / 2,
                y: (side - drawSize.height) / 2,
                width: drawSize.width,
                height: drawSize.height
            ))
        }
        return image.pngData()
    }
}

/// Decoded pictogram images, so the grid does not decode them on every redraw.
@MainActor
final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 200
    }

    func image(for pictogram: Pictogram) -> UIImage? {
        let key = "\(pictogram.id.uuidString)-\(pictogram.imageVersion)" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let data = pictogram.imageData, let image = UIImage(data: data) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }
}
