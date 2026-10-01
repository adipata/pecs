import UIKit

/// Normalisation des images de pictogrammes (plan §7.3) :
/// recadrage carré au centre, redimensionné à 512 px, PNG.
/// Une taille unique garde le classeur léger pour iCloud.
enum ImageNormalizer {

    static let side: CGFloat = 512

    /// Normalise des données d'image (JPEG, PNG, HEIC…). Retourne nil si les
    /// données ne sont pas une image exploitable.
    static func normalize(_ data: Data) -> Data? {
        guard let source = UIImage(data: data) else { return nil }
        let upright = redrawnUpright(source)
        let cropped = centerCroppedToSquare(upright)
        let resized = resizedToSide(cropped, side: side)
        return resized.pngData()
    }

    /// Redessine l'image pour intégrer l'orientation EXIF. Conserve la
    /// transparence : les pictogrammes ARASAAC ont un fond transparent.
    private static func redrawnUpright(_ image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    /// Recadre au centre au carré (le format des cartes PECS).
    private static func centerCroppedToSquare(_ image: UIImage) -> UIImage {
        let sideLength = min(image.size.width, image.size.height)
        guard sideLength > 0 else { return image }
        let rect = CGRect(
            x: (image.size.width - sideLength) / 2,
            y: (image.size.height - sideLength) / 2,
            width: sideLength,
            height: sideLength)
        guard let cgImage = image.cgImage?.cropping(to: rect) else { return image }
        return UIImage(cgImage: cgImage)
    }

    private static func resizedToSide(_ image: UIImage, side target: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: target, height: target), format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: CGSize(width: target, height: target)))
        }
    }
}
